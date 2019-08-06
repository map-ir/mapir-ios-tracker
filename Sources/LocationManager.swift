//
//  LocationManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 15/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation

final class LocationManager {
    let locationManager = CLLocationManager()

    enum Status {
        case initiated
        case tracking
        case stopped
    }

    var status: LocationManager.Status = .initiated

    init(distanceFilter: Double) {
        if distanceFilter <= 10 {
            locationManager.distanceFilter = 10
        }
        else {
            locationManager.distanceFilter = distanceFilter
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() throws {
        try authorizationCheck()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        status = .tracking
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        status = .stopped
    }

    func authorizationCheck() throws {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .authorizedWhenInUse, .denied, .restricted:
            throw TrackingError.LocationServiceError.unauthorizedForAlwaysUsage
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        @unknown default:
            break
        }
    }
}
