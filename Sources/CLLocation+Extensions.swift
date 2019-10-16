//
//  CLLocation+Extensions.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 23/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CoreLocation


internal extension CLLocation {
    convenience init(protoLocation: LiveTracker_Location) {
        let coordinate = CLLocationCoordinate2D(latitude: protoLocation.location[1], longitude: protoLocation.location[0])
        let course = Double(protoLocation.direction)
        let speed = protoLocation.speed
        let epochTimeString = protoLocation.rtimestamp
        guard let epoch = Double(epochTimeString) else {
            preconditionFailure("Timestamp is not in correct format.")
        }
        let date = Date(timeIntervalSince1970: epoch)
        self.init(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: course, speed: speed, timestamp: date)
    }
}
