//
//  LocationManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 15/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate: class {
    func locationManager(_ locationManager: LocationManager, locationUpdated location: CLLocation)
    func locationManager(_ locationManager: LocationManager, locationUpdatesFailWithError error: Error)
}

final class LocationManager: NSObject {

    let locationManager = CLLocationManager()
    var distanceFilter: Double {
        get { return locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue }
    }

    var location: CLLocation?

    weak var delegate: LocationManagerDelegate?

    enum Status {
        case initiated
        case tracking
        case stopped
    }

    var status: LocationManager.Status = .initiated

    override init() {
        super.init()
        locationManager.distanceFilter = 20
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() throws {
        if let authError = authorizationCheck() {
            status = .stopped
            throw authError
        } else {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            status = .tracking
        }
    }

    /// Stops Location Manager if it is tracking.
    func stopTracking() {
        if status == .tracking {
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
            status = .stopped
        }
    }

    func authorizationCheck() -> Error? {
        let auth = CLLocationManager.authorizationStatus()
        switch auth {
        case .authorizedAlways, .authorizedWhenInUse:
            return nil
        case .notDetermined, .denied, .restricted:
            fallthrough
        @unknown default:
            return LiveTrackerError.notAuthorizedForLocationUsage(auth)
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
        if let authError = authorizationCheck() {
            self.status = .stopped
            delegate?.locationManager(self, locationUpdatesFailWithError: authError)
        }
    }
}
