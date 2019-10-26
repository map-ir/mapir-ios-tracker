//
//  NetworkManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 1/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

let kNetworkConfigurationUpdatedNotification = Notification.Name("kNetworkConfigurationUpdatedNotification")

typealias JSONDictionary = [String: String]

/// Object that managers networking related tasks.
@objc(MLTNetworkingManager)
public class NetworkingManager: NSObject {

    /// Shared networking manager.
    @objc(sharedManager)
    public static let shared = NetworkingManager()

    private var _configuration: NetworkConfiguration = .mapirDefault

    /// Configuration for the Networking Manager.
    ///
    /// By default it is set to `NetworkConfiguration.mapirDefault`.
    /// If you want to change the network configuration, you may stop the service first.
    /// Or just change it before instatiating `Publisher` or `Subscriber`.
    @objc(configuration)
    public var configuration: NetworkConfiguration {
        get { _configuration }
        set {
            _configuration = newValue
            let notification = Notification(name: kNetworkConfigurationUpdatedNotification)
            NotificationCenter.default.post(notification)
        }
    }

    private override init() { }
}

extension NetworkingManager {
    typealias HTTPMethod = String

    func urlRequest(ofHTTPMehod method: HTTPMethod, path: String? = nil, customHeaders: [String: String] = [:], body: Data? = nil) -> URLRequest {

        var urlRequest: URLRequest
        if let path = path {
            urlRequest = URLRequest(url: configuration.authenticationServiceURL.appendingPathComponent(path))
        } else {
            urlRequest = URLRequest(url: configuration.authenticationServiceURL)
        }

        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = 5.0

        for pair in customHeaders {
            urlRequest.addValue(pair.value, forHTTPHeaderField: pair.key)
        }

        if method.lowercased() == "post" {
            urlRequest.httpBody = body
        }

        return urlRequest
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTask {
        return configuration.session.dataTask(with: request, completionHandler: completionHandler)
    }
}
