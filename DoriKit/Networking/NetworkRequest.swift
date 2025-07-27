//
//  NetworkRequest.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

import Foundation
internal import Alamofire
internal import SwiftyJSON

private let headers: HTTPHeaders = [
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Accept-Language": "en-US,en;q=0.9",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
]

internal func requestJSON(_ convertible: URLConvertible, method: HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, interceptor: RequestInterceptor? = nil, requestModifier: Session.RequestModifier? = nil) async -> Result<JSON, Void> {
    await withCheckedContinuation { continuation in
        AF.request(convertible, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, requestModifier: requestModifier).responseData { response in
            let data = response.data
            if data != nil {
                do {
                    let json = try JSON(data: data!)
                    continuation.resume(returning: .success(json))
                } catch {
                    continuation.resume(returning: .failure(()))
                }
            } else {
                continuation.resume(returning: .failure(()))
            }
        }
    }
}
internal func requestString(_ convertible: URLConvertible, method: HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, interceptor: RequestInterceptor? = nil, requestModifier: Session.RequestModifier? = nil) async -> Result<String, Void> {
    await withCheckedContinuation { continuation in
        AF.request(convertible, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor, requestModifier: requestModifier).responseData { response in
            let data = response.data
            if data != nil {
                let str = String(data: data!, encoding: .utf8)
                if str != nil {
                    continuation.resume(returning: .success(str!))
                } else {
                    continuation.resume(returning: .failure(()))
                }
            } else {
                continuation.resume(returning: .failure(()))
            }
        }
    }
}

internal enum Result<Success, Failure> {
    case success(Success)
    case failure(Failure)
}
