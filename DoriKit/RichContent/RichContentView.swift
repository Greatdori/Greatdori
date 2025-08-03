//
//  RichContentView.swift
//  Greatdori
//
//  Created by Mark Chan on 8/2/25.
//

import SwiftUI
import Foundation

public struct RichContentView: View {
    private var content: RichContentGroup
    
    public init(_ content: RichContentGroup) {
        self.content = content
    }
    
    internal var environment = RichContentEnvironment()
    
    public var body: some View {
        VStack(alignment: .leading) {
            let viewGroup = content._makeViewGroup(in: environment)
            ForEach(0..<viewGroup.count, id: \.self) { i in
                viewGroup[i].makeView()
            }
        }
    }
}

extension RichContentView {
    public func richEmojiFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> RichContentView {
        var mutating = self
        if let width {
            mutating.environment.emojiFrame.width = width
        }
        if let height {
            mutating.environment.emojiFrame.height = height
        }
        return mutating
    }
}
