//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriNotification.swift
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
internal import SwiftyJSON

public final class DoriNotification {
    public static func registerRemoteNewsNotification(deviceToken: Data) async -> UUID? {
        let tokenHex = deviceToken.map { unsafe String(format: "%02hhx", $0) }.joined()
        let result = await requestJSON("https://api.push.greatdori.memz.top/add/\(tokenHex)")
        if case let .success(respJSON) = result,
           let id = respJSON["result"]["id"].string {
            return .init(uuidString: id)
        } else {
            return nil
        }
    }
    
    public static func unregisterRemoteNewsNotification(id: UUID) async -> Bool {
        let result = await requestJSON("https://api.push.greatdori.memz.top/remove/\(id.uuidString.lowercased())")
        if case let .success(respJSON) = result {
            return respJSON["success"].boolValue
        }
        return false
    }
}
