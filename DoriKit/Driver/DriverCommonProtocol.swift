//===---*- Greatdori! -*---------------------------------------------------===//
//
// DriverCommonProtocol.swift
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

// MARK: - TitleDescribable

public protocol TitleDescribable {
    var title: LocalizedData<String> { get }
}

extension Band: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.bandName
    }
}

extension PreviewCard: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.prefix
    }
}
extension Card: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.prefix
    }
}
extension ExtendedCard: TitleDescribable {
    public var title: DoriAPI.LocalizedData<String> {
        self.card.prefix
    }
}

extension PreviewCharacter: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.characterName
    }
}
extension BirthdayCharacter: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.characterName
    }
}
extension Character: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.characterName
    }
}
extension ExtendedCharacter: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.character.characterName
    }
}

extension Comic: TitleDescribable {}

extension PreviewCostume: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.description
    }
}
extension Costume: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.description
    }
}
extension ExtendedCostume: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.costume.description
    }
}

extension Degree: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.degreeName
    }
}

extension PreviewEvent: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.eventName
    }
}
extension Event: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.eventName
    }
}
extension ExtendedEvent: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.event.eventName
    }
}

extension PreviewGacha: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.gachaName
    }
}
extension Gacha: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.gachaName
    }
}
extension ExtendedGacha: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.gacha.gachaName
    }
}

extension PreviewLoginCampaign: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.caption
    }
}
extension LoginCampaign: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.caption
    }
}

extension Skill: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.simpleDescription
    }
}

extension PreviewSong: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.musicTitle
    }
}
extension Song: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.musicTitle
    }
}
extension ExtendedSong: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.song.musicTitle
    }
}

extension MiracleTicket: TitleDescribable {
    @inlinable
    public var title: DoriAPI.LocalizedData<String> {
        self.name
    }
}

// MARK: - GettableByID
public protocol GettableByID {
    init?(id: Int) async
}

// Decls are in DoriKit/API/[Name].swift
extension Card: GettableByID {}
extension Character: GettableByID {}
extension Comic: GettableByID {}
extension Costume: GettableByID {}
extension Event: GettableByID {}
extension Gacha: GettableByID {}
extension LoginCampaign: GettableByID {}
extension Song: GettableByID {}

// Decls are in DoriKit/Frontend/[Name].swift
extension ExtendedCard: GettableByID {}
extension ExtendedCharacter: GettableByID {}
extension ExtendedCostume: GettableByID {}
extension ExtendedEvent: GettableByID {}
extension ExtendedGacha: GettableByID {}
extension ExtendedSong: GettableByID {}

// MARK: - ListGettable
public protocol ListGettable {
    static func all() async -> [Self]?
}

extension PreviewCard: ListGettable {}
extension PreviewCharacter: ListGettable {}
extension PreviewCostume: ListGettable {}
extension PreviewEvent: ListGettable {}
extension PreviewGacha: ListGettable {}
extension PreviewLoginCampaign: ListGettable {}
extension PreviewSong: ListGettable {}
extension CardWithBand: ListGettable {
    @inlinable
    public static func all() async -> [Self]? {
        await Card.allWithBand()
    }
}

// MARK: - PreviewConvertible
public protocol PreviewConvertible {
    associatedtype PreviewType
    init?(preview: PreviewType) async
}

// Decls are in DoriKit/API/[Name].swift
extension Card: PreviewConvertible {}
extension Character: PreviewConvertible {
    public typealias PreviewType = PreviewCharacter
}
extension Costume: PreviewConvertible {}
extension Event: PreviewConvertible {}
extension Gacha: PreviewConvertible {}
extension LoginCampaign: PreviewConvertible {}
extension Song: PreviewConvertible {}

// MARK: - FullTypeConvertible
public protocol FullTypeConvertible {
    associatedtype FullType
    init(_ full: FullType)
}

// Decls are in DoriKit/API/[Name].swift
extension PreviewCard: FullTypeConvertible {}
extension PreviewCharacter: FullTypeConvertible {}
extension PreviewCostume: FullTypeConvertible {}
extension PreviewEvent: FullTypeConvertible {}
extension PreviewGacha: FullTypeConvertible {}
extension PreviewLoginCampaign: FullTypeConvertible {}
extension PreviewSong: FullTypeConvertible {}

// MARK: - ExtendedTypeConvertible
public protocol ExtendedTypeConvertible {
    associatedtype ExtendedType
}

extension PreviewCard: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCard
}
extension PreviewCharacter: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCharacter
}
extension PreviewCostume: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCostume
}
extension PreviewEvent: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedEvent
}
extension PreviewGacha: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedGacha
}
extension PreviewSong: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedSong
}

extension Card: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCard
}
extension Character: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCharacter
}
extension Costume: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedCostume
}
extension Event: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedEvent
}
extension Gacha: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedGacha
}
extension Song: ExtendedTypeConvertible {
    public typealias ExtendedType = ExtendedSong
}
