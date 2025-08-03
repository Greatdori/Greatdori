//
//  Post.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation
internal import Alamofire
internal import SwiftyJSON

extension DoriAPI {
    public class Post {
        private init() {}
        
        public static func _list(_ request: ListRequest) async -> PagedPosts? {
            let result = await requestJSON("https://bestdori.com/api/post/list", method: .post, parameters: request, encoder: JSONParameterEncoder.default)
            if case let .success(respJSON) = result {
                let task = Task.detached(priority: .userInitiated) { () async -> PagedPosts? in
                    guard respJSON["result"].boolValue else { return nil }
                    return .init(
                        total: respJSON["count"].intValue,
                        currentOffset: request.offset,
                        content: respJSON["posts"].map {
                            .init(
                                id: $0.1["id"].intValue,
                                categoryName: .init(rawValue: $0.1["categoryName"].stringValue) ?? .selfPost,
                                categoryID: $0.1["categoryId"].stringValue,
                                title: $0.1["title"].stringValue,
                                content: .init(parsing: $0.1["content"])
                            )
                        }
                    )
                }
                return await task.value
            }
            return nil
        }
        
        @inlinable
        public static func communityPosts(limit: Int = 20, offset: Int) async -> PagedPosts? {
            await _list(.init(categoryName: .selfPost, categoryId: "text", order: .timeDescending, limit: limit, offset: offset))
        }
    }
}

extension DoriAPI.Post {
    public struct Post: Identifiable {
        public var id: Int
        public var categoryName: Category
        public var categoryID: String
        public var title: String
        public var content: RichContentGroup
    }
    
    public struct PagedPosts: PagedContent {
        public var total: Int
        public var currentOffset: Int
        public var content: [Post]
    }
    
    public enum Category: String {
        case selfPost = "SELF_POST"
    }
    
    public struct ListRequest: Encodable {
        public var following: Bool
        public var categoryName: String
        public var categoryId: String
        public var order: String
        public var limit: Int
        public var offset: Int
        
        public init(
            _following following: Bool = false,
            categoryName: Category,
            categoryId: String,
            order: ListOrder,
            limit: Int = 20,
            offset: Int
        ) {
            self.following = following
            self.categoryName = categoryName.rawValue
            self.categoryId = categoryId
            self.order = order.rawValue
            self.limit = limit
            self.offset = offset
        }
    }
    public enum ListOrder: String {
        case timeAscending = "TIME_ASC"
        case timeDescending = "TIME_DESC"
    }
}
