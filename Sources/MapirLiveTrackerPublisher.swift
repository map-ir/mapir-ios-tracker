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

enum TrackerType: String, CustomStringConvertible {
    case receiver
    case publisher

    var description: String {
        return self.rawValue
    }
}

protocol MapirLiveTrackerDelegate {
    func liveTracker(_ liveTracker: MapirLiveTrackerPublisher, failedWithError error: Error)
}

public final class MapirLiveTrackerPublisher {
    public var accessToken: String?
    var username: String?
    var password: String?
    var topic: String?

    public var trackingIdentifier: String?

    private var mqttClient = MQTTClient()

    var delegate: MapirLiveTrackerDelegate?

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private let locationManager = LocationManager(type: .publisher)
    private static let defaultDistanceFilter: Meters = 10.0

    let deviceIdentifier: UUID = {
        let uuid: UUID?
        #if os(iOS) || os(watchOS) || os(tvOS)
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid
        }
        #endif
        return UUID()
    }()

    init(distanceFilter: Meters = defaultDistanceFilter) {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPIRAccessToken") as? String {
            self.accessToken = token
        }
    }

    init(token: String, distanceFilter: Meters = defaultDistanceFilter) {
        self.accessToken = token
        commonInit(distanceFilter: distanceFilter)
    }

    private func commonInit(distanceFilter: Meters) {
        setupCoders()
    }

    private func setupCoders() {
        jsonEncoder.outputFormatting = .prettyPrinted
    }

    public func start(withTrackingIdentifier identifier: String) {

        // Request topic, username and password from the server.
        self.requestTopic(trackingIdentifier: identifier) { (result) in
            // TODO: Chech if [weak self] is needed.
            // guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.liveTracker(self, failedWithError: error)
                break
            case .success(let topic, let username, let password):
                self.topic = topic
                self.username = username
                self.password = password

                // If request succeeds, connect to MQTT Client.
                self.mqttClient.connect {

                    // If connection succeeds, start locating and publishing data.
                    do {
                        try self.locationManager.startTracking()
                    } catch let error{
                        self.delegate?.liveTracker(self, failedWithError: error)
                    }
                }
                break
            }
        }
    }

    private func requestTopic(trackingIdentifier: String,
                              completionHandler: @escaping (Result<(String, String, String), Error>) -> Void) {

        let urlComponents = NetworkUtilities.shared.defaultURLComponents
        let url = urlComponents.url!
        var request = URLRequest(url: url)

        guard let token = accessToken else {
            delegate?.liveTracker(self, failedWithError: TrackingError.ServiceError.apiKeyNotAvailable)
            return
        }

        request.addValue(token, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.timeoutInterval = 10
        // TODO: Update types for subscriber and publisher

        guard let trackingIdentifier = self.trackingIdentifier else { return }
        let bodyDictionary: JSONDictionary = ["type": "\(TrackerType.publisher)", "track_id": trackingIdentifier, "device_id": deviceIdentifier.uuidString]
        guard let encodedBody = try? self.jsonEncoder.encode(bodyDictionary) else { return }
        request.httpBody = encodedBody

        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let data = data else { return }
            do {
                let decodedData = try self.jsonDecoder.decode(NewLiveTrackerResponse.self, from: data)
                completionHandler(.success((decodedData.data.topic, decodedData.data.username, decodedData.data.password)))
                return
            } catch let decodingError {
                completionHandler(.failure(decodingError))
                return
            }
        }
    }
}


extension MapirLiveTrackerPublisher: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManager, locationUpdated: CLLocation) {
        // TODO: Implement usage of protobuf.
        let test = "Hello, World!".data(using: .utf8)
        guard let topic = topic else { return }
        mqttClient.publish(data: test!, onTopic: topic)
    }

    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error) {
        // TODO: Send location update failure to the user.
    }


}

extension MapirLiveTrackerPublisher: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        // TODO: Handle disconnection from server. and tell the user.
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData: Data) {
        // TODO: Convert data to something like message and create a queue for messages.
    }


}
