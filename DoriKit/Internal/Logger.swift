//
//  Logger.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

import OSLog
import Foundation

internal let logger = Logger(subsystem: "com.apple.runtime-issues", category: "DoriKit")

extension Logger {
    internal func log<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.log("\(message())")
        return closure()
    }
    
    internal func log<T>(level: OSLogType, _ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.log(level: level, "\(message())")
        return closure()
    }
    
    internal func trace<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.trace("\(message())")
        return closure()
    }
    
    internal func debug<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.debug("\(message())")
        return closure()
    }
    
    internal func info<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.info("\(message())")
        return closure()
    }
    
    internal func notice<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.notice("\(message())")
        return closure()
    }
    
    internal func warning<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.warning("\(message())")
        return closure()
    }
    
    internal func error<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.error("\(message())")
        return closure()
    }
    
    internal func critical<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.critical("\(message())")
        return closure()
    }
    
    internal func fault<T>(_ message: @autoclosure @escaping () -> String, evaluate closure: @autoclosure () -> T) -> T {
        self.fault("\(message())")
        return closure()
    }
}
