//
//  Constructor.swift
//  Greatdori
//
//  Created by Mark Chan on 7/25/25.
//

// __attribute__((constructor))
@_section("__DATA,__mod_init_func")
private let __constructor: @convention(c) () -> Void = {
    Task {
        await InMemoryCache.updateAll()
    }
}
