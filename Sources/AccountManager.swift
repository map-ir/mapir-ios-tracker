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

let kAccessTokenInfoPlistKey = "MAPIRAccessToken"

let kUpdatedUsernameAndPasswordNotification = Notification.Name("kUpdatedUsernameAndPasswordNotification")

/// Manager for Map.ir account.
public final class AccountManager {

    /// Shared instance for Map.ir account manager.
    public static var shared: AccountManager = AccountManager()

    private var _accessToken: String?

    /// Your Map.ir access token.
    ///
    /// If you use `Publisher`/`Subscriber` initializers that has no accessToken arguments,
    /// account manager searches for `MAPIRAccessToken` key/value pair in your project Info.plist file.
    /// You can't use live tracking services without access token.
    public internal(set) var accessToken: String? {
        get {
            return _accessToken
        }
        set {
            if let newValue = newValue, !newValue.isEmpty {
                _accessToken = newValue
            } else {
                if let token = Bundle.main.object(forInfoDictionaryKey: kAccessTokenInfoPlistKey) as? String {
                    _accessToken = token
                } else {
                    logError("Couldn't find access token in Info.plist. You can't start unless you add your access token using Publisher/Subsciber initializer that has accessToken argument, or Info.plist.")
                }
            }
        }
    }

    internal private(set) var username: String?
    internal private(set) var password: String?

    private func set(username: String, password: String) {
        if self.username?.lowercased() != username.lowercased() || self.password?.lowercased() != password.lowercased() {
            self.username = username
            self.password = password
            let notification = Notification(name: kUpdatedUsernameAndPasswordNotification)
            NotificationCenter.default.post(notification)
        }
    }

    private var topics: [String: String] = [:]

    private init() { }

    var isAuthenticated: Bool {
        (accessToken ?? "").isEmpty ? false : true
    }

    typealias RequestTopicCompletionHandler = (String?, Error?) -> ()

    func topic(forTrackingIdentifier trackingID: String, type: TrackerType, completionHandler: @escaping RequestTopicCompletionHandler) {
        if let topic = topics[trackingID] {
            completionHandler(topic, nil)
        } else {
            createNewTopic(forTrackingIdentifier: trackingID, type: type, completionHandler: completionHandler)
        }
    }

    var activeTopicFetchingTask: URLSessionDataTask? = nil

    func createNewTopic(forTrackingIdentifier trackingID: String, type: TrackerType, completionHandler: @escaping RequestTopicCompletionHandler) {

        if let activeTask = activeTopicFetchingTask, activeTask.state == .running {
            activeTask.cancel()
        }

        guard let accessToken = self.accessToken else {
            logError("Couldn't find Map.ir access token.")
            return
        }

        var headers: [String: String] = [:]
        headers.updateValue(accessToken, forKey: "x-api-key")
        headers.updateValue("application/json", forKey: "Content-Type")

        let bodyDictionary: JSONDictionary = ["type": type.rawValue, "track_id": trackingID, "device_id": NetworkConfiguration.deviceIdentifier.uuidString]

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        guard let encodedBody = try? jsonEncoder.encode(bodyDictionary) else { return }

        let request = NetworkingManager.shared.urlRequest(ofHTTPMehod: "post", customHeaders: headers, body: encodedBody)

        let dataTask = NetworkingManager.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                DispatchQueue.main.async { completionHandler(nil, error) }
                return
            }

            guard let data = data else { return }

            let urlResponse = urlResponse as! HTTPURLResponse
            switch urlResponse.statusCode {
            case 200...201:
                do {
                    struct NewLiveTrackerResponse: Decodable {

                        struct Data: Decodable {
                            var topic: String
                            var username: String
                            var password: String
                        }

                        var data: NewLiveTrackerResponse.Data
                        var message: String
                    }

                    let decodedData = try JSONDecoder().decode(NewLiveTrackerResponse.self, from: data)
                    self.set(username: decodedData.data.username, password: decodedData.data.password)
                    self.topics[trackingID] = decodedData.data.topic
                    DispatchQueue.main.async {
                        completionHandler(decodedData.data.topic, nil)
                    }
                    return
                } catch let decodingError {
                    DispatchQueue.main.async {
                        completionHandler(nil, decodingError)
                    }
                    return
                }
            default:
                DispatchQueue.main.async {
                    completionHandler(nil, InternalError.couldNotCreateTopic)
                }
            }
        }

        self.activeTopicFetchingTask = dataTask
        dataTask.resume()
    }
}
