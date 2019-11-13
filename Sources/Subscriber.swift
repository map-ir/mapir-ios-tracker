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

/// An object that handles publishing user location lively.
@objc(MLTSubscriberDelegate)
public protocol SubscriberDelegate: class {

    /// Receives location updates of the specified tracking identifier.
    ///
    /// - parameter subscriber: the receiver that received the location.
    /// - Parameter location: `CLLocation` instance of received data.
    ///     It does not contain accuracy, floor and altitude data.
    ///
    /// You may check the timestamp of the received `location` object to validate it.
    @objc(subscriber:locationReceived:)
    func subscriber(_ subscriber: Subscriber, locationReceived location: CLLocation)

    /// Tells the delegate that the operation is going to stop with or without an error.
    ///
    /// - Parameter subscriber: The receiver object that stopped.
    /// - Parameter error: Error which caused the process to stop, if there is any.
    ///
    /// After such errors, you may use `restart()` method to start it again.
    @objc(subscriber:stoppedWithError:)
    func subscriber(_ subscriber: Subscriber, stoppedWithError error: Error?)

    /// Sends the delegate errors related to failure of the procedure.
    ///
    /// - parameter subscriber: the receiver that had failure.
    /// - Parameter error: `Error` describing the failure.
    ///
    /// A failure does not mean that the service is going to stop the operation.
    /// while an error cuases a stop, `receive(_:stoppedWithError:)` gets called instead.
    @objc(subscriber:failedWithError:)
    optional func subscriber(_ subscriber: Subscriber, failedWithError error: Error)
}

public extension SubscriberDelegate {

    /// Default implementation has empty body.
    @inlinable func subscriber(_ subscriber: Subscriber, failedWithError error: Error) { return }
}

/// An object that handles fetching location lively based on a tracking identifier.
@objc(MLTSubscriber)
public final class Subscriber: NSObject {

    // MARK: General Properties

    /// Last received valid location.
    ///
    /// This property has the last valid received location. Sometimes received location is
    /// not valid due to its timestamp. In this case location won't be saved in this property.
    @objc(lastReceivedLocation)
    public private(set) var lastReceivedLocation: CLLocation?

    /// Current tracking identifier which service is using.
    ///
    /// `stop()` method does not remove tracking identifier,
    /// so you can use `restart()` method to receive data of the same identifier.
    @objc(trackingIdentifier)
    public private(set) var trackingIdentifier: String?

    private var mqttClient: MQTTClient

    private var topic: String?

    /// The receiver's delegate.
    ///
    /// Receiver sents notifications about received data and failures to the delegate.
    @objc(delegate)
    public weak var delegate: SubscriberDelegate?

    private var retries = 0

    /// Status of Receiver class
    @objc(MLTSubscriberStatus)
    public enum Status: UInt {
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
    @objc(status)
    public private(set) var status: Status

    // MARK: Initializers

    /// Initializes a Receiver object.
    ///
    /// Consider adding your valid API key with key of `MAPIRAccessToken` to your **Info.plist**.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    /// Starting the publisher fails if you don't define the this key-value pair.
    @objc(init)
    public override init() {
        AccountManager.shared.apiKey      = nil
        self.mqttClient                   = MQTTClient()
        self.status                       = .initiated
        super.init()

        self.mqttClient.delegate          = self
    }

    /// DescriptionInitializes a Receiver object.
    ///
    /// - Parameter apiKey: Your Map.ir API key.
    ///
    /// If you don't have any, visit "[App Registration website](https://corp.map.ir/appregistration)".
    @objc(initWithAPIKey:)
    public init(apiKey: String) {
        AccountManager.shared.apiKey      = apiKey
        self.mqttClient                   = MQTTClient()
        self.status                       = .initiated
        super.init()

        self.mqttClient.delegate          = self
    }

    // MARK: Start

    /// Starts receiving location of the the specified tracking identifier.
    ///
    /// - Parameter trackingIdentifier: A string which is used to name the current publishing session.
    ///
    /// This method first authorizes the user then starts receiving. it may take some time to run.
    /// If the starting fails, you will be notified via `receiver(_:stoppedWithError:)` delegate method.
    /// The receiver receives the data which is published on the same tracking identifier session.
    ///
    /// - Attention: You yourself must handle uniqueness of your tracking identifiers.
    /// Otherwise conflicts may occure between published and received data.
    @objc(startWithTrackingIdentifier:)
    public func start(withTrackingIdentifier trackingIdentifier: String) {
        guard AccountManager.shared.apiKeyStatus != .notAvailable else {
            logError("Subscriber can not start. API Key is not available.")
            stopService(shouldCallDelegate: true, error: LiveTrackerError.apiKeyNotAvailable)
            return
        }

        guard AccountManager.shared.apiKeyStatus != .unauthorized else {
            logError("Subscriber can not start. API Key is not valid.")
            stopService(shouldCallDelegate: true, error: LiveTrackerError.unauthorizedAPIKey)
            return
        }

        switch self.status {
        case .running, .starting:
            self.delegate?.subscriber?(self, failedWithError: LiveTrackerError.serviceCurrentlyRunning)
        case .stopped, .initiated:
            self.retries = 0
            self.trackingIdentifier = trackingIdentifier

            AccountManager.shared.requestTopic(forTrackingIdentifier: trackingIdentifier, type: .subscriber, completionHandler: self.requestTopicCompletionHandler)
        }
    }

