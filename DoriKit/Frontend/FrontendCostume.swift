//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendCostume.swift
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

#if !os(watchOS)
import WebKit
#endif

extension DoriFrontend {
    /// Request and fetch data about costume in Bandori.
    public enum Costume {
        /// List all costumes.
        ///
        /// - Returns: All costumes, nil if failed to fetch.
        public static func list(filter: Filter = .init()) async -> [PreviewCostume]? {
            let groupResult = await withTasksResult {
                await DoriAPI.Costume.all()
            } _: {
                await DoriAPI.Character.all()
            }
            guard let costumes = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            
            FilterCacheManager.shared.writeCharactersList(characters)
            
            return costumes
        }
        
        /// Get a detailed costume with related information.
        ///
        /// - Parameter id: The ID of costume.
        /// - Returns: The costume of requested ID,
        ///     with related character and band.
        public static func extendedInformation(of id: Int) async -> ExtendedCostume? {
            let groupResult = await withTasksResult {
                await DoriAPI.Costume.detail(of: id)
            } _: {
                await DoriAPI.Character.all()
            } _: {
                await DoriAPI.Band.all()
            } _: {
                await DoriAPI.Card.all()
            }
            guard let costume = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            guard let bands = groupResult.2 else { return nil }
            guard let cards = groupResult.3 else { return nil }
            
            let character = characters.first { $0.id == costume.characterID } ?? .init( // dummy
                id: -1,
                characterType: .common,
                characterName: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil),
                nickname: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil),
                bandID: nil,
                color: nil
            )
            return .init(
                costume: costume,
                character: character,
                band: bands.first { $0.id == character.bandID } ?? .init( // dummy
                    id: -1,
                    bandName: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
                ),
                cards: cards.filter { costume.cards.contains($0.id) }
            )
        }
        
        #if os(watchOS)
        public static func live2dViewer(for id: Int) -> NSObject {
            dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW)
            let webView = (NSClassFromString("WKWebView") as! NSObject.Type).init()
            webView.perform(
                NSSelectorFromString("loadRequest:"),
                with: URLRequest(url: URL(string: "https://bestdori.com/tool/live2d/costume/\(id)")!)
            )
            let _userScript = (NSClassFromString("WKUserScript") as! NSObject.Type).init()
            defer { _fixLifetime(_userScript) }
            let _userScriptMethod = _userScript.method(for: NSSelectorFromString("initWithSource:injectionTime:forMainFrameOnly:"))!
            let userScript = unsafeBitCast(_userScriptMethod, to: (@convention(c) (NSObject, Selector, NSString, Int, Bool) -> AnyObject).self)(_userScript, NSSelectorFromString("initWithSource:injectionTime:forMainFrameOnly:"), """
            for (let e of document.getElementsByClassName("columns is-gapless is-mobile is-marginless has-background-primary sticky sticky-nav")) { e.remove() }
            for (let e of document.getElementsByClassName("nav-main")) { e.remove() }
            document.getElementById("Community").remove()
            document.getElementById("comments").remove()
            for (let e of document.getElementsByClassName("max-width-40")) { e.remove() }
            for (let e of document.getElementsByClassName("columns is-mobile")) { e.remove() }
            """, 1, true) as! NSObject
            (webView.value(forKeyPath: "configuration.userContentController") as! NSObject).perform(NSSelectorFromString("addUserScript:"), with: userScript)
            return webView
        }
        #endif
    }
}

extension DoriFrontend.Costume {
    public typealias PreviewCostume = DoriAPI.Costume.PreviewCostume
    public typealias Costume = DoriAPI.Costume.Costume
    
    public struct ExtendedCostume: Sendable, Identifiable, Hashable, DoriCache.Cacheable {
        public var costume: Costume
        public var character: DoriAPI.Character.PreviewCharacter
        public var band: DoriAPI.Band.Band
        public var cards: [DoriAPI.Card.PreviewCard]
        
        @inlinable
        public var id: Int {
            costume.id
        }
    }
}

extension DoriFrontend.Costume.ExtendedCostume {
    @inlinable
    public init?(id: Int) async {
        if let costume = await DoriFrontend.Costume.extendedInformation(of: id) {
            self = costume
        } else {
            return nil
        }
    }
}
