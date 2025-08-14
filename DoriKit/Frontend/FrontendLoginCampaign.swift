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
    public class LoginCampaign {
        private init() {}
        
        public static func list(filter: Filter = .init()) async -> [PreviewCampaign]? {
            guard let campaigns = await DoriAPI.LoginCampaign.all() else { return nil }
            
            var filteredCampaigns = campaigns
            if filter.isFiltered {
                filteredCampaigns = campaigns.filter { campaign in
                    filter.server.contains { locale in
                        campaign.publishedAt.availableInLocale(locale)
                    }
                }.filter { campaign in
                    for timelineStatus in filter.timelineStatus {
                        let result = switch timelineStatus {
                        case .ended:
                            (campaign.closedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                        case .ongoing:
                            (campaign.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                            && (campaign.closedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                        case .upcoming:
                            (campaign.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                        }
                        if result {
                            return true
                        }
                    }
                    return false
                }
            }
            
            switch filter.sort.keyword {
            case .releaseDate(let locale):
                return filteredCampaigns.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.publishedAt.forLocale(locale) ?? lhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.publishedAt.forLocale(locale) ?? rhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            default:
                return filteredCampaigns.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
        }
    }
}

extension DoriFrontend.LoginCampaign {
    public typealias PreviewCampaign = DoriAPI.LoginCampaign.PreviewCampaign
}
