//
//  NetworkRequest.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

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
            request.responseData { response in
                let data = response.data
                if data != nil {
                    Task.detached(priority: .userInitiated) {
                        do {
                            let json = try JSON(data: data!)
                            continuation.resume(returning: .success(json))
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
