//
//  Logger.swift
//  MapirLiveTracker-iOS
//
//  Created by Alireza Asadi on 29/7/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

import Foundation

func logDebug(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    Logger.default.log(message, level: .debug, separator: separator, terminator: terminator)
}

func logInfo(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    Logger.default.log(message, level: .info, separator: separator, terminator: terminator)
}

func logError(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    Logger.default.log(message, level: .error, separator: separator, terminator: terminator)
}

/// Logging manager class for SDK.
struct Logger {

    /// Indicates logging level.
    var level: Level

    /// Default logger instance.
    static let `default` = Logger(level: .debug)

    private init(level: Level) {
        self.level = level
    }

    private var timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        return timeFormatter
    }()

    func log(_ message: [Any], level: Level, separator: String = " ", terminator: String = "\n") {
        if level.rawValue >= self.level.rawValue {
            let message = message.map { "\($0)" }.joined(separator: separator)
            print("LiveTracker - \(level.description) - \(self.timeFormatter.string(from: Date())): \(message)", terminator: terminator)
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
