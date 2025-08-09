//===---*- Greatdori! -*---------------------------------------------------===//
//
// CommunityStoriesView.swift
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

import SwiftUI
import DoriKit

struct CommunityStoriesView: View {
    @State var posts: DoriAPI.Post.PagedPosts?
    @State var availability = true
    @State var pageOffset = 0
    @State var isLoadingMore = false
    var body: some View {
        Form {
            if let posts {
                ForEach(Array(posts.content.enumerated()), id: \.element.id) { (index, post) in
                    VStack(alignment: .leading) {
                        if let storyMeta = post.storyMetadata {
                            HStack {
                                Spacer(minLength: 0)
                                VStack(alignment: .leading) {
                                    Text(post.title)
                                        .font(.headline)
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                        Text(storyMeta.rating.localizedString)
                                    }
                                    Text(storyMeta.summary)
                                        .font(.system(size: 14))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                        }
                        RichContentView(post.content)
                            .richEmojiFrame(width: 15, height: 15)
                            .font(.system(size: 14))
                    }
                    .onAppear {
                        if !isLoadingMore {
                            continueLoadPosts()
                        }
                    }
                }
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入故事时出错", systemImage: "book.pages.fill", retryHandler: getPosts)
                }
            }
        }
        .navigationTitle("故事")
        .task {
            await getPosts()
        }
    }
    
    func getPosts() async {
        posts = await DoriAPI.Post.communityStories(offset: pageOffset)
    }
    func continueLoadPosts() {
        if let posts, posts.hasMore {
            pageOffset = posts.nextOffset
            Task {
                isLoadingMore = true
                if let newPosts = await DoriAPI.Post.communityPosts(offset: pageOffset) {
                    self.posts!.content += newPosts.content
                }
                isLoadingMore = false
            }
        }
    }
}
