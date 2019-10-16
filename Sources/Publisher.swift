//
//  MapirLiveTracker.swift
//  MapirLiveTracker
//
//  Created by Alireza Asadi on 13 Mordad, 1398 AP.
//  Copyright © 1398 Map. All rights reserved.
//

// Include Foundation
@_exported import Foundation
import CocoaMQTT
import CoreLocation
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public typealias JSONDictionary = [String: String]

public typealias Meters = Double

public protocol PublisherDelegate: class {
    
    /// Sends the delegate the latest published `CLLocation` object.
    ///
    /// - parameter publisher: the publisher that sent the location.
    /// - Parameter location: `CLLocation` instance of published data.
    /// It does not contain accuracy, floor and altitude data.
    func publisher(_ publisher: Publisher, publishedLocation location: CLLocation)

    /// Sends the failure details to the delegate.
    ///
    /// - Parameter publisher: The publisher which failed
    /// - Parameter error: `Error` describing the failure.
    func publisher(_ publisher: Publisher, failedWithError error: Error)

    /// Tells the delegate that the operation is going to stop with or without an error.
    ///
    /// After such errors, you may use `restart()` method to start it again.
    ///
    /// - Parameter publisher: Publisher object that stopped.
    /// - Parameter error: Error which caused the process to stop, if there is any.
    func publisher(_ publisher: Publisher, stoppedWithError error: Error?)
}

public final class Publisher {

    // MARK: General Properties

    /// Your access token of Map.ir services.
    /// Visit [App Registration website](https://corp.map.ir/appregistration) for more information.
    private var account: AccountManager
    private var topic: String?

    /// Current tracking identifier which service is using.
    /// `stop()` method does not remove tracking identifier,
    /// so you can use `restart()` method to publish data of the same identifier.
    public private(set) var trackingIdentifier: String?

    private var mqttClient: MQTTClient

    /// The publisher's delegate.
    ///
    /// Publisher sents notifications about published data and failures to the delegate.
    public weak var delegate: PublisherDelegate?

    private let locationManager: LocationManager

    /// Accuracy of the location service.
    public var serviceAccuracy: CLLocationAccuracy {
        get { locationManager.locationManager.desiredAccuracy }
        set { locationManager.locationManager.desiredAccuracy = newValue }
    }

    /// Distance filter for location service
    public var distanceFilter: Meters  {
        get { return locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue}
    }

    /// Maximum number of retries that SDK itself handles.
    public var networkConfiguration: NetworkConfiguration
    private var retries = 0

    /// Status of Publisher class
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


    /// Initializes a Publisher object.
    ///
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// starting the publisher fails if you don't define the this key-value pair.
    ///
    /// - Parameter distanceFilter: New location will be published when the user moves this amount from last published location.
    public init(distanceFilter: Meters) {
        self.account                    = AccountManager()
        self.locationManager            = LocationManager()
        self.networkConfiguration       = .mapirDefault
        self.mqttClient                 = MQTTClient(networkConfiguration: networkConfiguration)
        self.status                     = .initiated
        self.locationManager.delegate   = self
        self.distanceFilter             = distanceFilter
        self.mqttClient.delegate        = self

    }

    /// Initializes a Publisher object.
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    /// starting the publisher fails if you don't define the this key-value pair.
    ///
    /// - Parameter accessToken: Your Map.ir access token.
    /// - Parameter distanceFilter: New location will be published when the user moves this amount from last published location.
    public init(accessToken: String, distanceFilter: Meters) {
        self.account                    = AccountManager(accessToken: accessToken)
        self.locationManager            = LocationManager()
        self.networkConfiguration       = .mapirDefault
        self.mqttClient                 = MQTTClient(networkConfiguration: networkConfiguration)
        self.status                     = .initiated
        self.locationManager.delegate   = self
        self.distanceFilter             = distanceFilter
        self.mqttClient.delegate        = self
    }

    // MARK: Start

