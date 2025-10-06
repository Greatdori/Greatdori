//===---*- Greatdori! -*---------------------------------------------------===//
//
// Live2DModel.swift
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

#if canImport(SwiftUI) && canImport(WebKit)

import Foundation
internal import SwiftyJSON

internal struct Live2DModel {
    internal var model: File
    internal var physics: File
    internal var textures: [File]
    internal var transition: File
    internal var motions: [File]
    internal var expressions: [File]
    
    internal init(json: JSON) {
        self.model = .init(json: json["Base"]["model"])
        self.physics = .init(json: json["Base"]["physics"])
        self.textures = json["Base"]["textures"].map { .init(json: $0.1) }
        self.transition = .init(json: json["Base"]["transition"])
        self.motions = json["Base"]["motions"].map { .init(json: $0.1) }
        self.expressions = json["Base"]["expressions"].map { .init(json: $0.1) }
    }
    
    internal struct File: Hashable {
        internal var bundleName: String
        internal var _fileName: String
        
        internal var fileName: String {
            if _fileName.hasSuffix(".bytes") {
                String(_fileName.dropLast(".bytes".count))
            } else {
                _fileName
            }
        }
        internal var absoluteURL: URL {
            .init(string: "https://bestdori.com/assets/jp/\(bundleName)_rip/\(fileName)")!
        }
        
        internal func preload() -> DoriCache.PreloadDescriptor<String> {
            //                                 Local file path ~~~~~~
            DoriCache.preload {
                let filePath = NSHomeDirectory() + "/tmp/\(bundleName.components(separatedBy: "/").last!)_\(fileName)"
                if !FileManager.default.fileExists(atPath: filePath) {
                    return await withCheckedContinuation { continuation in
                        DispatchQueue(label: "com.memz233.DoriKit.Live2DModel-File-Preload", qos: .userInitiated).async {
                            if let data = try? Data(contentsOf: absoluteURL),
                               (try? data.write(to: URL(filePath: filePath))) != nil {
                                continuation.resume(returning: filePath)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                } else {
                    return filePath
                }
            }
        }
    }
}
extension Live2DModel.File {
    internal init(json: JSON) {
        self.init(
            bundleName: json["bundleName"].stringValue,
            _fileName: json["fileName"].stringValue
        )
    }
}

#endif // canImport(SwiftUI) && canImport(WebKit)