    private func startService() {
        self.mqttClient.connect { [weak self] in

            guard let topic = self?.topic else { return }
            self?.mqttClient.subscribe(toTopic: topic) { [weak self] in
                logInfo("Subscriber connected.")
                self?.status = .running

            }
        }
    }

    private lazy var requestTopicCompletionHandler: (String?, Error?) -> () = {  [weak self] (topic, error) in
        guard let self = self else { return }
        if let error = error {
            if let error = error as? InternalError, error == InternalError.couldNotCreateTopic {
                logError("Map.ir authenticator isn't available at the moment.")
                self.stopService(shouldCallDelegate: true, error: LiveTrackerError.liveTrackerServiceNotAvailable)

            } else if let error = error as? InternalError, error == .unauthorizedToken {
                logError("Your API key is not authorized to use Map.ir live tracker serivces.")
                self.stopService(shouldCallDelegate: true, error: LiveTrackerError.unauthorizedAPIKey)

            } else if self.retries < NetworkingManager.shared.configuration.maximumNetworkRetries {
                logInfo("Couldn't reach Map.ir authenticator. retrying in 5 seconds...")
                self.retries += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self else { return }
                    guard let trackingIdentifier = self.trackingIdentifier else { return }
                    AccountManager.shared.requestTopic(forTrackingIdentifier: trackingIdentifier, type: .subscriber, completionHandler: self.requestTopicCompletionHandler)
                }
            } else {
                logError("Couldn't reach Map.ir authenticator.")
                self.stopService(shouldCallDelegate: true, error: error)
            }
        }

        guard let topic = topic else { return }

        self.topic = topic
        self.startService()
    }

    // MARK: Stop

    private var expectedDisconnect = false

    /// Stops the service.
    ///
    /// Stopping does not remove the previous tracking identifier.
    /// You can restart the service and the previously added tracking identifier will be used again.
    @objc(stop)
    public func stop() {
        expectedDisconnect = true
        stopService(shouldCallDelegate: false)
    }

    private func stopService(shouldCallDelegate: Bool, error: Error? = nil) {
        mqttClient.disconnect()

        self.status = .stopped

        retries = 0

        if shouldCallDelegate {
            self.delegate?.subscriber(self, stoppedWithError: error)
        }
    }

    // MARK: Restart

    /// Restarts the service.
    ///
    /// You can't user `restart()` unless a tracking identifier is available.
    /// A tracking identifier is added to the service once you use `start(withTrackingIdentifier:)`.
    @objc(restart)
    public func restart() {
        guard let trackingID = self.trackingIdentifier else {
            stopService(shouldCallDelegate: true, error: LiveTrackerError.trackingIdentifierNotAvailable)
            return
        }

        if mqttClient.isReady {
            start(withTrackingIdentifier: trackingID)
        } else {
            self.startService()
        }
    }
}

// MARK: - MQTT Client Delegate
extension Subscriber: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {

        if expectedDisconnect {
            expectedDisconnect = false
            self.stopService(shouldCallDelegate: true)
        } else if retries < NetworkingManager.shared.configuration.maximumNetworkRetries {
            retries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.startService()
            }
        } else {
            logError("Subscriber unexpectedly disconneted from the broker. \(error != nil ? "\(error!)" : "" )")
            stopService(shouldCallDelegate: true, error: error)
        }
    }

    private func validateReceivedLocation(location: CLLocation) -> Bool {
        if let lastReceivedLocation = lastReceivedLocation {
            if location.timestamp > lastReceivedLocation.timestamp {
                if location.timestamp > (Date() - 60 * 5) {
                    return true
                }
                return false
            }
            return false
        } else {
            if location.timestamp > (Date() - 60 * 5) {
                return true
            }
            return false
        }
    }

    func mqttClient(_ mqttClient: MQTTClient, receivedData data: Data) {
        guard let delegate = delegate else { return }
        do {
            let decodedProto = try LiveTracker_Location(serializedData: data)
            let location = CLLocation(protoLocation: decodedProto)
            if validateReceivedLocation(location: location) {
                self.lastReceivedLocation = location
                delegate.subscriber(self, locationReceived: location)
            } else {
                logInfo("Received an invalid location data. Location might be too old or older than last received location.")
            }
        } catch let error {
            logDebug("Received location deserializition failure: \(error)")
        }
    }
}
