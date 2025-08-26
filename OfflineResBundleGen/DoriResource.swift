//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriResource.swift
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
//
// Code in this file generates files for DoriResource.bundle
//
//===----------------------------------------------------------------------===//

import DoriKit
import Foundation

private let resourceInterpolation: [AnyHashable: String] = [
    DoriAPI.Locale.allCases.map { $0.rawValue }: "https://bestdori.com/res/icon/%s.svg",
    DoriAPI.Attribute.allCases.map { $0.rawValue }: "https://bestdori.com/res/icon/%s.svg",
    1...40: "https://bestdori.com/res/icon/chara_icon_%s.png",
    [1, 2, 3, 4, 5, 18, 21, 45]: "https://bestdori.com/res/icon/band_%s.svg"
]

func generateDoriResource(to output: URL) async throws {
    print("Fetching resources...")
    
    let resOutput = output.appending(path: "res")
    if !FileManager.default.fileExists(atPath: resOutput.path(percentEncoded: false)) {
        try FileManager.default.createDirectory(at: resOutput, withIntermediateDirectories: true)
    }
    
    var finishedCount = 0
    var totalCount = 0
    for (key, value) in resourceInterpolation {
        let collection = key.base as! any Collection
        for element in collection {
            DispatchQueue.main.async {
                totalCount += 1
            }
            LimitedTaskQueue.shared.addTask {
                let remoteURL = URL(string: value.replacing("%s", with: "\(element)"))!
                let outputFileURL = output.appending(path: remoteURL.absoluteString.dropFirst("https://bestdori.com/".count))
                let outputParentDirectoryURL = outputFileURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: outputParentDirectoryURL.path(percentEncoded: false)) {
                    try! FileManager.default.createDirectory(at: outputParentDirectoryURL, withIntermediateDirectories: true)
                }
                for i in 0..<5 {
                    if (try? Data(contentsOf: remoteURL).write(to: outputFileURL)) != nil {
                        break
                    } else if i == 4 {
                        print("\nwarning: failed to fetch '\(remoteURL)'. Skipping")
                    }
                }
                DispatchQueue.main.async {
                    finishedCount += 1
                    printProgressBar(finishedCount, total: totalCount)
                }
            }
        }
    }
    
    await LimitedTaskQueue.shared.waitUntilAllFinished()
}

