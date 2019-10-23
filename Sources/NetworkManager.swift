//
//  NetworkManager.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 1/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

let kNetworkConfigurationUpdatedNotification = Notification.Name("kNetworkConfigurationUpdatedNotification")

public class NetworkingManager {

    public static let shared = NetworkingManager()

    private var _configuration: NetworkConfiguration = .mapirDefault
    public var configuration: NetworkConfiguration {
        get { _configuration }
        set {
            _configuration = newValue
            let notification = Notification(name: kNetworkConfigurationUpdatedNotification)
            NotificationCenter.default.post(notification)
        }
    }

    private init() { }
}

extension NetworkingManager {
    typealias HTTPMethod = String

    func urlRequest(ofHTTPMehod method: HTTPMethod, path: String? = nil, customHeaders: [String: String] = [:], body: Data? = nil) -> URLRequest {

        var urlRequest: URLRequest
        if let path = path {
            urlRequest = URLRequest(url: configuration.apiBaseURL.appendingPathComponent(path))
        } else {
            urlRequest = URLRequest(url: configuration.apiBaseURL)
        }

        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = 5.0

        for pair in customHeaders {
            urlRequest.addValue(pair.value, forHTTPHeaderField: pair.key)
        }

        if method.lowercased() == "body" {
            urlRequest.httpBody = body
        }

        return urlRequest
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionDataTask {
        return configuration.session.dataTask(with: request, completionHandler: completionHandler)
    }
}
