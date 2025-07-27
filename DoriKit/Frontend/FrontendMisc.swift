//
//  FrontendMisc.swift
//  Greatdori
//
//  Created by Mark Chan on 7/26/25.
//

import Foundation

extension DoriFrontend {
    public class Misc {
        private init() {}
        
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
    }
}

extension DoriFrontend {
    public typealias Item = DoriAPI.Item
    
    public struct ExtendedItem: Identifiable, DoriCache.Cacheable {
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
}
