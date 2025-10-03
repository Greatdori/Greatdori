//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCollectionCoding.swift
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

struct CollectionEncodingInfo: Equatable {
    var name: String
    var cardList: [Int]
}
func encodeCollection(_ info: CollectionEncodingInfo) -> String {
    func compressInts(_ arr: [Int], preservesOrder: Bool = false) -> String {
        func encodeInt(_ value: UInt, into data: inout Data) {
            var v = value
            repeat {
                var byte = UInt8(v & 0x7F)
                v >>= 7
                if v != 0 {
                    byte |= 0x80
                }
                data.append(byte)
            } while v != 0
        }
        
        guard !arr.isEmpty else { return "" }
        
        var resultData = Data()
        
        if !preservesOrder {
            let arr = Array(Set(arr))
            let pos = arr.filter { $0 > 0 }.sorted()
            let neg = arr.filter { $0 < 0 }.map { -$0 }.sorted()
            var posDiffs: [Int] = []
            if !pos.isEmpty {
                posDiffs = [pos[0]]
                if pos.count > 1 {
                    for i in 1..<pos.count {
                        posDiffs.append(pos[i] - pos[i-1])
                    }
                }
            }
            var negDiffs: [Int] = []
            if !neg.isEmpty {
                negDiffs = [neg[0]]
                if neg.count > 1 {
                    for i in 1..<neg.count {
                        negDiffs.append(neg[i] - neg[i-1])
                    }
                }
            }
            
            for num in negDiffs {
                let unsigned = UInt(num)
                encodeInt(unsigned, into: &resultData)
            }
            encodeInt(0, into: &resultData)
            for num in posDiffs {
                let unsigned = UInt(num)
                encodeInt(unsigned, into: &resultData)
            }
        } else {
            for num in arr {
                let unsigned = UInt(bitPattern: num)
                encodeInt(unsigned, into: &resultData)
            }
        }
        
        if resultData.isEmpty { return "" }
        let charList: [UInt8] = Array(33...126).map { UInt8($0) }
        
        var leadingZeros = 0
        var index = 0
        let bytes = [UInt8](resultData)
        while index < bytes.count && bytes[index] == 0 {
            leadingZeros += 1
            index += 1
        }
        
        var num = Array(bytes[index...])
        var chars: [UInt8] = []
        
        while !num.isEmpty && !(num.count == 1 && num[0] == 0) {
            var remainder = 0
            var newNum: [UInt8] = []
            var seenNonZero = false
            
            for b in num {
                let acc = (remainder << 8) + Int(b)
                let q = acc / 94
                remainder = acc % 94
                if q != 0 || seenNonZero {
                    newNum.append(UInt8(q))
                    seenNonZero = true
                } else if !seenNonZero {
                    // skip leading zero in quotient
                }
            }
            
            chars.append(charList[remainder])
            num = newNum
            if num.isEmpty { break }
        }
        
        chars.reverse()
        
        let prefix = [UInt8](repeating: charList[0], count: leadingZeros)
        let outBytes = prefix + chars
        return String(bytes: outBytes, encoding: .ascii) ?? ""
    }
    
    func verification(of string: String) -> String {
        let slices = stride(from: 0, to: string.count, by: 15).map { startIndex in
            let start = string.index(string.startIndex, offsetBy: startIndex)
            let end = string.index(start, offsetBy: 15, limitedBy: string.endIndex) ?? string.endIndex
            return String(string[start..<end])
        }
        var result = ""
        for slice in slices {
            result += String(UnicodeScalar(Array(33...126)[Int(string2IntArray(slice).map { Int64($0) }.reduce(into: Int64(0)) { $0 += $1 } % 93)]))
        }
        return String(result.prefix(93))
    }
    
    let encodedList = string2IntArray(compressInts(info.cardList))
    let encodedName = string2IntArray(info.name)
    let mergedData = encodedList.map { Int($0) } + [10082625] + encodedName.map { Int($0) }
    let content = compressInts(mergedData, preservesOrder: true)
    let verificationString = verification(of: content)
    let verificationLengthTag = String(UnicodeScalar(Array(33...126)[verificationString.count]))
    // precondition: (each specifiers).count = 3
    let versionSpecifiers = ["HND", "ANO", "UNK", "ANN", "AIN", "PLN", "PNK",
                             "LSL", "CHY", "ANC", "LHR", "LGW", "MAN", "STN",
                             "LTN", "EDI", "BHX", "GLA", "BFS", "NCL"]
    let _thisSpecifier = versionSpecifiers.randomElement()!
    var thisSpecifier: [Character] = []
    for character in _thisSpecifier {
        if Bool.random() {
            thisSpecifier.append(Character(character.lowercased()))
        } else {
            thisSpecifier.append(character)
        }
    }
    return String(thisSpecifier[0]) + verificationLengthTag + content + verificationString + String(thisSpecifier[1...2])
}
func decodeCollection(_ str: String) -> CollectionEncodingInfo? {
    func decompressInts(_ str: String, preservedOrder: Bool = false) -> [Int] {
        func decodeInts(from data: Data) -> [UInt] {
            var values: [UInt] = []
            var value: UInt = 0
            var shift: UInt = 0
            
            for byte in data {
                value |= UInt(byte & 0x7F) << shift
                if (byte & 0x80) == 0 {
                    values.append(value)
                    value = 0
                    shift = 0
                } else {
                    shift += 7
                }
            }
            return values
        }
        
        var data: Data?
        guard !str.isEmpty else { return [] }
        
        guard let bytes = str.data(using: .ascii) else { return [] }
        let ba = [UInt8](bytes)
        
        var leadingZeros = 0
        var pos = 0
        while pos < ba.count && ba[pos] == 33 {
            leadingZeros += 1
            pos += 1
        }
        
        let rest = Array(ba[pos...])
        if rest.isEmpty {
            data = Data(repeating: 0, count: leadingZeros)
        }
        
        var digits: [Int] = []
        for c in rest {
            let v = Int(c) - 33
            if v < 0 || v >= 94 { return [] }
            digits.append(v)
        }
        
        var bigInt: [UInt8] = [0]
        
        for d in digits {
            var carry = d
            for i in (0..<bigInt.count).reversed() {
                let prod = Int(bigInt[i]) * 94 + carry
                bigInt[i] = UInt8(prod & 0xff)
                carry = prod >> 8
            }
            while carry > 0 {
                bigInt.insert(UInt8(carry & 0xff), at: 0)
                carry >>= 8
            }
        }
        
        while bigInt.count > 1 && bigInt.first == 0 {
            bigInt.removeFirst()
        }
        
        if leadingZeros > 0 {
            let zeros = [UInt8](repeating: 0, count: leadingZeros)
            bigInt = zeros + bigInt
        }
        
        data = Data(bigInt)
        guard let data else { return [] }
        
        var result: [Int] = []
        
        if !preservedOrder {
            let diffs = decodeInts(from: data)
            guard diffs != [0] else { return [] } // fast-path
            var diffIterator = diffs.makeIterator()
            
            var positiveFlag = false
            var negDiffs: [Int] = []
            var posDiffs: [Int] = []
            while let number = diffIterator.next() {
                if number == 0 {
                    positiveFlag = true
                    continue
                }
                if positiveFlag {
                    posDiffs.append(Int(number))
                } else {
                    negDiffs.append(Int(number))
                }
            }
            
            
            if !negDiffs.isEmpty {
                result.append(negDiffs[0])
                if negDiffs.count > 1 {
                    for i in 1..<negDiffs.count {
                        result.append(result.last! + negDiffs[i])
                    }
                }
                result = result.map { -$0 }
            }
            if !posDiffs.isEmpty {
                result.append(posDiffs[0])
                if posDiffs.count > 1 {
                    for i in 1..<posDiffs.count {
                        result.append(result.last! + posDiffs[i])
                    }
                }
            }
        } else {
            let parts = decodeInts(from: data)
            for part in parts {
                result.append(Int(bitPattern: part))
            }
        }
        return result
    }
    
    func verify(_ string: String, with code: String) -> Bool {
        let slices = stride(from: 0, to: string.count, by: 15).map { startIndex in
            let start = string.index(string.startIndex, offsetBy: startIndex)
            let end = string.index(start, offsetBy: 15, limitedBy: string.endIndex) ?? string.endIndex
            return String(string[start..<end])
        }
        var result = ""
        for slice in slices {
            result += String(UnicodeScalar(Array(33...126)[Int(string2IntArray(slice).map { Int64($0) }.reduce(into: Int64(0)) { $0 += $1 } % 93)]))
        }
        return result.prefix(93) == code
    }
    
    guard str.count > 5 else { return nil } // s[0] + l + c + v + s[1...2]
    // s: version specifier
    // l: specifier length
    // c: subject
    // v: verification string
    // Verify version specifier
    let versionSpecifiers = ["HND", "ANO", "UNK", "ANN", "AIN", "PLN", "PNK",
                             "LSL", "CHY", "ANC", "LHR", "LGW", "MAN", "STN",
                             "LTN", "EDI", "BHX", "GLA", "BFS", "NCL"]
    var str = str
    let specifier = String(str.removeFirst()) + (String(str.removeLast()) + String(str.removeLast())).reversed()
    guard versionSpecifiers.contains(specifier.uppercased()) else { return nil }
    
    // Verify verification code
    var verificationLength = str.removeFirst().unicodeScalars.first!.value - 33
    var verificationString = ""
    while verificationLength > 0 {
        verificationString.insert(str.removeLast(), at: verificationString.startIndex)
        verificationLength -= 1
    }
    guard verify(str, with: verificationString) else { return nil }
    
    let mergedData = decompressInts(str, preservedOrder: true)
    let splitedData = mergedData.split(separator: 10082625, maxSplits: 1)
    guard splitedData.count == 2 else { return nil }
    if let _decList = intArray2String(splitedData[0].map { Int32($0) }),
       let _decName = intArray2String(splitedData[1].map { Int32($0) }) {
        let decodedList = decompressInts(_decList)
        let decodedName = _decName
        return .init(name: decodedName, cardList: decodedList)
    } else {
        return nil
    }
}

