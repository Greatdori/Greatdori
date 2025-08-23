//===---*- Greatdori! -*---------------------------------------------------===//
//
// SearchView.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


struct FilterView: View {
    @Binding var filter: DoriFrontend.Filter
    var includingKeys: [DoriFrontend.Filter.Key]
    var body: some View {
        Form {
            Section(content: {
                //MARK: Attribute
                if includingKeys.contains(.attribute) {
                    ListItemView(title: {
                        Text("Filter.key.attribute")
                            .bold()
                            .onTapGesture(count: 2, perform: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.attribute.isEmpty {
                                        filter.attribute = Set(DoriAPI.Attribute.allCases)
                                    } else {
                                        filter.attribute.removeAll()
                                    }
                                }
                            })
                    }, value: {
                        HStack {
                            ForEach(DoriAPI.Attribute.allCases, id: \.self) { attribute in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        if filter.attribute.contains(attribute) {
                                            filter.attribute.remove(attribute)
                                        } else {
                                            filter.attribute.insert(attribute)
                                        }
                                    }
                                }, label: {
                                    ZStack {
                                            Circle()
                                                .stroke(.blue, lineWidth: 2)
                                            //                                            .foregroundStyle(.accent)
                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                .opacity(filter.attribute.contains(attribute) ? 1 : 0)
                                            //                                            .op
                                            //                                            .border(Circle)
                                            //                                            .border(Color.accentColor, width: 2)
                                        WebImage(url: attribute.iconImageURL)
//                                            .stroke(.blue, lineWidth: 2)
                                            .resizable()
//                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                            .scaleEffect(0.9)
//                                            .gray
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                            
//                            Button/
                        }
                    })
                }
                //MARK: Character
                if includingKeys.contains(.character) {
                    ListItemView(title: {
                        Text("Filter.key.character")
                            .bold()
                            .onTapGesture(count: 2, perform: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.attribute.isEmpty {
                                        filter.attribute = Set(DoriAPI.Attribute.allCases)
                                    } else {
                                        filter.attribute.removeAll()
                                    }
                                }
                            })
                    }, value: {
                        HStack {
                            ForEach(DoriAPI.Attribute.allCases, id: \.self) { attribute in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        if filter.attribute.contains(attribute) {
                                            filter.attribute.remove(attribute)
                                        } else {
                                            filter.attribute.insert(attribute)
                                        }
                                    }
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .stroke(.blue, lineWidth: 2)
                                        //                                            .foregroundStyle(.accent)
                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                            .opacity(filter.attribute.contains(attribute) ? 1 : 0)
                                        //                                            .op
                                        //                                            .border(Circle)
                                        //                                            .border(Color.accentColor, width: 2)
                                        WebImage(url: attribute.iconImageURL)
                                        //                                            .stroke(.blue, lineWidth: 2)
                                            .resizable()
                                        //                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                            .scaleEffect(0.9)
                                        //                                            .gray
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                            
                            //                            Button/
                        }
                    })
                }
            }, footer: {
                Text("Filter.footer")
            })
            
        }
//        .gridColumnAlignment(.trailing, for: 0)
//        .gridColumnAlignment(.leading, for: 1)
//        .gridCellAnchor(.)
    }
}

