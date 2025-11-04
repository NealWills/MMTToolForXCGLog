//
//  MELogManager.swift
//  BlePen
//
//  Created by maxeye on 2024/1/5.
//

import Foundation
import MMTToolForXCGLog

let documentsDirectory: URL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.endIndex - 1]
}()


let logTestOneMinites: XCGLogger = { // see bug report: rdar://49294916 or https://openradar.appspot.com/radar?id=4952305786945536
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "MeatmeetBleOtaLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "MeatmeetBleOtaLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logDirectory: URL = documentsDirectory.appendingPathComponent("Log/.BleOtaLog")
    if !FileManager.default.fileExists(atPath: logDirectory.path) {
        do {
            try FileManager.default.createDirectory(atPath: logDirectory.path, withIntermediateDirectories: true, attributes: nil)
            log.debug("成功创建目录 \(logDirectory)")
        } catch {
            log.debug("无法创建目录： \(logDirectory)_\(error.localizedDescription)")
        }
    }
//    let dateFormatter = DateFormatter()
//    dateFormatter.timeZone = TimeZone.autoupdatingCurrent
//    dateFormatter.dateFormat = "yyyy_MM_dd"
//    let day = dateFormatter.string(from: Date())
    let logPath = logDirectory.appendingPathComponent("meatmeet_ble_ota_log")
    let logArchiveDir: URL = logDirectory.appendingPathComponent("archive")
    let autoRotatingFileDestination = AutoRotatingFileDestination(
        writeToFile: logPath,
        identifier: "MeatmeetBleOtaLogger.fileDestination",
        shouldAppend: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
        maxFileSize: 1024 * 102, // 100k
        maxTimeInterval: 60 * 60 * 10, // 10h
        targetMaxLogFiles: 10000
    ) // Default is 10, max is 255

    // Optionally set some configuration options
    autoRotatingFileDestination.archiveFolderURL = logArchiveDir
    autoRotatingFileDestination.outputLevel = .info
    autoRotatingFileDestination.showLogIdentifier = false
    autoRotatingFileDestination.showFunctionName = true
    autoRotatingFileDestination.showThreadName = true
    autoRotatingFileDestination.showLevel = true
    autoRotatingFileDestination.showFileName = true
    autoRotatingFileDestination.showLineNumber = true
    autoRotatingFileDestination.showDate = true

    // Process this destination in the background
    autoRotatingFileDestination.logQueue = XCGLogger.logQueue
    
    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    let ansiColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
    autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: autoRotatingFileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.notice] = "✳️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    //    log.levelDescriptions[.alert] = "🛑"
    //    log.levelDescriptions[.emergency] = "🚨"

    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
//    let emojiLogFormatter = PrePostFixLogFormatter()
//    emojiLogFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
//    emojiLogFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
//    emojiLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
//    emojiLogFormatter.apply(prefix: "✳️✳️✳️ ", postfix: " ✳️✳️✳️", to: .notice)
//    emojiLogFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
//    emojiLogFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
//    emojiLogFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
//    emojiLogFormatter.apply(prefix: "🛑🛑🛑 ", postfix: " 🛑🛑🛑", to: .alert)
//    emojiLogFormatter.apply(prefix: "🚨🚨🚨 ", postfix: " 🚨🚨🚨", to: .emergency)
//    log.formatters = [emojiLogFormatter]

    let customLogFormatter = MECustomLogFormatter()
    log.formatters = [customLogFormatter]
    
    autoRotatingFileDestination.rotateFile()
    
    return log
}()


