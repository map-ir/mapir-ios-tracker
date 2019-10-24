//
//  NetworkUtilities.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CocoaMQTT

public class NetworkConfiguration {

    public let apiBaseURL: URL
    public let maximumNetworkRetries: Int

    public let brokerAddress: String
    public let brokerPort: UInt16
    public let qos: CocoaMQTTQOS
    public let usesSSL: Bool

    public let session: URLSession

    public static let mapirDefault = NetworkConfiguration(serverURL: URL(string: "https://tracking-dev.map.ir/")!,
                                                          maximumRetries: 3,
                                                          brokerAddress: "dev.map.ir",
                                                          port: 1883,
                                                          qos: .qos0,
                                                          usesSSL: false,
                                                          session: .shared)

    public init(serverURL: URL, maximumRetries: Int, brokerAddress: String, port: UInt16, qos: CocoaMQTTQOS, usesSSL: Bool, session: URLSession) {
        self.apiBaseURL = serverURL
        self.brokerAddress = brokerAddress
        self.brokerPort = port
        self.maximumNetworkRetries = 3
        self.qos = qos
        self.usesSSL = usesSSL
        self.session = session
    }

    let userAgent: String = {
        var components: [String] = []

        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as?String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            components.append("\(appName)/\(version)")
        }

        // Replace Your bundle name
        let libraryBundle: Bundle? = Bundle(for: NetworkConfiguration.self)

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
