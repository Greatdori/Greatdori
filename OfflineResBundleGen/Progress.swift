//===---*- Greatdori! -*---------------------------------------------------===//
//
// Progress.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Foundation

func printProgressBar(_ value: Int, total: Int, message: String? = nil, continousPrint: Bool = false, printInTwoLines: Bool = true) {
    let width = terminalWidth()
    let reservedSpace = 10 + String(value).count + String(total).count
    let barLength = max(10, width - reservedSpace)
    let progress = Double(value) / Double(total)
    let percent = Int(progress * 100)
    let filledLength = Int(progress * Double(barLength))
    let bar = String(repeating: "█", count: filledLength) + String(repeating: "-", count: barLength - filledLength)
    if message != nil && continousPrint {
        if printInTwoLines {
            print("\r\u{1B}[K\u{1B}[1A\u{1B}[K", terminator: "")
        } else {
            print("\r\u{1B}[K", terminator: "")
        }
        fflush(stdout)
    }
    print("\r[\(bar)] \(value)/\(total) \(String(format: "%.2f", progress))%", terminator: "")
    if let message {
        print("\(printInTwoLines ? "\n" : "")\(message)", terminator: "")
    }
    fflush(stdout)
}
func terminalWidth() -> Int {
    var w = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
        return Int(w.ws_col)
    } else {
        return 80
    }
}
