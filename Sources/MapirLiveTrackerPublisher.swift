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

    var mqqtHost = "81.91.152.2"
    var mqttPort = 1883

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

    private var mqttClient: CocoaMQTT!

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

    public func start(withTrackingIdentifier identifier: String) {
        // TODO: Go get the username, password and topic from map.ir server.
    }

    private func setupCoders() {
        jsonEncoder.outputFormatting = .prettyPrinted
    }

    private func requestTopic() {
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
        let bodyDictionary: JSONDictionary = ["type": "", "track_id": trackingIdentifier, "device_id": deviceIdentifier.uuidString]
        guard let encodedBody = try? self.jsonEncoder.encode(bodyDictionary) else { return }
        request.httpBody = encodedBody

        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let _ = error {
                return
            }

            guard let data = data else { return }
            guard let decodedData = try? self.jsonDecoder.decode(NewLiveTrackerResponse.self, from: data) else {
                return
            }
            self.password = decodedData.data.password
            self.username = decodedData.data.username
            self.topic    = decodedData.data.topic

        }
    }
}

struct NewLiveTrackerResponse: Decodable {

    struct Data: Decodable {
        var topic: String
        var username: String
        var password: String
    }

    var data: NewLiveTrackerResponse.Data
    var message: String
}
