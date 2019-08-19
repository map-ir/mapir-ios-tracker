//
//  TrackingError.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

enum TrackingError: Error {
    enum ServiceError: Error, LocalizedError {
        case apiKeyNotAvailable

        case serviceCurrentlyRunning

        case authorizationNotAvailable

        case couldNotDecodeProtobufData(Error?)
        case couldNotEncodeProtobufObject(desc: Error?)

        var errorDescription: String? {
            switch self {
            case .apiKeyNotAvailable:
                return "Starting service requires Map.ir access token. add your access in Info.plist or use init(token:) initalizer."

            case .serviceCurrentlyRunning:
                return "Can't start a publisher while a service is already started or being started."

            case .couldNotDecodeProtobufData(let error):
                if let error = error {
                    return "Couldn't decode protobuf encoded data. Contact SDK support.\nMore info: \(error)"
                } else {
                    return "Couldn't decode protobuf encoded data. Contact SDK support."
                }

            case .couldNotEncodeProtobufObject(let error):
                if let error = error {
                    return "Couldn't endcode protobuf object to data. Contact SDK support.\nMore info: \(error)"
                } else {
                    return "Couldn't endcode protobuf object to data. Contact SDK support."
                }
            case .authorizationNotAvailable:
                return "Couldn't find authorization status. use start(withTrackingIdentifier:) method to receive authorization data."
            }
        }
    }

    enum LocationServiceError: Error, LocalizedError {
        case unauthorizedForAlwaysUsage

        var errorDescription: String? {
            switch self {
            case .unauthorizedForAlwaysUsage:
                return "Authorization level must be set to \"Always Usage\" to use tracking features properly."
            }
        }
    }
}
