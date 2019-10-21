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


public protocol SubscriberDelegate: class {

    /// Receives location updates of the specified tracking identifier.
    ///
    /// - parameter subscriber: the receiver that received the location.
    /// - Parameter location: `CLLocation` instance of received data.
    /// It does not contain accuracy, floor and altitude data.
    ///
    /// You may check the timestamp of the received `location` object to validate it.
    func subscriber(_ subscriber: Subscriber, locationReceived location: CLLocation)

    /// Tells the delegate that the operation is going to stop with or without an error.
    ///
    /// After such errors, you may use `restart()` method to start it again.
    ///
    /// - Parameter subscriber: The receiver object that stopped.
    /// - Parameter error: Error which caused the process to stop, if there is any.
    func subscriber(_ subscriber: Subscriber, stoppedWithError error: Error?)
}

public extension SubscriberDelegate {

    /// Sends the delegate errors related to failure of the procedure.
    ///
    /// A failure does not mean that the service is going to stop the operation.
    /// while an error cuases a stop, `receive(_:stoppedWithError:)` gets called instead.
    ///
    /// Default implementation provided.
    /// - parameter subscriber: the receiver that had failure.
    /// - Parameter error: `Error` describing the failure.
    @inlinable func subscriber(_ subscriber: Subscriber, failedWithError error: Error) { return }
}

public final class Subscriber {

    // MARK: General Properties

    /// Your access token of Map.ir services.
    /// Visit [App Registration website](https://corp.map.ir/appregistration) for more information.
    private(set) var account: AccountManager
    private var topic: String?

    /// Current tracking identifier which service is using.
    /// `stop()` method does not remove tracking identifier,
    /// so you can use `restart()` method to receive data of the same identifier.
    public private(set) var trackingIdentifier: String?

    private var mqttClient: MQTTClient

    /// The receiver's delegate.
    ///
    /// Receiver sents notifications about received data and failures to the delegate.
    public weak var delegate: SubscriberDelegate?

    /// Maximum number of retries that SDK itself handles.
    public var networkConfiguration: NetworkConfiguration
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

    /// Status of Receiver class
    public enum Status {
        /// Class is initiated and it's ready to start.
        case initiated

        /// Trying to connect Map.ir servers and receive credentials.
        case starting

        /// Service is runnging and data is being published successfully.
        case running

        /// Service is stopped due to user initiated stop of error occurance.
        case stopped
    }

    /// Indicates the current status of the service.
    ///
    /// It can be one of 4 different states: `initiated`, `starting`, `running`, `stopped`.
    public private(set) var status: Status

    // MARK: Initializers

    /// Initializes a Receiver object.
    ///
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    /// Starting the publisher fails if you don't define the this key-value pair.
    public init() {
        self.account                    = AccountManager()
        self.networkConfiguration       = .mapirDefault
        self.mqttClient                 = MQTTClient(networkConfiguration: networkConfiguration)
        self.status                     = .initiated
        self.mqttClient.delegate        = self
    }

    /// DescriptionInitializes a Receiver object.
    ///
    /// - Parameter token: Your Map.ir access token.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    public init(accessToken: String) {
        self.account                    = AccountManager(accessToken: accessToken)
        self.networkConfiguration       = .mapirDefault
        self.mqttClient                 = MQTTClient(networkConfiguration: networkConfiguration)
        self.status                     = .initiated
        self.mqttClient.delegate        = self
    }

    // MARK: Start

    /// Starts receiving location of the the specified tracking identifier.
    ///
    /// This method first authorizes the user then starts receiving. it may take some time to run.
    /// If the starting fails, you will be notified via `receiver(_:stoppedWithError:)` delegate method.
    /// The receiver receives the data which is published on the same tracking identifier session.
    ///
    /// - Attention: You yourself must handle uniqueness of your tracking identifiers.
    /// Otherwise conflicts may occure between published and received data.
    ///
    /// - Parameter identifier: A string which is used to name the current publishing session.
    public func start(withTrackingIdentifier identifier: String) {
        guard account.isAuthenticated else {
            self.delegate?.subscriber(self, failedWithError: ServiceError.apiKeyNotAvailable)
            return
        }

        switch status {
        case .running, .starting:
            delegate?.subscriber(self, failedWithError: ServiceError.serviceCurrentlyRunning)
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
            if self.retries < self.networkConfiguration.maximumNetworkRetries {
                guard let trackingIdentifier = self.trackingIdentifier else { return }
                self.retries += 1
                self.requestTopic(trackingIdentifier: trackingIdentifier, completionHandler: self.requestTopicCompletionHandler)
            } else {
                self.delegate?.subscriber(self, failedWithError: error)
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

        let url = networkConfiguration.serverURL
        var request = URLRequest(url: url)

        guard let accessToken = account.accessToken else {
            preconditionFailure("Token Removed.")
        }

        request.addValue(accessToken, forHTTPHeaderField: "x-api-key")
        request.addValue(self.networkConfiguration.userAgent, forHTTPHeaderField: "User-Agent")
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
    ///
    /// Stopping does not remove the previous tracking identifier.
    /// You can restart the service and the previously added tracking identifier will be used again.
    public func stop() {
        expectedDisconnect = true

        mqttClient.disconnect()

        retries = 0
        self.status = .stopped
    }

    // MARK: Restart

    func restart() {
        guard mqttClient.username != nil, mqttClient.password != nil, topic != nil else {
            guard let delegate = delegate else { return }
            delegate.subscriber(self, stoppedWithError: ServiceError.authorizationNotAvailable)
            self.stop()
            return
        }

        self.connectMqtt()
    }
}

// MARK: - MQTT Client Delegate
extension Subscriber: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        guard let delegate = delegate else { return }

        if expectedDisconnect {
            delegate.subscriber(self, stoppedWithError: nil)
            self.stop()
            expectedDisconnect = false
        } else if retries < self.networkConfiguration.maximumNetworkRetries {
            self.connectMqtt()
            retries += 1
        } else {
            delegate.subscriber(self, stoppedWithError: error)
            self.stop()
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
            delegate.subscriber(self, locationReceived: location)
        } catch let error {
            delegate.subscriber(self, failedWithError: ServiceError.couldNotDecodeProtobufData(error))
        }
    }
}
