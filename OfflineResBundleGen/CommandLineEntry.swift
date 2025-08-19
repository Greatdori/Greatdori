//===---*- Greatdori! -*---------------------------------------------------===//
//
// CommandLineEntry.swift
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

import DoriKit
import Foundation
import ArgumentParser

@main
struct CommandLineEntry: AsyncParsableCommand {
    @Flag
    var locale: LocaleFlag = .all
    @Option(name: .shortAndLong, help: "Output path, should be a directory.", transform: URL.init(fileURLWithPath:))
    var output: URL
    @Option
    var maxConnectionCount: Int = 20
    mutating func run() async throws {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: output.path(percentEncoded: false), isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            print("error: output path is not a directory", to: &stderr)
            Foundation.exit(EXIT_FAILURE)
        }
        
        LimitedTaskQueue.shared = .init(limit: maxConnectionCount)
        
        if locale == .all {
            try await generate(to: output)
        } else {
            print("Generating for \(locale.rawValue.uppercased())...\n")
            let localizedOutput = output.appending(path: locale.rawValue)
            if !FileManager.default.fileExists(atPath: localizedOutput.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: localizedOutput, withIntermediateDirectories: true)
            }
            try await generateLocale(locale.apiLocale, to: localizedOutput)
        }
    }
    
    enum LocaleFlag: String, EnumerableFlag {
        case all
        case jp
        case en
        case tw
        case cn
        case kr
        
        var apiLocale: DoriAPI.Locale {
            switch self {
            case .en: .en
            case .tw: .tw
            case .cn: .cn
            case .kr: .kr
            default: .jp
            }
        }
    }
}
