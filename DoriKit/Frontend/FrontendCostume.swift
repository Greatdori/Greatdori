//
//  FrontendCostume.swift
//  Greatdori
//
//  Created by Mark Chan on 7/26/25.
//

import Foundation

#if !os(watchOS)
import WebKit
#endif

extension DoriFrontend {
    public class Costume {
        private init() {}
        
        public static func list(filter: Filter = .init()) async -> [PreviewCostume]? {
            let groupResult = await withTasksResult {
                await DoriAPI.Costume.all()
            } _: {
                await DoriAPI.Character.all()
            }
            guard let costumes = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            
            let filteredCostumes = costumes.filter { costume in
                filter.band.contains { band in
                    band.rawValue == characters.first(where: { $0.id == costume.characterID })?.bandID
                }
            }.filter { costume in
                filter.character.contains { character in
                    character.rawValue == costume.characterID
                }
            }.filter { costume in
                filter.server.contains { locale in
                    costume.publishedAt.availableInLocale(locale)
                }
            }.filter { costume in
                for bool in filter.released {
                    for locale in filter.server {
                        if bool {
                            if (costume.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 4107477600)) < .now {
                                return true
                            }
                        } else {
                            if (costume.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                                return true
                            }
                        }
                    }
                }
                return false
            }
            let sortedCostumes = switch filter.sort.keyword {
            case .releaseDate(let locale):
                filteredCostumes.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.publishedAt.forLocale(locale) ?? lhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.publishedAt.forLocale(locale) ?? rhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            default:
                filteredCostumes.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
            return sortedCostumes
        }
        
        #if !os(watchOS)
        @MainActor
        public static func live2dViewer(for id: Int) -> WKWebView {
            let webView = WKWebView()
            webView.load(.init(url: URL(string: "https://bestdori.com/tool/live2d/costume/\(id)")!))
            webView.configuration.userContentController.addUserScript(
                .init(
                    source: """
                    for (let e of document.getElementsByClassName("columns is-gapless is-mobile is-marginless has-background-primary sticky sticky-nav")) { e.remove() }
                    for (let e of document.getElementsByClassName("nav-main")) { e.remove() }
                    document.getElementById("Community").remove()
                    document.getElementById("comments").remove()
                    for (let e of document.getElementsByClassName("max-width-40")) { e.remove() }
                    for (let e of document.getElementsByClassName("columns is-mobile")) { e.remove() }
                    """,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
            return webView
        }
        #else
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
}
