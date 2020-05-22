//
//  NetworkUtilities.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 13/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CocoaMQTT
import UIKit

/// An object that represents a network configuration for the service.
@objc(MLTNetworkConfiguration)
public class NetworkConfiguration: NSObject {

    /// API base URL.
    ///
    /// This url is used to fetch topics for tracking identifier.
    @objc public let authenticationServiceURL: URL

    /// Maximum network retries.
    @objc public let maximumNetworkRetries: Int

    /// MQTT Broker address.
    @objc public let brokerAddress: String

    /// MQTT Broker port.
    @objc public let brokerPort: UInt16

    /// Quality of Service for MQTT packets.
    @objc public let qos: MQTTQoS

    /// Indicates that the configuration uses SSL or not.
    @objc public let sslCertificate: SSLCetrificate?

    /// Shared `URLSession` instance for the service.
    @objc public let session: URLSession

    /// Default Map.ir service configuration.
    ///
    /// - Attention: If you are using live tracking service with Map.ir infrastructre, you have to use this default configurations.
    @objc public static let mapirDefault = NetworkConfiguration(authenticationServiceURL: URL(string: "https://tracking-dev.map.ir/")!,
                                                                maximumRetries: 3,
                                                                brokerAddress: "tracking.map.ir",
                                                                port: 1883,
                                                                qos: .qos0,
                                                                sslCertificate: nil,
                                                                session: .shared)

    /// Default Map.ir service configuration.
    ///
    /// - Attention: If you are using live tracking service with Map.ir infrastructre, you have to use this default configurations.
    @objc static let mapirSSLDefault = NetworkConfiguration(authenticationServiceURL: URL(string: "https://tracking.map.ir/")!,
                                                                   maximumRetries: 3,
                                                                   brokerAddress: "tracking.map.ir",
                                                                   port: 8883,
                                                                   qos: .qos0,
                                                                   sslCertificate: SSLCetrificate(name: "certificate", password: "123456"),
                                                                   session: .shared)

    /// Enum representing QoS in MQTT Packets.
    @objc(MLTMQTTQoS)
    public enum MQTTQoS: UInt {

        /// Quality of Service level 0.
        case qos0 = 0

        /// Quality of Service level 1.
        case qos1 = 1

        /// Quality of Service level 2.
        case qos2 = 2

        var asCocoaMQTTQoS: CocoaMQTTQoS {
            return CocoaMQTTQoS(rawValue: UInt8(self.rawValue))!
        }
    }

    /// Creates a customized network configuration.
    ///
    /// - Parameter authenticationServiceURL: URL to fetch topics for tracking identifier.
    /// - Parameter maximumRetries: Maximum network retries.
    /// - Parameter brokerAddress: MQTT Broker address.
    /// - Parameter port: MQTT Broker port.
    /// - Parameter qos: Quality of Service for MQTT packets.
    /// - Parameter usesSSL: Indicates that the configuration uses SSL or not.
    /// - Parameter session: Shared `URLSession` instance for the service.
    ///
    /// If you use Map.ir Live Tracking Service on your own infrastructure,
    /// you can create a custom configuration using this initializer.
    @objc(initWithAuthenticationServiceURL:maximumRetries:brokerAddress:port:qos:sslCertificate:session:)
    public init(authenticationServiceURL: URL, maximumRetries: Int, brokerAddress: String, port: UInt16, qos: MQTTQoS, sslCertificate: SSLCetrificate?, session: URLSession) {
        self.authenticationServiceURL = authenticationServiceURL
        self.brokerAddress = brokerAddress
        self.brokerPort = port
        self.maximumNetworkRetries = 3
        self.qos = qos
        self.sslCertificate = sslCertificate
        self.session = session
    }

    static let userAgent: String = {
        var components: [String] = []

        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as?String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            components.append("\(appName)/\(version)")
        }

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

    static let mapirIdentifier: String = {
        var components: [String] = []

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

        let chip: String
        #if arch(x86_64)
            chip = "x86_64"
        #elseif arch(arm)
            chip = "arm"
        #elseif arch(arm64)
            chip = "arm64"
        #elseif arch(i386)
            chip = "i386"
        #else
            chip = "n/a"
        #endif
        components.append("\(system)\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)(\(chip))")

        let libraryBundle: Bundle? = Bundle(for: NetworkConfiguration.self)

        if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
            components.append("\(libraryName)/\(version)")
        }

        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                components.append("\(appName)/\(version)")
        }

        return components.joined(separator: "-")
    }()

    static let deviceIdentifier: UUID = {
        #if os(iOS) || os(watchOS) || os(tvOS)
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid
        }
        #endif
        return UUID()
    }()
}

extension NetworkConfiguration {

    @objc(MLTSSLCertificate)
    public class SSLCetrificate: NSObject {
        let name: String
        let password: String
        var setting: [String: NSObject] = [:]

        /// Creates SSLCertifiate.
        /// - Parameters:
        ///   - name: Name of the .p12 file.
        ///   - password: password of the .p12 file.
        @objc(initWithName:password:)
        public init(name: String, password: String? = nil) {
            self.name = name
            self.password = password ?? ""
            super.init()
            
            self.readCertificate()
        }

        func readCertificate() {
            guard let clientCertArray = readCertFromP12File(certName: self.name, certPassword: self.password) else {
                return
            }

            var sslSettings: [String: NSObject] = [:]
            sslSettings[kCFStreamSSLCertificates as String] = clientCertArray

            self.setting = sslSettings
        }

        private func readCertFromP12File(certName: String, certPassword: String) -> CFArray? {
            // get p12 file path
            let resourcePath = Bundle.main.path(forResource: certName, ofType: "p12")

            guard let filePath = resourcePath, let p12Data = NSData(contentsOfFile: filePath) else {
                print("Failed to open the certificate file: \(certName).p12")
                return nil
            }

            // create key dictionary for reading p12 file
            let key = kSecImportExportPassphrase as String
            let options : NSDictionary = [key: certPassword]

            var items : CFArray?
            let securityError = SecPKCS12Import(p12Data, options, &items)

            guard securityError == errSecSuccess else {
                if securityError == errSecAuthFailed {
                    print("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
                } else {
                    print("Failed to open the certificate file: \(certName).p12")
                }
                return nil
            }

            guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
                return nil
            }

            let dictionary = (theArray as NSArray).object(at: 0)
            guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
                return nil
            }
            let certArray = [identity] as CFArray

            return certArray
        }
    }
}
