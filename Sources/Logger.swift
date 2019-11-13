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
@objc(MLTLogger)
public class Logger: NSObject {

    private var _level: Level

    /// Default logger instance.
    internal static let `default` = Logger()

    /// Indicates logging level.
    @objc
    public static var level: Level {
        get {
            return Logger.default._level
        }
        set {
            Logger.default._level = newValue
        }
    }

    private init(level: Level? = nil) {
        if let level = level {
            self._level = level
        } else {
            self._level = .none
        }
        super.init()
    }

    private var timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        return timeFormatter
    }()

    internal func log(_ message: [Any], level: Level, separator: String = " ", terminator: String = "\n") {
        if level.rawValue >= self._level.rawValue {
            let message = message.map { "\($0)" }.joined(separator: separator)
            print("LiveTracker - \(level.description) - \(self.timeFormatter.string(from: Date())): \(message)", terminator: terminator)
        }
    }
}

extension Logger {

    /// Shows different logging levels.
    @objc(MLTLoggerLevel)
    public enum Level: Int, CustomStringConvertible {

        /// All debug, info and errors will be shown.
        case debug = 0

        /// All info and errors will be shown.
        case info = 1

        /// Only errors will be printed at this level.
        case error = 2

        /// No logs will be shown at this level.
        case none = 3

        /// Logger level description.
        public var description: String {
            switch self {
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .error:
                return "ERROR"
            case .none:
                return "NONE"
            }
        }
    }
}