    /// Starts publishing location of the current device.
    ///
    /// This method first authorizes the user then starts publishing. it may take some time to run.
    /// If the starting fails, you will be notified via `publisher(_:stoppedWithError:)` delegate method.
    /// A receiver that uses this identifier receives the data which is published in this session.
    ///
    /// - Attention: You yourself must handle uniqueness of your tracking identifiers.
    /// Otherwise conflicts may occure between published and received data.
    ///
    /// - Parameter identifier: A string which is used to name the current publishing session.
    public func start(withTrackingIdentifier identifier: String) {
        guard account.isAuthenticated else {
            self.delegate?.publisher(self, failedWithError: ServiceError.apiKeyNotAvailable)
            return
        }

        switch status {
        case .running, .starting:
            delegate?.publisher(self, failedWithError: ServiceError.serviceCurrentlyRunning)
            return
        case .stopped, .initiated:
            retries = 0
            trackingIdentifier = identifier
            // Request topic, username and password from the server.
            self.requestTopic(trackingIdentifier: identifier, completionHandler: requestTopicCompletionHandler)
        }
    }

    private func connectMqtt() {
        self.mqttClient.connect { [weak self] in
            do {
                try self?.locationManager.startTracking()
                self?.status = .running
            } catch let error {
                if let self = self {
                    self.status = .stopped
                    self.delegate?.publisher(self, failedWithError: error)
                }
            }
        }
    }

    private lazy var requestTopicCompletionHandler: ((Result<(String, String, String), Error>) -> Void) = { [weak self] (result) in
        guard let self = self else { return }
        switch result {
        case .failure(let error):
            if self.retries < self.networkConfiguration.maximumNetworkRetries {
                guard let trackingIdentifier = self.trackingIdentifier else { return }
                self.requestTopic(trackingIdentifier: trackingIdentifier, completionHandler: self.requestTopicCompletionHandler)
                self.retries += 1
            } else {
                self.delegate?.publisher(self, failedWithError: error)
                self.status = .stopped
            }
        case .success(let topic, let username, let password):
            self.retries = 0
            self.topic = topic

            self.mqttClient.username = username
            self.mqttClient.password = password

            // If request succeeds, connect to MQTT Client.
            self.retries = 0
            self.connectMqtt()
        }
    }

    private func requestTopic(trackingIdentifier: String,
                              completionHandler: @escaping (Result<(String, String, String), Error>) -> Void) {

        let url = networkConfiguration.serverURL
        var request = URLRequest(url: url)

        guard let accessToken = account.accessToken else {
            preconditionFailure("Token removed.")
        }

        request.addValue(accessToken, forHTTPHeaderField: "x-api-key")
        request.addValue(networkConfiguration.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.timeoutInterval = 10

        let bodyDictionary: JSONDictionary = ["type": "publisher", "track_id": trackingIdentifier, "device_id": self.account.deviceIdentifier.uuidString]

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

        locationManager.stopTracking()
        mqttClient.disconnect()
        
        self.retries = 0
        self.status = .stopped
    }

    // MARK: Restart

    func restart() {
        guard mqttClient.username != nil, mqttClient.password != nil, topic != nil else {
            guard let delegate = delegate else { return }
            delegate.publisher(self, stoppedWithError: ServiceError.authorizationNotAvailable)
            self.stop()
            return
        }

        self.connectMqtt()
    }
}

// MARK: - Location Manager Delegate
extension Publisher: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManager, locationUpdated location: CLLocation) {

        guard locationManager.status == .tracking else { return }
        guard mqttClient.status == .connected else { return }

        let proto = LiveTracker_Location(location: location)

        do {
            let data = try proto.serializedData()
            guard let topic = topic else { return }
            mqttClient.publish(data: data, onTopic: topic)
        } catch let error {
            delegate?.publisher(self, failedWithError: ServiceError.couldNotEncodeProtobufObject(desc: error))
        }
    }

    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error) {
        guard let delegate = self.delegate else { return }
        delegate.publisher(self, stoppedWithError: error)
        self.stop()
    }


}

// MARK: - MQTT Client Delegate
extension Publisher: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        guard let delegate = self.delegate else { return }

        if expectedDisconnect {
            delegate.publisher(self, stoppedWithError: nil)
            self.stop()
            expectedDisconnect = false
        } else if !expectedDisconnect, retries < networkConfiguration.maximumNetworkRetries {
            self.connectMqtt()
            retries += 1
        } else {
            delegate.publisher(self, stoppedWithError: error)
            self.stop()
        }
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data) {
        guard let delegate = self.delegate else { return }
        do {
            let decodedProto = try LiveTracker_Location(serializedData: data)
            let location = CLLocation(protoLocation: decodedProto)
            delegate.publisher(self, publishedLocation: location)
        } catch let error {
            delegate.publisher(self, failedWithError: error)
        }
    }

    func mqttClient(_ mqttClient: MQTTClient, receivedData data: Data) {
        // Do nothing
    }


}
