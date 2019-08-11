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

public protocol PublisherDelegate {
    func publisher(_ liveTrackerPublisher: MapirLiveTrackerPublisher, publishedLocation location: CLLocation)
    func publisher(_ liveTrackerPublisher: MapirLiveTrackerPublisher, failedWithError error: Error)
}

extension PublisherDelegate {
    func publisher(_ liveTrackerPublisher: MapirLiveTrackerPublisher, publishedLocation location: CLLocation) { }
}

public final class MapirLiveTrackerPublisher {
    public var accessToken: String?

    private var topic: String?
    public var trackingIdentifier: String?

    private var mqttClient = MQTTClient()

    public var delegate: PublisherDelegate?

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private let locationManager = LocationManager()
    public static let defaultDistanceFilter: Meters = 10.0

    let deviceIdentifier: UUID = {
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
        case started
        case stopped
    }

    public private(set) var status: Status = .initiated

    public init(distanceFilter: Meters = defaultDistanceFilter) {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPIRAccessToken") as? String {
            self.accessToken = token
        }
        commonInit(distanceFilter: distanceFilter)
    }

    public init(token: String, distanceFilter: Meters = defaultDistanceFilter) {
        self.accessToken = token
        commonInit(distanceFilter: distanceFilter)
    }

    private func commonInit(distanceFilter: Meters) {
        setupCoders()
        locationManager.delegate = self
        mqttClient.delegate      = self
    }

    private func setupCoders() {
        jsonEncoder.outputFormatting = .prettyPrinted
    }

    public func start(withTrackingIdentifier identifier: String) {

        switch status {
        case .started, .starting:
            delegate?.publisher(self, failedWithError: TrackingError.ServiceError.serviceCurrentlyRunning)
            return
        case .stopped, .initiated:
            // Request topic, username and password from the server.
            self.requestTopic(trackingIdentifier: identifier) { (result) in
                // TODO: Check if [weak self] is needed.
                // guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.delegate?.publisher(self, failedWithError: error)
                    self.status = .stopped
                    break
                case .success(let topic, let username, let password):
                    self.topic = topic
                    self.mqttClient.username = username
                    self.mqttClient.password = password

                    // If request succeeds, connect to MQTT Client.
                    self.mqttClient.connect {
                        // If connection succeeds, start locating and publishing data.
                        do {
                            try self.locationManager.startTracking()
                            self.status = .started
                        } catch let error {
                            self.delegate?.publisher(self, failedWithError: error)
                            self.status = .stopped
                        }
                    }
                }
            }
        }
    }

    private func requestTopic(trackingIdentifier: String,
                              completionHandler: @escaping (Result<(String, String, String), Error>) -> Void) {

        let urlComponents = NetworkUtilities.shared.defaultURLComponents
        let url = urlComponents.url!
        var request = URLRequest(url: url)

        guard let token = accessToken else {
            delegate?.publisher(self, failedWithError: TrackingError.ServiceError.apiKeyNotAvailable)
            return
        }

        request.addValue(token, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.timeoutInterval = 10

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
}


extension MapirLiveTrackerPublisher: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManager, locationUpdated location: CLLocation) {

        guard locationManager.status == .tracking else { return }
        guard mqttClient.status == .connected else { return }

        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: location.timestamp)

        var proto = LiveTracker_Location()
        proto.direction  = Float(location.course)
        proto.location   = [location.coordinate.longitude, location.coordinate.latitude]
        proto.speed      = location.speed
        proto.rtimestamp = timestamp

        do {
            let data = try proto.serializedData()
            guard let topic = topic else { return }
            mqttClient.publish(data: data, onTopic: topic)
        } catch let error {
            print(error)
        }
    }

    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error) {
        guard let delegate = self.delegate else { return }
        delegate.publisher(self, failedWithError: error)
    }


}

extension MapirLiveTrackerPublisher: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        // TODO: Handle disconnection from server. and tell the user.
        guard let delegate = self.delegate else { return }
        guard let error = error else { return }
        delegate.publisher(self, failedWithError: error)
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data) {
        // TODO: Convert data to something like message and create a queue for messages.
        guard let delegate = self.delegate else { return }
        guard let decodedProto = try? LiveTracker_Location(serializedData: data) else { return }

        let coordinate = CLLocationCoordinate2D(latitude: decodedProto.location[1], longitude: decodedProto.location[0])
        let course = Double(decodedProto.direction)
        let speed = decodedProto.speed
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: decodedProto.rtimestamp) else { return }

        let location = CLLocation(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: course, speed: speed, timestamp: date)
        delegate.publisher(self, publishedLocation: location)
    }


}
