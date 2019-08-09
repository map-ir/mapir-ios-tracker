//
//  MapirLiveTrackerReceiver.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 18/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

protocol ReceiverDelegate {

}

final class MapirLiveTrackerReceiver {
    public var accessToken: String?
    var topic: String?

    public var trackingIdentifier: String?

    private var mqttClient = MQTTClient()

    var delegate: ReceiverDelegate?

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
}
