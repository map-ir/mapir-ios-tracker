//
//  Errors.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation

enum LiveTrackerError: Error {

    case accessTokenNotAvailable

    case serviceCurrentlyRunning

    case notAuthorizedForLocationUsage(CLAuthorizationStatus)

    case trackingIdentifierNotAvailable

    var errorDescription: String? {
        switch self {
        case .accessTokenNotAvailable:
            return "Starting service requires Map.ir access token. add your access token in Info.plist or use initalizer that accepts token."

        case .serviceCurrentlyRunning:
            return "Can't start a publisher while a service is being started or already started."

        case .trackingIdentifierNotAvailable:
            return "Tracking identifier is not available. You must specify it first, using start(withTrackingIdentifier:) instance method."

        case .notAuthorizedForLocationUsage(let current):
            return "Location service permission is required for Publisher. It must be set to \"When In Use\" or \"Always\" but it is \"\(current.description)\"."
        }
    }
}

fileprivate extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorizedWhenInUse:
            return "When In Use"
        case .authorizedAlways:
            return "Always"
        @unknown default:
            return "Unknown"
        }
    }
}
