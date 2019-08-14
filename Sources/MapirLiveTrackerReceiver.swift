//
//  MapirLiveTrackerReceiver.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 18/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CocoaMQTT
import CoreLocation
import SwiftProtobuf

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


public protocol ReceiverDelegate {

    /// Receives location updates of the specified tracking identifier.
    ///
    /// - parameter liveTrackerReceiver: the receiver that received the location.
    /// - Parameter location: `CLLocation` instance of received data.
    /// It does not contain accuracy, floor and altitude data.
    ///
    /// You may check the timestamp of the received `location` object to validate it.
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, locationReceived location: CLLocation)

    /// Sends the delegate errors related to failure of the procedure.
    ///
    /// A failure does not mean that the service is going to stop the operation.
    /// while an error cuases a stop, `receive(_:stoppedWithError:)` gets called instead.
    ///
    /// - parameter liveTrackerReceiver: the receiver that had failure.
    /// - Parameter error: `Error` describing the failure.
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, failedWithError error: Error)

    /// Tells the delegate that the operation is going to stop with or without an error.
    ///
    /// After such errors, you may use `restart()` method to start it again.
    ///
    /// - Parameter liveTrackerReceiver: The receiver object that stopped.
    /// - Parameter error: Error which caused the process to stop, if there is any.
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, stoppedWithError error: Error?)
}

public final class MapirLiveTrackerReceiver {

    // MARK: General Properties

    /// Map.ir access token which is needed to access the sevices.
    public private(set) var accessToken: String?
    private var topic: String?

    public private(set) var trackingIdentifier: String?

    private var mqttClient = MQTTClient()

    /// All updates are sent the delegate class.
    public var delegate: ReceiverDelegate?

    /// Maximum number of retries that SDK itself handles.
    public var maximumNumberOfRetries = 3
    private var retries = 0

    private let deviceIdentifier: UUID = {
        let uuid: UUID?
        #if os(iOS) || os(watchOS) || os(tvOS)
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid
        }
        #endif
        return UUID()
    }()

    public enum Status {
        case initiated
        case starting
        case running
        case stopped
    }

    /// Indicates the current status of the service.
    ///
    /// It can be one of 4 different states: `initiated`, `starting`, `running`, `stopped`.
    public private(set) var status: Status = .initiated

    // MARK: Initializers

    /// Initializes a Receiver object.
    ///
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    /// Starting the publisher fails if you don't define the this key-value pair.
    public init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPIRAccessToken") as? String {
            self.accessToken = token
        }
        commonInit()
    }

    /// DescriptionInitializes a Receiver object.
    ///
    /// - Parameter token: Your Map.ir access token.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    public init(token: String) {
        self.accessToken = token
        commonInit()
    }

    private func commonInit() {
        mqttClient.delegate = self
    }

    // MARK: Start

    public func start(withTrackingIdentifier identifier: String) {
        switch status {
        case .running, .starting:
            delegate?.receiver(self, failedWithError: TrackingError.ServiceError.serviceCurrentlyRunning)
        case .stopped, .initiated:
            retries = 0
            trackingIdentifier = identifier
            // Request topic, username and password from the server.
            self.requestTopic(trackingIdentifier: identifier, completionHandler: requestTopicCompletionHandler)
        }
    }

    private func connectMqtt() {
        self.mqttClient.connect { [weak self] in
            // TODO: Subscribe on topic and start receiving.
            guard let topic = self?.topic else { return }
            self?.mqttClient.subscribe(toTopic: topic) { [weak self] in
                self?.status = .running
            }
        }
    }

    private lazy var requestTopicCompletionHandler: ((Result<(String, String, String), Error>) -> Void) = {  [weak self] (result) in // TODO: Chech if [weak self] is needed.
        guard let self = self else { return }
        switch result {
        case .failure(let error):
            if self.retries < self.maximumNumberOfRetries {
                guard let trackingIdentifier = self.trackingIdentifier else { return }
                self.retries += 1
                self.requestTopic(trackingIdentifier: trackingIdentifier, completionHandler: self.requestTopicCompletionHandler)
            } else {
                self.delegate?.receiver(self, failedWithError: error)
                self.status = .stopped
            }
        case .success(let topic, let username, let password):
            self.topic = topic
            self.mqttClient.username = username
            self.mqttClient.password = password

            self.retries = 0
            // If request succeeds, connect to MQTT Client.
            self.connectMqtt()
        }
    }

    private func requestTopic(trackingIdentifier: String,
                              completionHandler: @escaping (Result<(String, String, String), Error>) -> Void) {

        let urlComponents = NetworkUtilities.shared.defaultURLComponents
        let url = urlComponents.url!
        var request = URLRequest(url: url)

        guard let token = accessToken else {
            delegate?.receiver(self, failedWithError: TrackingError.ServiceError.apiKeyNotAvailable)
            return
        }

        request.addValue(token, forHTTPHeaderField: "x-api-key")
        request.addValue(NetworkUtilities.shared.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.timeoutInterval = 10

        guard let trackingIdentifier = self.trackingIdentifier else { return }
        let bodyDictionary: JSONDictionary = ["type": "subscriber", "track_id": trackingIdentifier, "device_id": deviceIdentifier.uuidString]

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        guard let encodedBody = try? jsonEncoder.encode(bodyDictionary) else { return }
        request.httpBody = encodedBody

        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let data = data else { return }
            do {
                let decodedData = try JSONDecoder().decode(NewLiveTrackerResponse.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(.success((decodedData.data.topic, decodedData.data.username, decodedData.data.password)))
                }
                return
            } catch let decodingError {
                DispatchQueue.main.async {
                    completionHandler(.failure(decodingError))
                }
                return
            }
        }.resume()
    }

    // MARK: Stop

    private var expectedDisconnect = false

    /// Stops the service.
    public func stop() {
        expectedDisconnect = true

        mqttClient.disconnect()

        retries = 0
        self.status = .stopped
    }
}

// MARK: - MQTT Client Delegate
extension MapirLiveTrackerReceiver: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        guard let delegate = delegate else { return }

        if expectedDisconnect {
            delegate.receiver(self, stoppedWithError: nil)
            self.stop()
            expectedDisconnect = false
        } else if retries < maximumNumberOfRetries {
            self.connectMqtt()
            retries += 1
        } else {
            delegate.receiver(self, stoppedWithError: error)
        }
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data) {
        // Do nothing.
    }

    func mqttClient(_ mqttClient: MQTTClient, receivedData data: Data) {
        guard let delegate = delegate else { return }
        do {
            let decodedProto = try LiveTracker_Location(serializedData: data)
            let location = CLLocation(protoLocation: decodedProto)
            delegate.receiver(self, locationReceived: location)
        } catch let error {
            delegate.receiver(self, failedWithError: TrackingError.ServiceError.couldNotDecodeProtobufData(error))
        }
    }
}
