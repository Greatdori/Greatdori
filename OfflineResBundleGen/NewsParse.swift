//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsParse.swift
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


//func getLastHandledAssetPatchNoteID() -> Int {
////    FileManager.default.
//}

func getRecentAssetPatchNotes(lastID: Int) async -> [DoriFrontend.News.ListItem]? {
    let allNews = await DoriFrontend.News.list(filter: .patchNote)
    guard allNews != nil else { return nil }
    let assetPatchNotes = allNews!.filter { $0.tags.contains("Asset") }.sorted(by: { $0.relatedID > $1.relatedID })
    return Array(assetPatchNotes.prefix(while: { $0.relatedID > lastID }))
    // If last time's lastest news is #3417, then next time #3417 should not be checked. So use > not >=.
}

func getDatasInAseetPatchNotes(from patchNoteContents: [DoriAPI.News.Item.Content]) -> [String] {
    var result: [String] = []
    
    func traverseSection(_ section: DoriAPI.News.Item.Content.ContentDataSection) {
        switch section {
        case .link(_, let data, _):
            result.append(data)
        case .ul(let arrays):
            for array in arrays {
                for s in array {
                    traverseSection(s)
                }
            }
        default:
            break
        }
    }
    
    func traverseContent(_ content: DoriAPI.News.Item.Content) {
        switch content {
        case .content(let sections):
            for section in sections {
                traverseSection(section)
            }
        default:
            break
        }
    }
    
    for content in patchNoteContents {
        traverseContent(content)
    }
    
    return result
}

func searchForAssetUpdate(lastID: Int) async -> [DoriLocale: Set<String>]? {
    print("[$][Search] Searching starts with lastID #\(lastID).")
    let recentNotes = await getRecentAssetPatchNotes(lastID: lastID)
    if let recentNotes {
        var result: [DoriLocale: Set<String>] = [:]
        
        if recentNotes.count == 0 {
            print("[$][Search] No recent asset patch found with LastID #\(lastID).")
        }
        
        for note in recentNotes {
            let completePassage = await DoriAPI.News.Item(id: note.relatedID)
            if let completePassage {
                let datas = getDatasInAseetPatchNotes(from: completePassage.content)
                if let passageLocale = completePassage.locale {
                    if datas.isEmpty {
                        print("[!][Search] Could not find any updated asset in passage #\(note.relatedID)")
                    }
                    result[passageLocale] = (result[passageLocale] ?? Set()).union(Set(datas))
                } else {
                    print("[?!!][UNEXPECTED ISSUE][Search] Passage #\(note.relatedID) has no locale value. This is unexpected. Skipping.")
                }
            } else {
                print("[!][Search] Found nil while trying to fetch passage #\(note.relatedID).")
            }
        }
        print("[$][Search] Search completed.")
        for locale in DoriLocale.allCases {
            if result[locale] != nil {
                print("[$][Search] \(locale.rawValue.uppercased()) has \(result[locale]!.count) items waiting for update.")
            }
        }
        return result
    } else {
        print("[×][Search] Failed getting recent asset patch note with LastID #\(lastID).")
        return nil
    }
}


