//
//  Logger.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 29/7/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

func logDebug(_ message: String) {
    Logger.default.log(message, level: .debug)
}

func logInfo(_ message: String) {
    Logger.default.log(message, level: .info)
}

func logError(_ message: String) {
    Logger.default.log(message, level: .error)
}

struct Logger {
    var level: Level

    static let `default` = Logger(level: .debug)

    private init(level: Level) {
        self.level = level
    }

    private var timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        return timeFormatter
    }()

    func log(_ message: String, level: Level) {
        if level.rawValue >= self.level.rawValue {
            print("LiveTracker - \(level.description) - \(self.timeFormatter.string(from: Date())): \(message)")
        }
    }
}


extension Logger {
    enum Level: Int, CustomStringConvertible {
        case none = 0, info, debug, error

        var description: String {
            switch self {
            case .none:
                return "NONE"
            case .info:
                return "INFO"
            case .debug:
                return "DEBUG"
            case .error:
                return "ERROR"
            }
        }
    }
}
