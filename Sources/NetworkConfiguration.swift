//
//  NetworkUtilities.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

public struct NetworkConfiguration {

    public let serverURL: URL
    public let brokerAddress: String
    public let port: UInt16
    public let maximumNetworkRetries: Int
    public let usesSSL: Bool = false

    public let session: URLSession = .shared

    public static let mapirDefault = NetworkConfiguration(serverURL: URL(string: "https://tracking-dev.map.ir/")!,
                                                          brokerAddress: "dev.map.ir",
                                                          port: 1883,
                                                          maximumRetries: 3)

    public init(serverURL: URL, brokerAddress: String, port: UInt16, maximumRetries: Int) {
        self.serverURL = serverURL
        self.brokerAddress = brokerAddress
        self.port = port
        self.maximumNetworkRetries = 3
    }

    let userAgent: String = {
        var components: [String] = []

        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as?String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            components.append("\(appName)/\(version)")
        }

        // Replace Your bundle name
        let libraryBundle: Bundle? = Bundle(for: Publisher.self)

        if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
            components.append("\(libraryName)/\(version)")
        }

        let system: String
        #if os(OSX)
            system = "macOS"
        #elseif os(iOS)
            system = "iOS"
        #elseif os(watchOS)
            system = "watchOS"
        #elseif os(tvOS)
            system = "tvOS"
        #endif
        let systemVersion = ProcessInfo().operatingSystemVersion
        components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")

        let chip: String
        #if arch(x86_64)
            chip = "x86_64"
        #elseif arch(arm)
            chip = "arm"
        #elseif arch(arm64)
            chip = "arm64"
        #elseif arch(i386)
            chip = "i386"
        #endif
        components.append("(\(chip))")

        return components.joined(separator: " ")
    }()
}


struct NewLiveTrackerResponse: Decodable {

    struct Data: Decodable {
        var topic: String
        var username: String
        var password: String
    }

    var data: NewLiveTrackerResponse.Data
    var message: String
}
