//
//  FilterView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/24/25.
//

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
