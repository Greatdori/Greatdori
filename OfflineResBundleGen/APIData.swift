//===---*- Greatdori! -*---------------------------------------------------===//
//
// APIData.swift
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
import SwiftyJSON

private let apiListURLs: [URL] = [
    .init(string: "https://bestdori.com/api/bands/main.1.json")!,
    .init(string: "https://bestdori.com/api/bands/all.1.json")!,
    .init(string: "https://bestdori.com/api/cards/all.5.json")!,
    .init(string: "https://bestdori.com/api/characters/all.2.json")!,
    .init(string: "https://bestdori.com/api/characters/main.birthday.json")!,
    .init(string: "https://bestdori.com/api/comics/all.5.json")!,
    .init(string: "https://bestdori.com/api/costumes/all.5.json")!,
    .init(string: "https://bestdori.com/api/degrees/all.3.json")!,
    .init(string: "https://bestdori.com/api/events/all.5.json")!,
    .init(string: "https://bestdori.com/api/tracker/rates.json")!,
    .init(string: "https://bestdori.com/api/events/all.stories.json")!,
    .init(string: "https://bestdori.com/api/gacha/all.5.json")!,
    .init(string: "https://bestdori.com/api/loginCampaigns/all.5.json")!,
    .init(string: "https://bestdori.com/api/skills/all.10.json")!,
    .init(string: "https://bestdori.com/api/songs/all.7.json")!,
    .init(string: "https://bestdori.com/api/songs/meta/all.5.json")!,
    .init(string: "https://bestdori.com/api/miracleTicketExchanges/all.5.json")!,
    .init(string: "https://bestdori.com/api/misc/itemtexts.2.json")!,
    .init(string: "https://bestdori.com/api/misc/mainstories.5.json")!,
    .init(string: "https://bestdori.com/api/misc/bandstories.5.json")!,
    .init(string: "https://bestdori.com/api/misc/afterlivetalks.5.json")!,
    .init(string: "https://bestdori.com/api/misc/areas.1.json")!,
    .init(string: "https://bestdori.com/api/misc/actionsets.5.json")!
]

private let apiInterpolation = [
    "api/cards/all.5.json": "https://bestdori.com/api/cards/%d.json",
    "api/characters/all.2.json": "https://bestdori.com/api/characters/%d.json",
    "api/costumes/all.5.json": "https://bestdori.com/api/costumes/%d.json",
    "api/events/all.5.json": "https://bestdori.com/api/events/%d.json",
    "api/gacha/all.5.json": "https://bestdori.com/api/gacha/%d.json",
    "api/loginCampaigns/all.5.json": "https://bestdori.com/api/loginCampaigns/%d.json",
    "api/songs/all.7.json": "https://bestdori.com/api/songs/%d.json"
]

func generateAPI(to output: URL) async {
    print("Fetching API base lists...")
    await generateAPIBaseLists(to: output)
    print("Fetching API interpolated data...")
    await generateAPIInterpolated(to: output)
}

private func generateAPIBaseLists(to output: URL) async {
    var finishedCount = 0
    for url in apiListURLs {
        LimitedTaskQueue.shared.addTask {
            let baseFilePath = url.absoluteString.dropFirst("https://bestdori.com/".count)
            let outputFileURL = output.appending(path: baseFilePath)
            let outputParentDirectoryURL = outputFileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: outputParentDirectoryURL.path(percentEncoded: false)) {
                try! FileManager.default.createDirectory(at: outputParentDirectoryURL, withIntermediateDirectories: true)
            }
            for i in 0..<5 {
                if (try? Data(contentsOf: url).write(to: outputFileURL)) != nil {
                    break
                } else if i == 4 {
                    print("\nwarning: failed to fetch '\(url)'. Skipping")
                }
            }
            DispatchQueue.main.async {
                finishedCount += 1
                printProgressBar(finishedCount, total: apiListURLs.count)
            }
        }
    }
    await LimitedTaskQueue.shared.waitUntilAllFinished()
    print("")
}

private func generateAPIInterpolated(to output: URL) async {
    var finishedCount = 0
    var totalCount = 0
    for (localBaseFilePath, interpolation) in apiInterpolation {
        let localFileURL = output.appending(path: localBaseFilePath)
        let indexJSON = try! JSON(data: Data(contentsOf: localFileURL))
        for (id, _) in indexJSON {
            DispatchQueue.main.async {
                totalCount += 1
            }
            LimitedTaskQueue.shared.addTask {
                let remoteFileURL = URL(string: interpolation.replacing("%d", with: id))!
                let outputFileURL = output.appending(path: remoteFileURL.absoluteString.dropFirst("https://bestdori.com/".count))
                for i in 0..<5 {
                    if (try? Data(contentsOf: remoteFileURL).write(to: outputFileURL)) != nil {
                        break
                    } else if i == 4 {
                        print("\nwarning: failed to fetch '\(remoteFileURL)'. Skipping")
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
    print("")
}
