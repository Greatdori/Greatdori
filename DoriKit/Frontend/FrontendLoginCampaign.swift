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
        /// List all login campaigns with a filter.
        ///
        /// - Parameter filter: A ``DoriFrontend/Filter`` for filtering result.
        /// - Returns: All login campaigns, nil if failed to fetch.
        ///
        /// This function respects these keys in `filter`:
        ///
        /// - ``DoriFrontend/Filter/Key/server``
        /// - ``DoriFrontend/Filter/Key/timelineStatus``
        /// - ``DoriFrontend/Filter/Key/loginCampaignType``
        /// - ``DoriFrontend/Filter/Key/sort``
        ///     - ``DoriFrontend/Filter/Sort/Keyword/releaseDate(in:)``
        ///     - ``DoriFrontend/Filter/Sort/Keyword/id``
        ///
        /// Other keys are ignored.
        public static func list() async -> [PreviewCampaign]? {
            guard let campaigns = await DoriAPI.LoginCampaign.all() else { return nil }
            return campaigns
        }
    }
}

extension DoriFrontend.LoginCampaign {
    public typealias PreviewCampaign = DoriAPI.LoginCampaign.PreviewCampaign
}
