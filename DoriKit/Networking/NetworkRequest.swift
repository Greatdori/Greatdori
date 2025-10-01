//===---*- Greatdori! -*---------------------------------------------------===//
//
// NetworkRequest.swift
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
internal import Alamofire
internal import SwiftyJSON

internal func requestJSON(
    _ convertible: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    interceptor: RequestInterceptor? = nil,
    requestModifier: Session.RequestModifier? = nil
) async -> Result<JSON, Void> {
    switch offlineAssetResult(for: convertible) {
    case .delegated(let data):
        if let data {
            let task = Task.detached(priority: .userInitiated) { () -> Result<JSON, Void> in
                do {
                    let json = try JSON(data: data)
                    return .success(json)
                } catch {
                    return .failure(())
                }
            }
            return await task.value
        } else {
            return .failure(())
        }
    case .useDefault:
        break
    }
    
    if DoriCache.preferCachedNetworkSource,
       let url = try? convertible.asURL(),
       let cache = await NetworkCache.shared.getCache(for: url),
       abs(Date.now.timeIntervalSince1970 - cache.dateUpdated.timeIntervalSince1970) < 60 * 60 {
        if let json = (try? JSON(data: cache.data)) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                AF.request(
                    convertible,
                    method: method,
                    parameters: parameters,
                    encoding: encoding,
                    interceptor: interceptor,
                    requestModifier: requestModifier
                ).responseData { response in
                    if let data = response.data {
                        Task.detached(priority: .userInitiated) {
                            if (try? JSON(data: data)) != nil {
                                await NetworkCache.shared.updateCache(.init(data: data), for: url)
                            }
                        }
                    }
                }
            }
            return .success(json)
        } else {
            await NetworkCache.shared.removeCache(for: url)
        }
    }
    
    let request = AF.request(
        convertible,
        method: method,
        parameters: parameters,
        encoding: encoding,
        interceptor: interceptor,
        requestModifier: requestModifier
    )
    return await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
            let preferCachedNetworkSource = DoriCache.preferCachedNetworkSource
            request.responseData { response in
                let data = response.data
                if data != nil {
                    Task.detached(priority: .userInitiated) {
                        do {
                            let json = try JSON(data: data!)
                            continuation.resume(returning: .success(json))
                            if preferCachedNetworkSource, let url = try? convertible.asURL() {
                                await NetworkCache.shared.updateCache(.init(data: data!), for: url)
                            }
                        } catch {
                            continuation.resume(returning: .failure(()))
                        }
                    }
                } else {
                    continuation.resume(returning: .failure(()))
                }
            }
        }
    } onCancel: {
        request.cancel()
    }
}
internal func requestJSON<Parameters: Encodable & Sendable>(
    _ convertible: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoder: any ParameterEncoder = URLEncodedFormParameterEncoder.default,
    interceptor: RequestInterceptor? = nil,
    requestModifier: Session.RequestModifier? = nil
) async -> Result<JSON, Void> {
    switch offlineAssetResult(for: convertible) {
    case .delegated(let data):
        if let data {
            let task = Task.detached(priority: .userInitiated) { () -> Result<JSON, Void> in
                do {
                    let json = try JSON(data: data)
                    return .success(json)
                } catch {
                    return .failure(())
                }
            }
            return await task.value
        } else {
            return .failure(())
        }
    case .useDefault:
        break
    }
    
    if DoriCache.preferCachedNetworkSource,
       let url = try? convertible.asURL(),
       let cache = await NetworkCache.shared.getCache(for: url),
       abs(Date.now.timeIntervalSince1970 - cache.dateUpdated.timeIntervalSince1970) < 60 * 60 {
        if let json = (try? JSON(data: cache.data)) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                AF.request(
                    convertible,
                    method: method,
                    parameters: parameters,
                    encoder: encoder,
                    interceptor: interceptor,
                    requestModifier: requestModifier
                ).responseData { response in
                    if let data = response.data {
                        Task.detached(priority: .userInitiated) {
                            if (try? JSON(data: data)) != nil {
                                await NetworkCache.shared.updateCache(.init(data: data), for: url)
                            }
                        }
                    }
                }
            }
            return .success(json)
        } else {
            await NetworkCache.shared.removeCache(for: url)
        }
    }
    
    let request = AF.request(
        convertible,
        method: method,
        parameters: parameters,
        encoder: encoder,
        interceptor: interceptor,
        requestModifier: requestModifier
    )
    return await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
            request.responseData { response in
                let data = response.data
                if data != nil {
                    Task.detached(priority: .userInitiated) {
                        do {
                            let json = try JSON(data: data!)
                            continuation.resume(returning: .success(json))
                            if DoriCache.preferCachedNetworkSource, let url = try? convertible.asURL() {
                                await NetworkCache.shared.updateCache(.init(data: data!), for: url)
                            }
                        } catch {
                            continuation.resume(returning: .failure(()))
                        }
                    }
                } else {
                    continuation.resume(returning: .failure(()))
                }
            }
        }
    } onCancel: {
        request.cancel()
    }
}

internal enum Result<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

extension Result: Sendable where Success: Sendable, Failure: Sendable {}

extension JSON: @retroactive @unchecked Sendable {}
