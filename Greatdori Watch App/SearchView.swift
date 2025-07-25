//
//  SearchView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/25/25.
//

import SwiftUI
import DoriKit

struct SearchView<T: DoriFrontend.Searchable>: View {
    var items: [T]
    @Binding var text: String
    var completion: ([T]) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section {
                TextField("搜索...", text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        let _startTime = CFAbsoluteTimeGetCurrent()
                        completion(items.search(for: text))
                        print(CFAbsoluteTimeGetCurrent() - _startTime)
                    }
            }
        }
    }
}
