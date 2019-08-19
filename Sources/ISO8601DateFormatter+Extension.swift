//
//  ISO8601DateFormatter+Extension.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 27/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    static let `default`: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        if #available(iOSApplicationExtension 11.0, *) {
            formatter.formatOptions = [.withFractionalSeconds, .withTimeZone]
        } else {
            formatter.formatOptions = [.withTimeZone]
        }
        return formatter
    }()
}
