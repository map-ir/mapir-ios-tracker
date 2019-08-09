//
//  MQTTClient.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 18/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CocoaMQTT

final class MQTTClient {
    private var username: String? {
        get { return client.username }
        set { client.username = newValue }
    }
    private var password: String? {
        get { return client.password }
        set { client.password = newValue }
    }

    private var status: CocoaMQTTConnState {
        return client.connState
    }
    private var topic: String

    private let client: CocoaMQTT!
    var defaultHost = "81.91.152.2"
    var defaultPort: UInt16 = 1883

    init() {
        // TODO: Add UUID
        client = CocoaMQTT(clientID: "")
        client.host = defaultHost
        client.port = defaultPort
        client.cleanSession = true
        client.delegate = self
        _ = client.connect()
        
    }
}

extension MQTTClient: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        <#code#>
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        <#code#>
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        <#code#>
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        <#code#>
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        <#code#>
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        <#code#>
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        <#code#>
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        <#code#>
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        <#code#>
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        <#code#>
    }


}
