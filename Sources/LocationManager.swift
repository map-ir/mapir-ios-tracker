//
//  LocationManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 15/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    // TODO: Define Location Manger Delegate
    func locationManager(_ locationManager: LocationManager, locationUpdated: CLLocation)
    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error)
}

final class LocationManager: NSObject {

    private var managerType: TrackerType!

    let locationManager = CLLocationManager()
    var distanceFilter: Double {
        get { return locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue }
    }

    var location: CLLocation?

    var delegate: LocationManagerDelegate?

    enum Status {
        case initiated
        case tracking
        case stopped
    }

    var status: LocationManager.Status = .initiated

    init(type: TrackerType) {
        super.init()
        self.managerType = type
        locationManager.distanceFilter = 20
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() throws {
        switch authorizationCheck() {
        case .success(_):
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            status = .tracking
        case .failure(let error):
            throw error
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        status = .stopped
    }

    func authorizationCheck() -> Result<Any, Error> {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            return .success(true)
        case .authorizedWhenInUse:
            if self.managerType == .receiver {
                return .success(true)
            } else {
                fallthrough
            }
        case .notDetermined, .denied, .restricted:
            fallthrough
        @unknown default:
            if managerType == .publisher {
                return .failure(TrackingError.LocationServiceError.unauthorizedForAlwaysUsage)
            } else {
                return .failure(TrackingError.LocationServiceError.unauthorizedForWhenInUseUsage)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        delegate?.locationManager(self, locationUpdated: location)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch authorizationCheck() {
        case .failure(let error):
            self.status = .stopped
            delegate?.locationManager(self, locationUpdatesFailWithError: error)
        default:
            break
        }
    }
}
