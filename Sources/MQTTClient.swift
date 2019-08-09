//
//  MQTTClient.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 18/5/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation
import CocoaMQTT

typealias ConnectCompletionHandler = () -> Void

protocol MQTTClientDelegate {

}

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

    var topic: String?

    private let client: CocoaMQTT!
    var defaultHost = "81.91.152.2"
    var defaultPort: UInt16 = 1883
    var defaultQoS: CocoaMQTTQOS = .qos1

    init() {
        // TODO: Add UUID
        client = CocoaMQTT(clientID: "")
        client.host = defaultHost
        client.port = defaultPort
        client.cleanSession = true
        client.delegate = self
        _ = client.connect()
    }

    private var connectCompletionHandler: ConnectCompletionHandler?

    func connect(completionHandler: @escaping ConnectCompletionHandler) {
        self.connectCompletionHandler = completionHandler
        _ = client.connect(timeout: 10)
    }

    func publish(data: Data, onTopic topic: String) {
        let payload: [UInt8] = [UInt8](data)
        let message = CocoaMQTTMessage(topic: topic, payload: payload)
        message.qos = defaultQoS
        message.dup = false
        message.retained = true
        client.publish(message)
    }
}

extension MQTTClient: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        switch state {
        case .connected:
            if let connectCompletionHandler = connectCompletionHandler {
                connectCompletionHandler()
            }
        case .disconnected:
            // TODO: Tell the delegate that the client disconnected.
            break
        case .connecting, .initial:
            break
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {

    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {

    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {

    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {

    }
}