let bleLog: XCGLogger = { // see bug report: rdar://49294916 or https://openradar.appspot.com/radar?id=4952305786945536
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "MeatmeetBleLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "MeatmeetBleLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logDirectory: URL = documentsDirectory.appendingPathComponent("Log/.BleLog")
    if !FileManager.default.fileExists(atPath: logDirectory.path) {
        do {
            try FileManager.default.createDirectory(atPath: logDirectory.path, withIntermediateDirectories: true, attributes: nil)
            log.debug("成功创建目录 \(logDirectory)")
        } catch {
            log.debug("无法创建目录： \(logDirectory)_\(error.localizedDescription)")
        }
    }
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.autoupdatingCurrent
    dateFormatter.dateFormat = "yyyy_MM_dd"
    let day = dateFormatter.string(from: Date())
    let logPath = logDirectory.appendingPathComponent("meatmeet_ble_log_" + day)
    let autoRotatingFileDestination = AutoRotatingFileDestination(
        writeToFile: logPath,
        identifier: "MeatmeetBleLogger.fileDestination",
        shouldAppend: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
        maxFileSize: 1024 * 1024 * 10, // 10MB
        maxTimeInterval: 60 * 60 * 3, // 3h
        targetMaxLogFiles: 200
    ) // Default is 10, max is 255

    // Optionally set some configuration options
    autoRotatingFileDestination.outputLevel = .info
    autoRotatingFileDestination.showLogIdentifier = false
    autoRotatingFileDestination.showFunctionName = true
    autoRotatingFileDestination.showThreadName = true
    autoRotatingFileDestination.showLevel = true
    autoRotatingFileDestination.showFileName = true
    autoRotatingFileDestination.showLineNumber = true
    autoRotatingFileDestination.showDate = true

    // Process this destination in the background
    autoRotatingFileDestination.logQueue = XCGLogger.logQueue

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    let ansiColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
    autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: autoRotatingFileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.notice] = "✳️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    //    log.levelDescriptions[.alert] = "🛑"
    //    log.levelDescriptions[.emergency] = "🚨"

    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
//    let emojiLogFormatter = PrePostFixLogFormatter()
//    emojiLogFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
//    emojiLogFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
//    emojiLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
//    emojiLogFormatter.apply(prefix: "✳️✳️✳️ ", postfix: " ✳️✳️✳️", to: .notice)
//    emojiLogFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
//    emojiLogFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
//    emojiLogFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
//    emojiLogFormatter.apply(prefix: "🛑🛑🛑 ", postfix: " 🛑🛑🛑", to: .alert)
//    emojiLogFormatter.apply(prefix: "🚨🚨🚨 ", postfix: " 🚨🚨🚨", to: .emergency)
//    log.formatters = [emojiLogFormatter]

    let customLogFormatter = MECustomLogFormatter()
    log.formatters = [customLogFormatter]
    return log
}()

let deviceSearchLog: XCGLogger = { // see bug report: rdar://49294916 or https://openradar.appspot.com/radar?id=4952305786945536
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "MeatmeetBleSearchLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "MeatmeetBleSearchLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logDirectory: URL = documentsDirectory.appendingPathComponent("Log/.DeviceSearchLog")
    if !FileManager.default.fileExists(atPath: logDirectory.path) {
        do {
            try FileManager.default.createDirectory(atPath: logDirectory.path, withIntermediateDirectories: true, attributes: nil)
            log.debug("成功创建目录 \(logDirectory)")
        } catch {
            log.debug("无法创建目录： \(logDirectory)_\(error.localizedDescription)")
        }
    }
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.autoupdatingCurrent
    dateFormatter.dateFormat = "yyyy_MM_dd"
    let day = dateFormatter.string(from: Date())
    let logPath = logDirectory.appendingPathComponent("meatmeet_ble_log_" + day)
    let autoRotatingFileDestination = AutoRotatingFileDestination(
        writeToFile: logPath,
        identifier: "MeatmeetBleSearchLogger.fileDestination",
        shouldAppend: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
        maxFileSize: 1024 * 1024 * 10, // 10MB
        maxTimeInterval: 60 * 60 * 3, // 3h
        targetMaxLogFiles: 200
    ) // Default is 10, max is 255

    // Optionally set some configuration options
    autoRotatingFileDestination.outputLevel = .info
    autoRotatingFileDestination.showLogIdentifier = false
    autoRotatingFileDestination.showFunctionName = true
    autoRotatingFileDestination.showThreadName = true
    autoRotatingFileDestination.showLevel = true
    autoRotatingFileDestination.showFileName = true
    autoRotatingFileDestination.showLineNumber = true
    autoRotatingFileDestination.showDate = true

    // Process this destination in the background
    autoRotatingFileDestination.logQueue = XCGLogger.logQueue

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    let ansiColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
    autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: autoRotatingFileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.notice] = "✳️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    //    log.levelDescriptions[.alert] = "🛑"
    //    log.levelDescriptions[.emergency] = "🚨"

    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
