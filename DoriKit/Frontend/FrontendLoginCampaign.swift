//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendLoginCampaign.swift
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
    /// Request and fetch data about login campaigns in Bandori.
    public enum LoginCampaign {
        /// List all login campaigns.
        ///
        /// - Returns: All login campaigns, nil if failed to fetch.
        public static func list() async -> [PreviewCampaign]? {
            guard let campaigns = await DoriAPI.LoginCampaign.all() else { return nil }
            return campaigns
        }
    }
}

extension DoriFrontend.LoginCampaign {
    public typealias PreviewCampaign = DoriAPI.LoginCampaign.PreviewCampaign
}
