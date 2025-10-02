//===---*- Greatdori! -*---------------------------------------------------===//
//
// ReflectionView.swift
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

import SwiftUI
import DoriKit
import ShazamKit
import SDWebImageSwiftUI
import UniformTypeIdentifiers

struct ReflectionView: View {
    @Environment(\.openURL) var openURL
    @State var singleMusicIDInput = ""
    @State var singleMatchResults: [SHMatchedMediaItem]?
    @State var batchMatchResults: [PreviewSong: Result<[SHMatchedMediaItem], any Error>] = [:]
    @State var batchResultFile: PropertyListFileDocument?
    @State var isBatchResultExporterPresented = false
    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Music ID", text: $singleMusicIDInput)
                    Button("Generate") {
                        guard let musicID = Int(singleMusicIDInput) else { return }
                        Task {
                            do {
                                singleMatchResults = try await matchMediaItems(for: musicID)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
                if let results = singleMatchResults {
                    ForEach(results) { result in
                        mediaItemPreview(result)
                    }
                }
            } header: {
                Text("Single")
            }
            Section {
                HStack {
                    Button("Get All") {
                        batchMatchResults.removeAll()
                        Task {
                            await matchAllMediaItems { song, result in
                                batchMatchResults.updateValue(result, forKey: song)
                            }
                        }
                    }
                    Spacer()
                    Button("Export...") {
                        let encoder = PropertyListEncoder()
                        let codableResult = batchMatchResults.mapValues { CodableMatchResult($0) }
                        if let data = try? encoder.encode(codableResult) {
                            batchResultFile = .init(data)
                            isBatchResultExporterPresented = true
                        }
                    }
                    Text(String(batchMatchResults.count))
                }
                if !batchMatchResults.isEmpty {
                    ForEach(batchMatchResults.keys.sorted(by: { $0.id > $1.id })) { key in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(key.musicTitle.forPreferredLocale() ?? "No title")
                                Text(verbatim: "#\(key.id)")
                                    .foregroundStyle(.gray)
                            }
                            switch batchMatchResults[key]! {
                            case .success(let items):
                                ForEach(items) { item in
                                    mediaItemPreview(item)
                                }
                            case .failure(let error):
                                Text(error.localizedDescription)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            } header: {
                Text("Batch")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("Reflection")
        .fileExporter(isPresented: $isBatchResultExporterPresented, document: batchResultFile, contentType: .propertyList, defaultFilename: "") { _ in
            batchResultFile = nil
        }
    }
    
    @ViewBuilder
    func mediaItemPreview(_ item: SHMatchedMediaItem) -> some View {
        HStack {
            WebImage(url: item.artworkURL) { image in
                image
            } placeholder: {
                Rectangle()
                    .fill(Color.gray)
            }
            .resizable()
            .cornerRadius(12)
            .scaledToFit()
            .frame(width: 100, height: 100)
            VStack(alignment: .leading) {
                Text(item.title ?? "No title")
                    .font(.title3)
                Text(item.artist ?? "No artist")
                    .font(.body)
                    .foregroundStyle(.gray)
                Text("\(unsafe String(format: "%.2f", item.confidence * 100))%")
            }
            Spacer()
            if let url = item.appleMusicURL {
                Button(action: {
                    openURL(url)
                }, label: {
                    HStack {
                        Image(_internalSystemName: "music")
                        Text("Open in Apple Music")
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .foregroundStyle(.white)
                    .padding(5)
                    .padding(.horizontal, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 230 / 255, green: 63 / 255, blue: 69 / 255))
                    }
                })
                .buttonStyle(.borderless)
            }
        }
    }
}

private func matchMediaItems(for id: Int) async throws -> [SHMatchedMediaItem] {
    guard let song = await Song(id: id) else {
        throw CocoaError(.fileReadUnknown)
    }
    let url = song.soundURL
    return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue(label: "com.memz233.Greatdori.GreatLyrics.Download-Song-For-Reflection-\(song.id)", qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else {
                continuation.resume(
                    throwing: CocoaError(
                        .fileReadUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to download song from \(url.absoluteString)"]
                    )
                )
                return
            }
            let destination = URL(filePath: NSHomeDirectory() + "/tmp/\(url.lastPathComponent)")
            guard (try? data.write(to: destination)) != nil else {
                continuation.resume(throwing: CocoaError(.fileReadCorruptFile))
                return
            }
            SHSignatureGenerator.generateSignature(from: AVURLAsset(url: destination)) { signature, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                Task {
                    guard let signature = try? await signature?.slices(from: 1, duration: 12).first(where: { _ in true }) else {
                        continuation.resume(throwing: CocoaError(.coderValueNotFound))
                        return
                    }
                    let session = SHSession()
                    let result = await session.result(from: signature)
                    switch result {
                    case .match(let match):
                        continuation.resume(returning: match.mediaItems)
                    case .noMatch(_):
                        continuation.resume(returning: [])
                    case .error(let error, _):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

private func matchAllMediaItems(
    eachCompletion: @Sendable @escaping (PreviewSong, Result<[SHMatchedMediaItem], any Error>) -> Void
) async {
    guard let songs = await Song.all() else { return }
    await withTaskGroup { group in
        var counter = 0
        for song in songs {
            group.addTask(priority: .userInitiated) {
                let _result: Result<[SHMatchedMediaItem], any Error>
                do {
                    let items = try await matchMediaItems(for: song.id)
                    _result = .success(items)
                } catch {
                    _result = .failure(error)
                }
                eachCompletion(song, _result)
                return (song, _result)
            }
            if counter >= 20 {
                await group.waitForAll()
                counter = 0
            }
            counter += 1
        }
    }
}

// [PreviewSong: Result<[SHMatchedMediaItem], any Error>]
private enum CodableMatchResult: Codable {
    case some([CodableMatchItem])
    case none(String)
    
    init(_ result: Result<[SHMatchedMediaItem], any Error>) {
        self = switch result {
        case .success(let items): .some(items.map { .init($0) })
        case .failure(let error): .none(error.localizedDescription)
        }
    }
    
    struct CodableMatchItem: Codable {
        var confidence: Float
        var matchOffset: TimeInterval
        var predictedCurrentMatchOffset: TimeInterval
        var frequencySkew: Float
        var timeRanges: [Range<TimeInterval>]
        var frequencySkewRanges: [Range<Float>]
        var title: String?
        var subtitle: String?
        var artist: String?
        var artworkURL: URL?
        var videoURL: URL?
        var genres: [String]
        var explicitContent: Bool
        var creationDate: Date?
        var isrc: String?
        var id: UUID
        var appleMusicURL: URL?
        var appleMusicID: String?
        var webURL: URL?
        var shazamID: String?
        
        init(_ item: SHMatchedMediaItem) {
            self.confidence = item.confidence
            self.matchOffset = item.matchOffset
            self.predictedCurrentMatchOffset = item.predictedCurrentMatchOffset
            self.frequencySkew = item.frequencySkew
            self.timeRanges = item.timeRanges
            self.frequencySkewRanges = item.frequencySkewRanges
            self.title = item.title
            self.subtitle = item.subtitle
            self.artist = item.artist
            self.artworkURL = item.artworkURL
            self.videoURL = item.videoURL
            self.genres = item.genres
            self.explicitContent = item.explicitContent
            self.creationDate = item.creationDate
            self.isrc = item.isrc
            self.id = item.id
            self.appleMusicURL = item.appleMusicURL
            self.appleMusicID = item.appleMusicID
            self.webURL = item.webURL
            self.shazamID = item.shazamID
        }
    }
}

struct PropertyListFileDocument: FileDocument {
    static let readableContentTypes = [UTType.propertyList]
    
    var data: Data
    
    init(_ data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.coderReadCorrupt)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
