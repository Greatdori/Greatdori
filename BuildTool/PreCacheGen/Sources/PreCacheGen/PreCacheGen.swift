//
//  PreCacheGen.swift
//  PreCacheGen
//
//  Created by Mark Chan on 7/31/25.
//

import DoriKit
import Foundation

@main
struct PreCacheGen {
    static func main() async throws {
        // We use stderr for all outputs because logs in Xcode show everything in stderr in real-time but stdout delayed.
        var stderr = StandardError()
        
        guard let outputPath = ProcessInfo.processInfo.environment["CODESIGNING_FOLDER_PATH"] else {
            print("error: CODESIGNING_FOLDER_PATH is unavailable", to: &stderr)
            exit(EXIT_FAILURE)
        }
        guard let targetPlatform = ProcessInfo.processInfo.environment["SWIFT_PLATFORM_TARGET_PREFIX"] else {
            print("error: SWIFT_PLATFORM_TARGET_PREFIX is unavailable", to: &stderr)
            exit(EXIT_FAILURE)
        }
        
        print("Fetching bands...", to: &stderr)
        let bands = await retryUntilNonNil(perform: DoriAPI.Band.all)
        print("Fetching main bands...", to: &stderr)
        let mainBands = await retryUntilNonNil(perform: DoriAPI.Band.main)
        print("Fetching characters...", to: &stderr)
        let characters = await retryUntilNonNil(perform: DoriAPI.Character.all)
        print("Fetching birthday characters...", to: &stderr)
        let birthdayCharacters = await retryUntilNonNil(perform: DoriAPI.Character.allBirthday)
        print("Fetching categorized characters...", to: &stderr)
        let categorizedCharacters = await retryUntilNonNil(perform: DoriFrontend.Character.categorizedCharacters)
        var characterDetails = [Int: DoriAPI.Character.Character]()
        for (index, character) in characters.enumerated() {
            print("Fetching character detail for \(character.characterName.jp ?? "\(character.id)")... [\(index + 1)/\(characters.count)]", to: &stderr)
            let detail = await retryUntilNonNil { await DoriAPI.Character.detail(of: character.id) }
            characterDetails.updateValue(detail, forKey: character.id)
        }
        
        let result = CacheResult(
            bands: bands,
            mainBands: mainBands,
            characters: characters,
            birthdayCharacters: birthdayCharacters,
            categorizedCharacters: categorizedCharacters,
            characterDetails: characterDetails
        )
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(result)
        if targetPlatform.hasPrefix("mac") {
            try data.write(to: URL(filePath: outputPath + "/Resources/PreCache.cache"))
        } else {
            try data.write(to: URL(filePath: outputPath + "/PreCache.cache"))
        }
        
        exit(EXIT_SUCCESS)
    }
}

struct CacheResult: Codable {
    var bands: [DoriAPI.Band.Band]
    var mainBands: [DoriAPI.Band.Band]
    var characters: [DoriAPI.Character.PreviewCharacter]
    var birthdayCharacters: [DoriAPI.Character.BirthdayCharacter]
    var categorizedCharacters: DoriFrontend.Character.CategorizedCharacters
    var characterDetails: [Int: DoriAPI.Character.Character] // [CharacterID: Detail]
}

func retryUntilNonNil<T>(maxRetry: Int = 5, perform: () async -> T?) async -> T {
    for _ in 0..<maxRetry {
        if let result = await perform() {
            return result
        }
    }
    fatalError("Failed to fetch")
}

struct StandardError: TextOutputStream, Sendable {
    private static let handle = FileHandle.standardError
    
    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }
}
