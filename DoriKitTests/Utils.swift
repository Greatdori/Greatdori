//
//  Utils.swift
//  Greatdori
//
//  Created by Mark Chan on 7/27/25.
//

import Testing
import Foundation
import SwiftyJSON
@testable import DoriKit

func retryableRequestJSON(_ url: String, maxCount: Int = 5) async -> JSON? {
    for _ in 0..<maxCount {
        let request = await requestJSON(url)
        if case let .success(respJSON) = request {
            return respJSON
        }
    }
    return nil
}

func findExtraKeys<T: Decodable>(in json: JSON, comparedTo instance: T, exceptions: [String] = []) -> [String] {
    return findExtraKeys(in: json, comparedTo: Mirror(reflecting: instance), prefix: "", original: instance, exceptions: exceptions)
}

private func findExtraKeys(in json: JSON, comparedTo mirror: Mirror, prefix: String, original: Any, exceptions: [String]) -> [String] {
    var structKeys = Set<String>()
    var childrenMap: [String: Mirror.Child] = [:]
    
    for child in mirror.children {
        if let key = child.label {
            structKeys.insert(key)
            childrenMap[key] = child
        }
    }
    
    var extraKeys: [String] = []
    
    for (key, subJson) in json {
        if !structKeys.map({ $0.lowercased() }).contains(key.lowercased()) && !exceptions.map({ $0.lowercased() }).contains(key.lowercased()) {
            extraKeys.append(prefix + key)
        } else if let child = childrenMap[key] {
            let childValue = child.value
            let childMirror = Mirror(reflecting: childValue)
            
            if subJson.type == .dictionary {
                if childMirror.displayStyle == .struct || childMirror.displayStyle == .class {
                    let nestedExtras = findExtraKeys(in: subJson, comparedTo: childMirror, prefix: prefix + key + ".", original: childValue, exceptions: exceptions)
                    extraKeys.append(contentsOf: nestedExtras)
                }
            } else if isEnum(type(of: childValue)) {
                if let rawRepresentableType = type(of: childValue) as? (any RawRepresentable.Type) {
                    let rawValue = subJson.rawValue
                    
                    if !isValidEnumValue(rawValue: rawValue, enumType: rawRepresentableType) {
                        extraKeys.append(prefix + key + " (invalid enum value: \(subJson.stringValue))")
                    }
                }
            }
        }
    }
    
    return extraKeys
}

private func isEnum(_ type: Any.Type) -> Bool {
    Mirror(reflecting: type).displayStyle == .enum ||
    String(describing: type).contains(".")
}

private func isValidEnumValue<T: RawRepresentable>(rawValue: Any, enumType: T.Type) -> Bool {
    switch rawValue {
    case let str as String:
        return enumType.init(rawValue: str as! T.RawValue) != nil
    case let int as Int:
        return enumType.init(rawValue: int as! T.RawValue) != nil
    default:
        return false
    }
}

extension JSON {
    func sorted() -> [Element] {
        self.sorted { lhs, rhs in
            if let intl = Int(lhs.0), let intr = Int(rhs.0) {
                intl < intr
            } else {
                lhs.0 < rhs.0
            }
        }
    }
}

extension Comment {
    init(_ array: [Any]...) {
        var result = [String]()
        for a in array {
            result.append("[\n\(a.map { var r = ""; dump($0, to: &r); return r.components(separatedBy: "\n").map { "  \($0)" }.joined(separator: "\n") }.joined(separator: ",\n"))\n]")
        }
        self = "\(result.joined(separator: "\n\n"))"
    }
    @_disfavoredOverload
    init(_ any: Any...) {
        self = "\(any.map { var r = ""; dump($0, to: &r); return r }.joined(separator: "\n\n"))"
    }
}
