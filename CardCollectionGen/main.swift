//
//  main.swift
//  CardCollectionGen
//
//  Created by Mark Chan on 8/7/25.
//

import Darwin
import AppKit
import DoriKit
import Foundation

print("""
Localization Key for Collection Name
Example: BUILTIN_CARD_COLLECTION_MYGO
""")
print("> ", terminator: .init())
let collectionNameKey = readLine()!
print("")

print("""
Comma Separated Card ID with Training Status
[ID1]:[before|after], [ID2]:[before|after]...
Example: 2125:before, 1954:after
""")
print("> ", terminator: .init())
let formattedCardInfoString = readLine()!
print("")

print("""
Output Path
Default: ~/Desktop/CardCollections.plist
""")
print("> ", terminator: .init())
let _outputPath = readLine() ?? ""
let outputPath = _outputPath.isEmpty ? "~/Desktop/CardCollections.plist" : _outputPath
print("")

print("Fetching...")

let ids = formattedCardInfoString
    .replacingOccurrences(of: " ", with: "")
    .components(separatedBy: ",")
    .compactMap {
        if let direct = Int($0) {
            // "2125"
            return (id: direct, trained: false)
        } else if $0.contains(":") {
            // "1954:after"
            let separated = $0.components(separatedBy: ":")
            guard separated.count == 2 else { return nil }
            guard let id = Int(separated[0]) else { return nil }
            return (id: id, trained: separated[1] == "after")
        } else {
            return nil
        }
    }
print("Please wait...", terminator: .init())
fflush(stdout)
if let cards = await DoriAPI.Card.all() {
    let relatedCards = cards.compactMap { card in
        if ids.map({ $0.id }).contains(card.id) {
            (card: card, trained: ids.first(where: { $0.id == card.id })!.trained)
        } else {
            nil
        }
    }
    printProgressBar(0, total: relatedCards.count)
    var resultCards = [Card]()
    for (index, (card, trained)) in relatedCards.enumerated() {
        let imageURL = trained ? (card.coverAfterTrainingImageURL ?? card.coverNormalImageURL) : card.coverNormalImageURL
        let data = try Data(contentsOf: imageURL)
        resultCards.append(
            .init(
                name: card.prefix,
                imageData: data
            )
        )
        printProgressBar(index + 1, total: relatedCards.count)
    }
    print("")
    for card in resultCards {
        if NSImage(data: card.imageData) == nil {
            print("error: data integrity check failed: image data of card '\(card.name.forPreferredLocale() ?? "nil")' is invalid")
        }
    }
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let collection = Collection(name: collectionNameKey, cards: resultCards)
    let data = try! encoder.encode(collection)
    try! data.write(to: URL(filePath: outputPath))
    print("Successfully generated card collection file at \(outputPath)")
} else {
    print("Failed to get cards from API")
}

func printProgressBar(_ progress: Int, total: Int) {
    func terminalWidth() -> Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return Int(w.ws_col)
        } else {
            return 80
        }
    }
    
    let width = terminalWidth()
    let reservedSpace = 8
    let barLength = max(10, width - reservedSpace)
    let progress = Double(progress) / Double(total)
    let percent = Int(progress * 100)
    let filledLength = Int(progress * Double(barLength))
    let bar = String(repeating: "█", count: filledLength) + String(repeating: "-", count: barLength - filledLength)
    print("\r[\(bar)] \(percent)%", terminator: "")
    fflush(stdout)
}

struct Collection: Codable {
    var name: String
    var cards: [Card]
}
struct Card: Codable {
    var name: DoriAPI.LocalizedData<String>
    var imageData: Data
}
