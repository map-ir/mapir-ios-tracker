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

/// Type alias for Meters.
public typealias Meters = Double

/// Protocol for Publisher Delegate.
@objc(MLTPublisherDelegate)
public protocol PublisherDelegate: class {

    /// Tells the delegate that the operation is going to stop with or without an error.
    ///
    /// - Parameter publisher: Publisher object that stopped.
    /// - Parameter error: Error which caused the process to stop, if there is any.
    ///
    /// After such errors, you may use `restart()` method to start it again.
    @objc(publisher:stoppedWithError:)
    func publisher(_ publisher: Publisher, stoppedWithError error: Error?)

    /// Sends the delegate the latest published `CLLocation` object.
    ///
    /// - parameter publisher: the publisher that sent the location.
    /// - Parameter location: `CLLocation` instance of published data.
    ///     It does not contain accuracy, floor and altitude data.
    @objc(publisher:publishedLocation:)
    optional func publisher(_ publisher: Publisher, publishedLocation location: CLLocation)

    /// Sends the failure details to the delegate.
    ///
    /// - Parameter publisher: The publisher which failed
    /// - Parameter error: `Error` describing the failure.
    @objc(publisher:failedWithError:)
    optional func publisher(_ publisher: Publisher, failedWithError error: Error)
}

public extension PublisherDelegate {

    /// Default implementation has empty body.
    @inlinable func publisher(_ publisher: Publisher, publishedLocation location: CLLocation) { return }

    /// Default implementation has empty body.
    @inlinable func publisher(_ publisher: Publisher, failedWithError error: Error) { return }
}

/// An object that handles publishing user location lively based on a tracking identifier.
@objc(MLTPublisher)
public final class Publisher: NSObject {

    // MARK: General Properties

    private var topic: String?

    /// Current tracking identifier which service is using.
    ///
    /// `stop()` method does not remove tracking identifier,
    /// so you can use `restart()` method to publish data of the same identifier.
    public private(set) var trackingIdentifier: String?

    private var mqttClient: MQTTClient

    /// The publisher's delegate.
    ///
    /// Publisher sents notifications about published data and failures to the delegate.
    @objc(delegate)
    public weak var delegate: PublisherDelegate?

    private let locationManager: LocationManager

    /// Accuracy of the location service.
    @objc(serviceAccuracy)
    public var serviceAccuracy: CLLocationAccuracy {
        get { locationManager.locationManager.desiredAccuracy }
        set { locationManager.locationManager.desiredAccuracy = newValue }
    }

    /// Distance filter for location service
    @objc(distanceFilter)
    public var distanceFilter: Meters  {
        get { return locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue}
    }

    private var retries = 0

    /// Status of Publisher class
    @objc(MLTPublisherStatus)
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


    /// Initializes a Publisher object.
    ///
    /// - Parameter distanceFilter: New location will be published when the user moves this amount from last published location.
    ///
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// starting the publisher fails if you don't define the this key-value pair.
    @objc(initWithDistanceFilter:)
    public init(distanceFilter: Meters) {
        AccountManager.shared.accessToken = nil
        self.locationManager              = LocationManager()
        self.mqttClient                   = MQTTClient()
        self.status                       = .initiated
        super.init()

        self.locationManager.delegate     = self
        self.distanceFilter               = distanceFilter
        self.mqttClient.delegate          = self

    }

    /// Initializes a Publisher object.
    ///
    /// - Parameter accessToken: Your Map.ir access token.
    /// - Parameter distanceFilter: New location will be published when the user moves this amount from last published location.
    ///
    /// Consider adding your valid access token with key of `MAPIRAccessToken` to your **Info.plist**.
    /// If you don't have any, visit [App Registration website](https://corp.map.ir/appregistration).
    /// starting the publisher fails if you don't define the this key-value pair.
    @objc(initWithAccessToken:distanceFilter:)
    public init(accessToken: String, distanceFilter: Meters) {
        AccountManager.shared.accessToken = accessToken
        self.locationManager              = LocationManager()
        self.mqttClient                   = MQTTClient()
        self.status                       = .initiated
        super.init()

        self.locationManager.delegate     = self
        self.distanceFilter               = distanceFilter
        self.mqttClient.delegate          = self
    }

