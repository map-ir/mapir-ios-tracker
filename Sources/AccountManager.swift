//
//  AccountManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 23/7/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public final class AccountManager {

    var accessToken: String?
    var username: String?
    var password: String?

    var topics: [String: String] = [:]

    init(accessToken: String) {
        self.accessToken = accessToken
    }

    init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPIRAccessToken") as? String {
            self.accessToken = token
        }
    }

    let deviceIdentifier: UUID = {
        #if os(iOS) || os(watchOS) || os(tvOS)
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid
        }
        #endif
        return UUID()
    }()

    var isAuthenticated: Bool {
        if let token = accessToken, !token.isEmpty {
            return true
        } else {
            return false
        }
    }

    func topic(forTrackingIdentifier trackingID: String) -> String? {
        if let topic = topics[trackingID] {
            return topic
        } else {
            createNewTopic(forTrackingIdentifier: trackingID)
            return nil
        }
    }

    func createNewTopic(forTrackingIdentifier trackingID: String) {

    }

}