private func string2IntArray(_ input: String) -> [Int32] {
    let data = Array(input.utf8)
    
    var dict: [String: Int] = [:]
    var dictSize = 256
    for i in 0..<256 {
        dict[String(UnicodeScalar(i)!)] = i
    }
    
    var w = ""
    var result: [Int] = []
    
    for byte in data {
        let c = String(UnicodeScalar(Int(byte))!)
        let wc = w + c
        if dict[wc] != nil {
            w = wc
        } else {
            result.append(dict[w]!)
            dict[wc] = dictSize
            dictSize += 1
            w = c
        }
    }
    if !w.isEmpty {
        result.append(dict[w]!)
    }
    
    return result.map { Int32($0) }
}
private func intArray2String(_ compressed: [Int32]) -> String? {
    guard !compressed.isEmpty else { return "" }
    
    var dict: [Int: String] = [:]
    var dictSize = 256
    for i in 0..<256 {
        dict[i] = String(UnicodeScalar(i)!)
    }
    
    var result = ""
    var w = dict[Int(compressed[0])]!
    result.append(w)
    
    for k in compressed.dropFirst() {
        let entry: String
        if let s = dict[Int(k)] {
            entry = s
        } else if Int(k) == dictSize {
            entry = w + String(w.first!)
        } else {
            return nil
        }
        
        result.append(entry)
        dict[dictSize] = w + String(entry.first!)
        dictSize += 1
        w = entry
    }
    
    let bytes = result.unicodeScalars.map { UInt8($0.value) }
    return String(data: Data(bytes), encoding: .utf8) ?? ""
}
