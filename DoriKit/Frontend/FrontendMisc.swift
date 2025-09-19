//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendMisc.swift
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

extension DoriFrontend {
    /// Other uncatogorized requests in Bandori.
    public enum Misc {
        /// Returns a list of items with related information from given items.
        ///
        /// - Parameter items: A collection of items.
        /// - Returns: Items with related information from given items, nil if failed to fetch.
        public static func extendedItems<T>(
            from items: T
        ) async -> [ExtendedItem]? where T: RandomAccessCollection, T.Element == Item {
            guard let texts = await DoriAPI.Misc.itemTexts() else { return nil }
            
            var result = [ExtendedItem]()
            for item in items {
                var text: DoriAPI.Misc.ItemText?
                switch item.type {
                case .item, .practiceTicket, .liveBoostRecoveryItem, .gachaTicket, .miracleTicket:
                    // These types of items are included in itemTexts result,
                    // we get it directly.
                    if let id = item.itemID {
                        text = texts["\(item.type.rawValue)_\(id)"]
                    }
                case .star:
                    text = .init(
                        name: .init(
                            jp: "スター (無償)",
                            en: "Star (Free)",
                            tw: "Star (免費)",
                            cn: "星石 (免费)",
                            kr: "스타 (무료)"
                        ),
                        type: nil,
                        resourceID: -1
                    )
                case .coin:
                    text = .init(
                        name: .init(
                            jp: "コイン",
                            en: "Coin",
                            tw: "金幣",
                            cn: "金币",
                            kr: "골드"
                        ),
                        type: nil,
                        resourceID: -1
                    )
                case .stamp:
                    text = .init(
                        name: .init(
                            jp: "レアスタンプ",
                            en: "Rare Stamp",
                            tw: "稀有貼圖",
                            cn: "稀有表情",
                            kr: "레어 스탬프"
                        ),
                        type: nil,
                        resourceID: -1
                    )
                case .degree:
                    text = .init(
                        name: .init(
                            jp: "Title",
                            en: "称号",
                            tw: "稱號",
                            cn: "称号",
                            kr: "제목"
                        ),
                        type: nil,
                        resourceID: -1
                    )
                default: break
                }
                result.append(.init(item: item, text: text))
            }
            return result
        }
        
        public static func extendedPlayerProfile(of id: Int, in locale: DoriAPI.Locale) async -> ExtendedPlayerProfile? {
            let groupResult = await withTasksResult {
                await DoriAPI.Misc.playerProfile(of: id, in: locale)
            } _: {
                await DoriAPI.Degree.all()
            } _: {
                await DoriAPI.Card.all()
            } _: {
                await DoriAPI.Song.all()
            }
            guard let profile = groupResult.0 else { return nil }
            guard let degrees = groupResult.1 else { return nil }
            guard let cards = groupResult.2 else { return nil }
            guard let songs = groupResult.3 else { return nil }
            
            return .init(
                profile: profile,
                degrees: degrees.filter { profile.userProfileDegree.compactMap { $0 }.contains($0.id)
                },
                keyVisualCard: cards.first { $0.id == profile.userProfileSituation.situationID } ?? .init( // dummy
                    id: -1,
                    characterID: -1,
                    rarity: -1,
                    attribute: .powerful,
                    levelLimit: -1,
                    resourceSetName: "",
                    prefix: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil),
                    releasedAt: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil),
                    skillID: -1,
                    type: .others,
                    stat: .init()
                ),
                mainDeckCards: cards.filter {
                    [profile.mainUserDeck.leader,
                     profile.mainUserDeck.member1,
                     profile.mainUserDeck.member2,
                     profile.mainUserDeck.member3,
                     profile.mainUserDeck.member4].contains($0.id)
                },
                songs: songs.filter {
                    (profile.userHighScoreRating.poppinParty.map(\.musicID)
                     + profile.userHighScoreRating.afterglow.map(\.musicID)
                     + profile.userHighScoreRating.pastelPalettes.map(\.musicID)
                     + profile.userHighScoreRating.helloHappyWorld.map(\.musicID)
                     + profile.userHighScoreRating.roselia.map(\.musicID)
                     + profile.userHighScoreRating.others.map(\.musicID)
                     + profile.userHighScoreRating.morfonica.map(\.musicID)
                     + profile.userHighScoreRating.raiseASuilen.map(\.musicID)
                     + profile.userHighScoreRating.myGO.map(\.musicID)).contains($0.id)
                }
            )
        }
    }
}

extension DoriFrontend {
    public typealias Item = DoriAPI.Item
    
    public struct ExtendedItem: Identifiable, Hashable, DoriCache.Cacheable {
        public var item: Item
        public var text: DoriAPI.Misc.ItemText?
        
        public var id: String {
            item.id
        }
        
        internal init(item: Item, text: DoriAPI.Misc.ItemText?) {
            self.item = item
            self.text = text
        }
    }
    
    public struct ExtendedPlayerProfile: Sendable, Hashable, DoriCache.Cacheable {
        public var profile: DoriAPI.Misc.PlayerProfile
        public var degrees: [DoriAPI.Degree.Degree]
        public var keyVisualCard: DoriAPI.Card.PreviewCard
        public var mainDeckCards: [DoriAPI.Card.PreviewCard]
        public var songs: [DoriAPI.Song.PreviewSong]
    }
}

extension DoriAPI.Misc.StoryAsset {
    /// Textual transcript of story.
    public var transcript: [Transcript] {
        var result = [Transcript]()
        for snippet in self.snippets {
            switch snippet.actionType {
            case .talk:
                let ref = self.talkData[snippet.referenceIndex]
                result.append(.talk(.init(
                    _characterID: ref.talkCharacters.count > 0 ? ref.talkCharacters[0].characterID : 0,
                    characterName: ref.windowDisplayName,
                    text: ref.body,
                    voiceID: ref.voices.count > 0 ? ref.voices[0].voiceID : nil
                )))
            case .effect:
                let ref = self.specialEffectData[snippet.referenceIndex]
                if ref.effectType == .telop {
                    result.append(.notation(ref.stringVal))
                }
            default: break
            }
        }
        return result
    }
    
    public enum Transcript: Sendable, Hashable {
        case talk(Talk)
        case notation(String)
        
        public struct Talk: Sendable, Hashable {
            public var _characterID: Int
            public var characterName: String
            public var text: String
            public var voiceID: String?
            
            internal init(_characterID: Int, characterName: String, text: String, voiceID: String?) {
                self._characterID = _characterID
                self.characterName = characterName
                self.text = text
                self.voiceID = voiceID
            }
            
            @inlinable
            public var characterIconImageURL: URL? {
                if _characterID > 0 {
                    .init(string: "https://bestdori.com/res/icon/chara_icon_\(_characterID).png")!
                } else {
                    nil
                }
            }
        }
    }
}
