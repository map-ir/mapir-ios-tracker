//
//  Errors.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation

/// Errors related to the Map.ir Live Tracker service.
enum LiveTrackerError: Error {

    /// Your Map.ir API key is not available.
    ///
    /// You can't use Map.ir Live Tracker unless you have API key. If you don't have any,
    /// see "[App Regstration](https://corp.map.ir/registration)". If you have API key,
    /// use Publisher/Subscriber initializers with APIKey argument, or add it to your Info.plist
    /// of your bundle.
    case apiKeyNotAvailable

    /// Your Map.ir API key is not authorized.
    ///
    /// If you don't have a valid API key, see "[App Regstration](https://corp.map.ir/registration)"
    /// and get one. Then retry with the new API key.
    case unauthorizedAPIKey

    /// Service is currently running
    ///
    /// You can't start or restart while service is running or starting.
    case serviceCurrentlyRunning

    /// Publisher is not authorized to use location services.
    ///
    /// You must handle location service authorization yourself. Without permission set to "When In Use"
    /// or "Alyaws", publisher can't access and send live location.
    case notAuthorizedForLocationUsage(CLAuthorizationStatus)

    /// Tracking identifier is not available.
    ///
    /// use `start(withTrackingIdentifier:)` before `restart()` method.
    case trackingIdentifierNotAvailable

    /// Map.ir Live Tracker service is not available at the moment.
    ///
    /// In case of happening [contact support](https://corp.map.ir/contact-us/) for more information.
    case liveTrackerServiceNotAvailable


    /// Description of the error.
    var errorDescription: String? {
        switch self {
        case .apiKeyNotAvailable:
            return "Using service requires a valid Map.ir API key. add your API key in Info.plist or use initalizer that accepts token."

        case .unauthorizedAPIKey:
            return "Using service requires a valid Map.ir API key. update your API key to a valid one, then retry."

        case .serviceCurrentlyRunning:
            return "Can't start a publisher while a service is being started or already started."

        case .trackingIdentifierNotAvailable:
            return "Tracking identifier is not available. You must specify it first, using start(withTrackingIdentifier:) instance method."

        case .notAuthorizedForLocationUsage(let current):
            return "Location service permission is required for Publisher. It must be set to \"When In Use\" or \"Always\" but it is \"\(current.description)\"."

        case .liveTrackerServiceNotAvailable:
            return "Map.ir Live Tracker service is not available at the moment. Contact support.\nWebsite: https://corp.map.ir/contact-us/"
        }
    }
}

internal enum InternalError: Error {
    case couldNotCreateTopic

    case unauthorizedToken
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
