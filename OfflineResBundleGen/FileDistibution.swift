//===---*- Greatdori! -*---------------------------------------------------===//
//
// FileDistibution.swift
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

func updateAssets(in destination: URL, withToken token: String?, lastID givenLastID: Int? = nil) async {
    print("[$][Main] Main starts.")
    guard token != nil else {
        print("[×][Main] Token is `nil`. Aborting.")
        return
    }
    
    var lastID: Int? = nil
    if givenLastID == nil {
        lastID = await readLastID()
    } else {
        lastID = givenLastID
        print("[!][Main] Last ID is given as #\(givenLastID!). Please do not use this regularly.")
    }
    
    if lastID != nil {
        print("[$][Main] Last ID read as #\(lastID!).")
    } else {
        print("[×][Main] Last ID could not be read. Aborting.")
        return
    }
    
    let assetsForUpdate = await searchForAssetUpdate(lastID: lastID!)
    
    guard assetsForUpdate != nil else {
        print("[×][Main] Search result is `nil`.")
        return
    }
    
    for (locale, datas) in assetsForUpdate! {
        await updateLocale(datas: Array(datas), forLocale: locale, to: destination, withToken: token!)
    }
    
    lastID = await updateLastID()
    if lastID != nil {
        print("[$][Main] Last ID updated.")
    } else {
        print("[×][Main] Last ID update failed.")
    }
    
    print("[✓][Main] Process all done.")
}

func updateLocale(datas: [String], forLocale locale: DoriLocale, to destination: URL, withToken token: String) async {
    // I. Initiailzization
    print("[$][Update][\(locale.rawValue)] Update process starts.")
    var groupedDatas: [String: [String]] = [:]
    
    // II. Divide Data in Groups
    for data in datas {
        let branch = analyzePathBranch(data)
        groupedDatas.updateValue((groupedDatas[branch] ?? []) + [data], forKey: branch)
    }
    
    print("[$][Update][\(locale.rawValue)] \(groupedDatas.count) branch(es) requires update.")
    
    // III. Handle Grouped Datas
    for (branch, datas) in groupedDatas {
        do {
            // 0. Initialization
            print("[$][Update][\(locale.rawValue)/\(branch)] Started with \(datas.count) item(s).")
            let startTime = CFAbsoluteTimeGetCurrent()
            var updatedItemsCount = 0
            
            // 1. Pull
            let script = #"""
git config --global --add safe.directory "\#(destination.absoluteString)"
cd "\#(destination.absoluteString)"

git checkout "\#(locale.rawValue)/\#(branch)"

# Retry git pull --rebase up to 10 times
for i in {1..10}; do
  if git pull --rebase; then
    break
  fi
done
"""#
            let (status, output) = try await runBashScript(script, commandName: "Git Pull", viewFailureAsFatalError: false)
            print("[✓][Update][\(locale.rawValue)/\(branch)] Git pulled. Status \(status).")
            
            // 2. Update Files
            LimitedTaskQueue.shared.addTask {
                await withTaskGroup { group in
                    for data in datas {
                        group.addTask {
                            await updateFile(for: data, into: destination, inLocale: locale, onUpdate: { message in
                                updatedItemsCount += 1
                                printProgressBar(
                                    updatedItemsCount,
                                    total: datas.count,
                                    message: "\(message) \(formatSeconds(Int(CFAbsoluteTimeGetCurrent() - startTime)))")
                            })
                        }
                    }
                }
            }
            await LimitedTaskQueue.shared.waitUntilAllFinished()
            
            // 3. Push
            do {
                let script = #"""
git config --global --add safe.directory "\#(destination.absoluteString)"
cd "\#(destination.absoluteString)"

git config user.name "Togawa Sakiko"
git config user.email "sakiko@darock.top"
git remote set-url origin https://x-access-token:\#(token)@github.com/Greatdori/Greatdori-OfflineResBundle.git

git checkout "\#(locale.rawValue)/\#(branch)"

git add .
git commit -m "Auto update \#(locale.rawValue)/\#(branch) ($(date +"%Y-%m-%d"))" || true
for i in {1..10}; do git push && break; done
"""#
                let (status, output) = try await runBashScript(script, commandName: "Git Push", viewFailureAsFatalError: false)
                print("[✓][Update][\(locale.rawValue)/\(branch)] Git pushed. Status \(status).")
            } catch {
                print("[×][Update][\(locale.rawValue)/\(branch)] Git push failed. Error: \(error).")
            }
        } catch {
            print("[×][Update][\(locale.rawValue)/\(branch)] Git pull failed. Error: \(error).")
        }
    }
    print("[$][Update][\(locale.rawValue)] Update process ended.")
}


func updateFile(for inputtedPath: String, into destination: URL, inLocale locale: DoriLocale, onUpdate: @escaping (String) -> Void) async {
    let path = inputtedPath.hasPrefix("/") ? inputtedPath : "/\(inputtedPath)"
    
    let contents = await DoriAPI.Asset._contentsOf(path, in: locale)
    if let contents {
        let fileContainerURL = destination.appending(path: "\(locale.rawValue)\(path)_rip")
        if !FileManager.default.fileExists(atPath: fileContainerURL.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: fileContainerURL, withIntermediateDirectories: true)
        }
        
        for content in contents {
            let resourceURL = URL(string: "https://bestdori.com/assets/\(locale.rawValue)\(path)_rip/\(content)")!
            let fileURL = fileContainerURL.appending(path: content)
            for i in 0..<5 { // Retry
                if (try? Data(contentsOf: resourceURL).write(to: fileURL)) != nil {
                    break
                } else if i == 4 {
                    print("[!][Update][\(locale.rawValue)] Failed to download \(resourceURL.absoluteString). Skipping.")
                }
            }
        }
        onUpdate(clipPathForPrinting("\(path)_rip", reserve: 15))
    } else {
        print("[?!!][UNEXPECTED ISSUE][Update][\(locale.rawValue)] Failed reading contents of path \"\(path)\". This is unexpected. Skipping.")
    }
}
