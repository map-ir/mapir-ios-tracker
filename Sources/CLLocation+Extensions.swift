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
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: protoLocation.rtimestamp) {
            self.init(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: course, speed: speed, timestamp: date)

        } else {
            self.init(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: course, speed: speed, timestamp: Date())
        }
    }
}
