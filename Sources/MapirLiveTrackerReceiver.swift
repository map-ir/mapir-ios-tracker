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
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, locationReceived location: CLLocation)
    func receiver(_ liveTrackerReceiver: MapirLiveTrackerReceiver, failedWithError error: Error)
}

public final class MapirLiveTrackerReceiver {
    public var accessToken: String?
    private var topic: String?

    public var trackingIdentifier: String?

    private var mqttClient = MQTTClient()

    var delegate: ReceiverDelegate?

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

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
        case running
        case stopped
    }

    public private(set) var status: Status = .initiated

    init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPIRAccessToken") as? String {
            self.accessToken = token
        }
        commonInit()
    }

    init(token: String) {
        self.accessToken = token
        commonInit()
    }

    private func commonInit() {
        setupCoders()
        mqttClient.delegate = self
    }

    private func setupCoders() {
        jsonEncoder.outputFormatting = .prettyPrinted
    }

    public func start(withTrackingIdentifier identifier: String) {

        switch status {
        case .running, .starting:
            delegate?.receiver(self, failedWithError: TrackingError.ServiceError.serviceCurrentlyRunning)
        case .stopped, .initiated:
            trackingIdentifier = identifier
            // Request topic, username and password from the server.
            self.requestTopic(trackingIdentifier: identifier) { (result) in
                // TODO: Chech if [weak self] is needed.
                // guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.delegate?.receiver(self, failedWithError: error)
                    self.status = .stopped
                    break
                case .success(let topic, let username, let password):
                    self.topic = topic
                    self.mqttClient.username = username
                    self.mqttClient.password = password

                    // If request succeeds, connect to MQTT Client.
                    self.mqttClient.connect {
                        // TODO: Subscribe on topic and start receiving.
                        guard let topic = self.topic else { return }
                        self.mqttClient.subscribe(toTopic: topic)
                        self.status = .running
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
            delegate?.receiver(self, failedWithError: TrackingError.ServiceError.apiKeyNotAvailable)
            return
        }

        request.addValue(token, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.timeoutInterval = 10

        guard let trackingIdentifier = self.trackingIdentifier else { return }
        let bodyDictionary: JSONDictionary = ["type": "\(TrackerType.receiver)", "track_id": trackingIdentifier, "device_id": deviceIdentifier.uuidString]
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
        }
    }
}

extension MapirLiveTrackerReceiver: MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?) {
        guard let delegate = delegate else { return }
        guard let error = error else { return }

        delegate.receiver(self, failedWithError: error)
    }

    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data) {
        // Do nothing.
    }

    func mqttClient(_ mqttClient: MQTTClient, receivedData data: Data) {
        guard let delegate = delegate else { return }
        do {
            let decodedProto = try LiveTracker_Location(serializedData: data)
            let coordinate = CLLocationCoordinate2D(latitude: decodedProto.location[1], longitude: decodedProto.location[0])
            let course = Double(decodedProto.direction)
            let speed = decodedProto.speed
            let dateFormatter = ISO8601DateFormatter()
            guard let date = dateFormatter.date(from: decodedProto.rtimestamp) else { return }

            let location = CLLocation(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: course, speed: speed, timestamp: date)
            delegate.receiver(self, locationReceived: location)
        } catch let error {
            delegate.receiver(self, failedWithError: TrackingError.ServiceError.couldNotDecodeProtobufData(error))
        }
    }
}