    // MARK: Start

    /// Starts publishing location of the current device.
    ///
    /// - Parameter trackingIdentifier: A string which is used to name the current publishing session.
    ///
    /// This method first authorizes the user then starts publishing. it may take some time to run.
    /// If the starting fails, you will be notified via `publisher(_:stoppedWithError:)` delegate method.
    /// A receiver that uses this identifier receives the data which is published in this session.
    ///
    /// - Attention: You yourself must handle uniqueness of your tracking identifiers.
    ///     Otherwise conflicts may occure between published and received data.
    @objc(startWithTrackingIdentifier:)
    public func start(withTrackingIdentifier trackingIdentifier: String) {
        guard AccountManager.shared.isAuthenticated else {
            stopService(shouldCallDelegate: true, error: LiveTrackerError.accessTokenNotAvailable)
            return
        }

        switch status {
        case .running, .starting:
            delegate?.publisher?(self, failedWithError: LiveTrackerError.serviceCurrentlyRunning)
            return
        case .stopped, .initiated:
            self.retries = 0
            self.trackingIdentifier = trackingIdentifier
            // Request topic, username and password from the server.
            AccountManager.shared.requestTopic(forTrackingIdentifier: trackingIdentifier, type: .publisher, completionHandler: requestTopicCompletionHandler)
        }
    }

    private func startService() {
        do {
            try self.locationManager.startTracking()

            self.mqttClient.connect { [weak self] in
                guard let self = self else { return }
                logDebug("Connected to MQTTBroker.")
                    self.status = .running
            }
        } catch let locationServiceError {
            stopService(shouldCallDelegate: true, error: locationServiceError)
        }
    }

    private lazy var requestTopicCompletionHandler: (String?, Error?) -> Void = { [weak self] (topic, error) in
        guard let self = self else { return }
        if let error = error {
            if let error = error as? InternalError, error == InternalError.couldNotCreateTopic {
                logError("Live Tracker Service is not available. Contant support.")
                self.stopService(shouldCallDelegate: true, error: LiveTrackerError.liveTrackerServiceNotAvailable)
            } else if self.retries < NetworkingManager.shared.configuration.maximumNetworkRetries {
                self.retries += 1
                logDebug("Couldn't create topic. Retrying in 5 seconds. (\(self.retries))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self else { return }
                    guard let trackingIdentifier = self.trackingIdentifier else { return }
                    AccountManager.shared.requestTopic(forTrackingIdentifier: trackingIdentifier, type: .publisher, completionHandler: self.requestTopicCompletionHandler)
                }
            } else {
                logDebug("Couldn't create topic. Maximum retries reached. Stopping service. (\(self.retries))")
                self.stopService(shouldCallDelegate: true, error: error)
            }

            return
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
        locationManager.stopTracking()
        mqttClient.disconnect()

        self.status = .stopped

        self.retries = 0

        if shouldCallDelegate {
            self.delegate?.publisher(self, stoppedWithError: error)
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
            startService()
        }
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
            logError("Protobuf serialization failure.\nError: \(error)")
        }
    }

    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error) {
        stopService(shouldCallDelegate: true, error: error)
    }
}

// MARK: - MQTT Client Delegate
extension Publisher: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {

        if expectedDisconnect {
            expectedDisconnect = false
            stopService(shouldCallDelegate: true)
        } else if retries < NetworkingManager.shared.configuration.maximumNetworkRetries {
            self.retries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                guard let self = self else { return }
                self.startService()
            }
        } else {
            stopService(shouldCallDelegate: true, error: error)
        }
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data) {
        guard let delegate = self.delegate else { return }
        do {
            let decodedProto = try LiveTracker_Location(serializedData: data)
            let location = CLLocation(protoLocation: decodedProto)
            delegate.publisher?(self, publishedLocation: location)
        } catch let error {
            logError("protobuf serialization failure.\nError: \(error)")
        }
    }
}
