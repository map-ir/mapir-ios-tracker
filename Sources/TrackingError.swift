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

        var errorDescription: String? {
            switch self {
            case .apiKeyNotAvailable:
                return "Starting service requires Map.ir access token. add your access in Info.plist or use init(token:) initalizer."
            }
        }
    }

    enum LocationServiceError: Error, LocalizedError {
        case unauthorizedForAlwaysUsage

        var errorDescription: String? {
            switch self {
            case .unauthorizedForAlwaysUsage:
                return "Authorization level for using tracker must be set to \"Always Usage\""
            }
        }
    }
}
