//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsMarkdown.swift
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

extension Array<DoriAPI.News.Item.Content> {
    public func toMarkdown(
        locale: Locale = .current,
        dateFormatter: DateFormatter = .init()
    ) -> String {
        self.map { compileNewsContent($0, locale: locale, dateFormatter: dateFormatter) }.joined(separator: "\n\n")
    }
}

private func compileNewsContent(
    _ content: DoriAPI.News.Item.Content,
    locale: Locale,
    dateFormatter: DateFormatter
) -> String {
    switch content {
    case .content(let sections):
        sections.map { compileContentSection($0, locale: locale, dateFormatter: dateFormatter) }.joined(separator: "\n")
    case .heading(let content):
        "## \(NSLocalizedString(content, bundle: #bundle, comment: ""))"
    }
}

private func compileContentSection(
    _ section: DoriAPI.News.Item.Content.ContentDataSection,
    locale: Locale,
    dateFormatter: DateFormatter
) -> String {
    switch section {
    case .localizedText(let key):
        String(localized: .init(key), bundle: #bundle, locale: locale)
    case .textLiteral(let string):
        string
    case .ul(let list):
        compileBulletList(list, locale: locale, dateFormatter: dateFormatter)
    case .link(let target, let data, _):
        if target == "asset-single" {
            "![\(data)](greatdori://rich-content/asset/\(data))"
        } else {
            "[\(parseLinkTargetName(target, data: data))](\(parseLinkTarget(target, data: data)))"
        }
    case .br:
        "\n\n"
    case .date(let date):
        dateFormatter.string(from: date)
    }
}

private func compileBulletList(
    _ contents: [[DoriAPI.News.Item.Content.ContentDataSection]],
    locale: Locale,
    dateFormatter: DateFormatter
) -> String {
    var result = ""
    for content in contents {
        if content.count > 1 {
            let compiledList = content.map { "- \(setIndent(4, to: compileContentSection($0, locale: locale, dateFormatter: dateFormatter)))" }
            let joinedList = compiledList.joined(separator: "\n")
            result.append("- List\n\(setIndent(4, to: joinedList, ignoresFirstLine: false))")
        } else if let c = content.first {
            let compiled = compileContentSection(c, locale: locale, dateFormatter: dateFormatter)
            result.append(setIndent(4, to: "- \(compiled)") + "\n")
        }
    }
    return String(result.dropLast())
}

private func parseLinkTarget(_ target: String, data: String) -> String {
    switch target {
    case "live2d-asset": "https://bestdori.com/tool/live2d/asset/\(DoriAPI.preferredLocale.rawValue)/\(data)"
    case "story-asset": "https://bestdori.com/tool/storyviewer/asset/\(DoriAPI.preferredLocale.rawValue)/\(data)"
    case "asset-single": "https://bestdori.com/tool/explorer/asset/\(DoriAPI.preferredLocale.rawValue)/\(data)"
    case "join-us": "https://bestdori.com/home/join"
    case "support-us": "https://bestdori.com/home/support"
    default:
        if target.hasPrefix("/") {
            "https://bestdori.com\(target)"
        } else {
            target
        }
    }
}
private func parseLinkTargetName(_ target: String, data: String) -> String {
    switch target {
    case "join-us": "Join Us"
    case "support-us": "Support Us"
    default: parseLinkTarget(target, data: data)
    }
}

private func setIndent(_ length: Int, to string: String, ignoresFirstLine: Bool = true) -> String {
    if !ignoresFirstLine {
        string
            .components(separatedBy: .newlines)
            .map { String(repeating: " ", count: length) + $0 }
            .joined(separator: "\n")
    } else {
        string
            .components(separatedBy: .newlines)
            .enumerated()
            .map { ($0 != 0 ? String(repeating: " ", count: length) : "") + $1 }
            .joined(separator: "\n")
    }
}