/*
import OSLog
import SwiftUI
import DoriKit

struct FilterView: View {
    @Binding private var filter: DoriFrontend.Filter
    private var includingKeys: Set<DoriFrontend.Filter.Key>
    private var searchView: AnyView?
    
    init(
        filter: Binding<DoriFrontend.Filter>,
        includingKeys: Set<DoriFrontend.Filter.Key>
    ) {
        self._filter = filter
        self.includingKeys = includingKeys
    }
    init<V: View>(
        filter: Binding<DoriFrontend.Filter>,
        includingKeys: Set<DoriFrontend.Filter.Key>,
        @ViewBuilder searchView: () -> V
    ) {
        self._filter = filter
        self.includingKeys = includingKeys
        self.searchView = AnyView(searchView())
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isSearchPresented = false
    
    var body: some View {
        NavigationStack {
            List {
                if filter.isFiltered {
                    Button("清除过滤", systemImage: "arrow.counterclockwise") {
                        filter.clearAll()
                    }
                }
                Section {
                    let sortedKeys = includingKeys.sorted()
                    ForEach(sortedKeys) { key in
                        switch key.selector.type {
                        case .single:
                            SingleSelector(filter: $filter, key: key)
                        case .multiple:
                            MultipleSelector(filter: $filter, key: key)
                        }
                    }
                }
            }
            .animation(.default, value: filter.isFiltered)
            .navigationTitle("过滤")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isSearchPresented) {
                dismiss()
            } content: {
                if let searchView {
                    searchView
                }
            }
            .toolbar {
                if searchView != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isSearchPresented = true
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                }
            }
        }
    }
    
    private struct SingleSelector: View {
        @Binding var filter: DoriFrontend.Filter
        var key: DoriFrontend.Filter.Key
        var body: some View {
            NavigationLink {
                List {
                    if key == .skill {
                        Button(action: {
                            filter[key] = nil as Optional<DoriFrontend.Filter.Skill>
                        }, label: {
                            HStack {
                                Text("任意")
                                Spacer()
                                if (filter[key].base as! Optional<DoriFrontend.Filter.Skill>) == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        })
                    } else if key == .sort {
                        let sort = filter[key] as! DoriFrontend.Filter.Sort
                        Section {
                            Button(action: {
                                var sort = sort
                                sort.direction = .ascending
                                filter[key] = sort
                            }, label: {
                                HStack {
                                    Text("升序")
                                    Spacer()
                                    if sort.direction == .ascending {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accent)
                                    }
                                }
                            })
                            Button(action: {
                                var sort = sort
                                sort.direction = .descending
                                filter[key] = sort
                            }, label: {
                                HStack {
                                    Text("降序")
                                    Spacer()
                                    if sort.direction == .descending {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accent)
                                    }
                                }
                            })
                        } header: {
                            Text("顺序")
                        }
                    }
                    ForEach(key.selector.items, id: \.self) { item in
                        Button(action: {
                            filter[key] = item.item.value
                        }, label: {
                            HStack {
                                Text(item.text)
                                Spacer()
                                if (filter[key].base as! any DoriFrontend.Filter._Selectable).isEqual(to: item.item.value.base as! any DoriFrontend.Filter._Selectable) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        })
                    }
                }
                .navigationTitle(key.localizedString)
            } label: {
                VStack(alignment: .leading) {
                    Text(key.localizedString)
                    if let filterItem = filter[key] as? any DoriFrontend.Filter._Selectable {
                        Text(filterItem.selectorText)
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .opacity(0.6)
                    }
                }
            }
        }
    }
    private struct MultipleSelector: View {
        @Binding var filter: DoriFrontend.Filter
        var key: DoriFrontend.Filter.Key
        var body: some View {
            NavigationLink {
                List {
                    ForEach(key.selector.items, id: \.self) { item in
                        Button(action: {
                            if var filterSet = filter[key] as? Set<AnyHashable> {
                                if filterSet.contains(item.item.value) {
                                    filterSet.remove(item.item.value)
                                } else {
                                    filterSet.insert(item.item.value)
                                }
                                filter[key] = filterSet
                            } else {
                                os_log(.fault, "\(type(of: filter[key])) is not Set")
                            }
                        }, label: {
                            HStack {
                                Text(item.text)
                                Spacer()
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    Image(systemName: filterSet.contains(item.item.value) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(.accent)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        })
                    }
                }
                .navigationTitle(key.localizedString)
                .toolbar {
                    if let filterSet = filter[key] as? Set<AnyHashable> {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                if filterSet == Set(key.selector.items.map { $0.item.value }) {
                                    // Currently selected all, we unselect all
                                    var filterSet = filterSet
                                    filterSet.removeAll()
                                    filter[key] = filterSet
                                } else {
                                    filter[key] = Set(key.selector.items.map { $0.item.value })
                                }
                            }, label: {
                                Image(systemName: filterSet == Set(key.selector.items.map { $0.item.value }) ? "checklist.checked" : (filterSet.isEmpty ? "checklist.unchecked" : "checklist"))
                            })
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text(key.localizedString)
                    if let filterSet = filter[key] as? Set<AnyHashable> {
                        Text(filterSet.map { ($0 as! (any DoriFrontend.Filter._Selectable)).selectorText }.sorted().joined(separator: ", "))
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .opacity(0.6)
                    }
                }
            }
        }
    }
}
*/