//    let emojiLogFormatter = PrePostFixLogFormatter()
//    emojiLogFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
//    emojiLogFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
//    emojiLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
//    emojiLogFormatter.apply(prefix: "✳️✳️✳️ ", postfix: " ✳️✳️✳️", to: .notice)
//    emojiLogFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
//    emojiLogFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
//    emojiLogFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
//    emojiLogFormatter.apply(prefix: "🛑🛑🛑 ", postfix: " 🛑🛑🛑", to: .alert)
//    emojiLogFormatter.apply(prefix: "🚨🚨🚨 ", postfix: " 🚨🚨🚨", to: .emergency)
//    log.formatters = [emojiLogFormatter]

    let customLogFormatter = MECustomLogFormatter()
    log.formatters = [customLogFormatter]
    return log
}()

let log: XCGLogger = { // see bug report: rdar://49294916 or https://openradar.appspot.com/radar?id=4952305786945536
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "MeatmeetLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "MeatmeetLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logDirectory: URL = documentsDirectory.appendingPathComponent("Log")
    if !FileManager.default.fileExists(atPath: logDirectory.path) {
        do {
            try FileManager.default.createDirectory(atPath: logDirectory.path, withIntermediateDirectories: true, attributes: nil)
            log.debug("成功创建目录 \(logDirectory)")
        } catch {
            log.debug("无法创建目录： \(logDirectory)_\(error.localizedDescription)")
        }
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.autoupdatingCurrent
    dateFormatter.dateFormat = "yyyy_MM_dd"
    let day = dateFormatter.string(from: Date())
    let logPath = logDirectory.appendingPathComponent("meatmeet_log_" + day)
    let autoRotatingFileDestination = AutoRotatingFileDestination(
        writeToFile: logPath,
        identifier: "MeatmeetLogger.fileDestination",
        shouldAppend: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
        maxFileSize: 1024 * 1024 * 10, // 10MB
        maxTimeInterval: 60 * 60 * 3, // 3h
        targetMaxLogFiles: 200
    ) // Default is 10, max is 255

    // Optionally set some configuration options
    autoRotatingFileDestination.outputLevel = .info
    autoRotatingFileDestination.showLogIdentifier = false
    autoRotatingFileDestination.showFunctionName = true
    autoRotatingFileDestination.showThreadName = true
    autoRotatingFileDestination.showLevel = true
    autoRotatingFileDestination.showFileName = true
    autoRotatingFileDestination.showLineNumber = true
    autoRotatingFileDestination.showDate = true

    // Process this destination in the background
    autoRotatingFileDestination.logQueue = XCGLogger.logQueue

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    let ansiColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
    autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: autoRotatingFileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.notice] = "✳️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    //    log.levelDescriptions[.alert] = "🛑"
    //    log.levelDescriptions[.emergency] = "🚨"

    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
//    let emojiLogFormatter = PrePostFixLogFormatter()
//    emojiLogFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
//    emojiLogFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
//    emojiLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
//    emojiLogFormatter.apply(prefix: "✳️✳️✳️ ", postfix: " ✳️✳️✳️", to: .notice)
//    emojiLogFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
//    emojiLogFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
//    emojiLogFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
//    emojiLogFormatter.apply(prefix: "🛑🛑🛑 ", postfix: " 🛑🛑🛑", to: .alert)
//    emojiLogFormatter.apply(prefix: "🚨🚨🚨 ", postfix: " 🚨🚨🚨", to: .emergency)
//    log.formatters = [emojiLogFormatter]

    let customLogFormatter = MECustomLogFormatter()
    log.formatters = [customLogFormatter]
    return log
}()

class MECustomLogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {
    // 实现 CustomDebugStringConvertible 协议的 debugDescription 属性
    var debugDescription: String {
        return "<CustomLogFormatter>"
    }

    func format(logDetails: inout LogDetails, message: inout String) -> String {
        if let tag = logDetails.userInfo["com.cerebralgardens.xcglogger.tags"] as? String, let dev = logDetails.userInfo["com.cerebralgardens.xcglogger.devs"] as? String {
            message = "[\(tag)] [\(dev)] \(message)"
        }
        return message
    }
}

// Create custom tags for your logs
extension Tag {
    static let ble = Tag("ble")
    static let note = Tag("note")
    static let mine = Tag("mine")
    static let icloud = Tag("icloud")
}

// Create custom developers for your logs
extension Dev {
    static let limy = Dev("limy")
    static let chzf = Dev("chzf")
    static let donghn = Dev("donghn")
}
