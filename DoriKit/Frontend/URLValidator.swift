//===---*- Greatdori! -*---------------------------------------------------===//
//
// URLValidator.swift
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

import Combine
import Foundation
internal import Alamofire

extension DoriFrontend {
    /// Validate URLs from DoriKit.
    ///
    /// - IMPORTANT:
    ///     This class should only be used to validate URLs from DoriKit.
    ///     It may give false results for other URLs.
    public final class URLValidator: @unchecked Sendable, ObservableObject {
        /// Validates reachability of a URL from DoriKit.
        /// - Parameter url: A URL from DoriKit for validation.
        /// - Returns: Whether the provided URL is reachable.
        ///
        /// - IMPORTANT:
        ///     This function should only be used to validate URLs from DoriKit.
        ///     It may give false results for other URLs.
        public static func reachability(of url: URL) async -> Bool {
            let request = AF.request(url, method: .head)
            return await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    request.response { response in
                        continuation.resume(returning: response.response?.headers["Content-Type"] != "text/html")
                    }
                }
            } onCancel: {
                request.cancel()
            }
        }
        
        @Published public private(set) var validURLs: [URL]
        
        private var validationTask: Task<Void, Never>?
        
        public init(validating urls: [URL]) {
            self._validURLs = .init(initialValue: urls)
            
            self.validationTask = Task {
                var validationResult = [URL]()
                for url in urls where await DoriFrontend.URLValidator.reachability(of: url) {
                    validationResult.append(url)
                }
                self.validURLs = validationResult
            }
        }
        
        deinit {
            validationTask?.cancel()
        }
    }
}
