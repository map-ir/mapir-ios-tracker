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
typealias SubscribeCompletionHandler =  () -> Void

protocol MQTTClientDelegate {
    func mqttClient(_ mqttClient: MQTTClient, disconnectedWithError error: Error?)
    func mqttClient(_ mqttClient: MQTTClient, publishedData data: Data)
    func mqttClient(_ mqttClient: MQTTClient, receivedData data: Data)
    // func mqttClientConnected(_ mqttClient: MQTTClient)
}

final class MQTTClient {
    var username: String? {
        get { return client.username }
        set { client.username = newValue }
    }
    var password: String? {
        get { return client.password }
        set { client.password = newValue }
    }

    var status: CocoaMQTTConnState {
        return client.connState
    }

    var topic: String?

    private let client: CocoaMQTT!
    var defaultHost = "81.91.152.2"
    var defaultPort: UInt16 = 1883
    var defaultQoS: CocoaMQTTQOS = .qos0

    var delegate: MQTTClientDelegate?

    init() {
        let uuid = UUID()
        client = CocoaMQTT(clientID: uuid.uuidString)
        client.host = defaultHost
        client.port = defaultPort
        client.autoReconnect = false
        client.cleanSession = true
        client.delegate = self
    }

    deinit {
        connectCompletionHandler = nil
        subscribeCompletionHandler = nil
    }

    private var connectCompletionHandler: ConnectCompletionHandler?
    private var subscribeCompletionHandler: SubscribeCompletionHandler?

    func connect(completionHandler: @escaping ConnectCompletionHandler) {
        self.connectCompletionHandler = completionHandler
        _ = client.connect(timeout: 10)
    }

    func disconnect() {
        client.disconnect()
    }

    func publish(data: Data, onTopic topic: String) {
        let payload: [UInt8] = [UInt8](data)
        let message = CocoaMQTTMessage(topic: topic, payload: payload)
        message.qos = defaultQoS
        message.dup = false
        message.retained = true
        client.publish(message)
    }

    func subscribe(toTopic topic: String, completionHandler: SubscribeCompletionHandler?) {
        self.subscribeCompletionHandler = completionHandler
        client.subscribe(topic, qos: defaultQoS)
    }

    func unsubscribe(topic: String) {
        client.unsubscribe(topic)
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
            break
        case .connecting, .initial:
            break
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        let data = Data(message.payload)
        delegate?.mqttClient(self, publishedData: data)
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let data = Data(message.payload)
        delegate?.mqttClient(self, receivedData: data)
        
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        subscribeCompletionHandler?()
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {

    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {

    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {

    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        delegate?.mqttClient(self, disconnectedWithError: err)
    }
}
