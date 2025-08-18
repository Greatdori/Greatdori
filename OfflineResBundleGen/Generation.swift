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
    for locale in DoriAPI.Locale.allCases {
        print("Generating for \(locale.rawValue.uppercased())...")
        
        let localizedOutput = output.appending(path: locale.rawValue)
        if !FileManager.default.fileExists(atPath: localizedOutput.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: localizedOutput, withIntermediateDirectories: true)
        }
        
        try await generateLocale(locale, to: localizedOutput)
    }
}

private func generateLocale(_ locale: DoriAPI.Locale, to output: URL) async throws {
    let info = await retryUntilNonNil { await DoriAPI.Asset.info(in: locale) }
    var finishedCount = 0
    try await generateFromInfo(info, in: locale, to: output, finished: &finishedCount, total: fileCount(of: info))
    await LimitedTaskQueue.shared.waitUntilAllFinished()
}

private func generateFromInfo(
    _ info: DoriAPI.Asset.AssetList,
    in locale: DoriAPI.Locale,
    to output: URL,
    finished: inout Int,
    total: Int,
    _path: String = "/"
) async throws {
    for (name, child) in info {
        switch child {
        case .files:
            let ptrFinished = withUnsafeMutablePointer(to: &finished) { $0 }
            LimitedTaskQueue.shared.addTask {
                let contents = await retryUntilNonNil { await DoriAPI.Asset._contentsOf(_path + name, in: locale) }
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
                                        print("\nwarning: Failed to download \(resourceURL.absoluteString). Skipping.", to: &stderr)
                                    }
                                }
                                DispatchQueue.main.async {
                                    ptrFinished.pointee += 1
                                    printProgressBar(ptrFinished.pointee, total: total)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            ptrFinished.pointee += 1
                            printProgressBar(ptrFinished.pointee, total: total)
                        }
                    }
                }
            }
        case .list(let c):
            let newOutput = output.appending(path: name)
            if !FileManager.default.fileExists(atPath: newOutput.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: newOutput, withIntermediateDirectories: true)
            }
            try await generateFromInfo(c, in: locale, to: newOutput, finished: &finished, total: total, _path: _path + "\(name)/")
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
