//===---*- Greatdori! -*---------------------------------------------------===//
//
// Generation.swift
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

func generate(to output: URL) async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    for locale in DoriAPI.Locale.allCases {
        print("Generating for \(locale.rawValue.uppercased())...\n")
        
        let localizedOutput = output.appending(path: locale.rawValue)
        if !FileManager.default.fileExists(atPath: localizedOutput.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: localizedOutput, withIntermediateDirectories: true)
        }
        
        try await generateLocale(locale, to: localizedOutput, startTime: startTime)
    }
}

func generateLocale(_ locale: DoriAPI.Locale, to output: URL, startTime: TimeInterval = CFAbsoluteTimeGetCurrent()) async throws {
    let info = await retryUntilNonNil { await DoriAPI.Asset.info(in: locale) }
    var finishedCount = 0
    try await generateFromInfo(info, in: locale, to: output, finished: &finishedCount, total: fileCount(of: info), startTime: startTime)
    await LimitedTaskQueue.shared.waitUntilAllFinished()
}

private func generateFromInfo(
    _ info: DoriAPI.Asset.AssetList,
    in locale: DoriAPI.Locale,
    to output: URL,
    finished: inout Int,
    total: Int,
    startTime: TimeInterval,
    _path: String = "/"
) async throws {
    for (name, child) in info {
        switch child {
        case .files:
            let ptrFinished = withUnsafeMutablePointer(to: &finished) { $0 }
            LimitedTaskQueue.shared.addTask {
                var contents: [String]!
                for i in 0..<5 {
                    if let result = await DoriAPI.Asset._contentsOf(_path + name, in: locale) {
                        contents = result
                        break
                    } else if i == 4 {
                        print("\nwarning: Failed to get contents of '\(_path + name)'. Skipping\n")
                        return
                    }
                }
                let fileContainerURL = output.appending(path: "\(name)_rip")
                if !FileManager.default.fileExists(atPath: fileContainerURL.path(percentEncoded: false)) {
                    try! FileManager.default.createDirectory(at: fileContainerURL, withIntermediateDirectories: true)
                }
                for content in contents {
                    let resourceURL = URL(string: "https://bestdori.com/assets/\(locale.rawValue)\(_path + "\(name)_rip")/\(content)")!
                    let fileURL = fileContainerURL.appending(path: content)
                    if _fastPath(!FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false))) {
                        await withTaskGroup { group in
                            group.addTask {
                                for i in 0..<5 { // Retry
                                    if (try? Data(contentsOf: resourceURL).write(to: fileURL)) != nil {
                                        break
                                    } else if i == 4 {
                                        print("\nwarning: Failed to download \(resourceURL.absoluteString). Skipping\n", to: &stderr)
                                    }
                                }
                                DispatchQueue.main.async {
                                    ptrFinished.pointee += 1
                                    printProgressBar(ptrFinished.pointee, total: total, message: "Downloading \(clipPathForPrinting("\(_path)\(name)_rip/\(content)", reserve: 15)) \(formatSeconds(Int(CFAbsoluteTimeGetCurrent() - startTime)))")
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            ptrFinished.pointee += 1
                            printProgressBar(ptrFinished.pointee, total: total, message: "Downloading \(clipPathForPrinting("\(_path)\(name)_rip/\(content)", reserve: 15)) \(formatSeconds(Int(CFAbsoluteTimeGetCurrent() - startTime)))")
                        }
                    }
                }
            }
        case .list(let c):
            let newOutput = output.appending(path: name)
            if !FileManager.default.fileExists(atPath: newOutput.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: newOutput, withIntermediateDirectories: true)
            }
            try await generateFromInfo(c, in: locale, to: newOutput, finished: &finished, total: total, startTime: startTime, _path: _path + "\(name)/")
        }
    }
}

private func fileCount(of info: DoriAPI.Asset.AssetList) -> Int {
    var result = 0
    for (_, child) in info {
        switch child {
        case .files(let count):
            result += count
        case .list(let c):
            result += fileCount(of: c)
        }
    }
    return result
}

private func formatSeconds(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

private func clipPathForPrinting(_ path: String, reserve: Int = 0) -> String {
    let width = terminalWidth()
    if path.count <= width - 10 - reserve {
        return path
    } else {
        var result = path
        while result.count > width - 13 - reserve {
            result.removeLast()
        }
        return result + "..."
    }
}
