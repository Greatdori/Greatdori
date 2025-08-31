//===---*- Greatdori! -*---------------------------------------------------===//
//
// FilterView.swift
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

let flowLayoutDefaultVerticalSpacing: CGFloat = 3
let flowLayoutDefaultHorizontalSpacing: CGFloat = 3
let capsuleDefaultCornerRadius: CGFloat = isMACOS ? 6 : 10

struct FilterView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var filter: DoriFrontend.Filter
    var includingKeys: Set<DoriFrontend.Filter.Key>
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key? = nil
    
    var body: some View {
        Form {
            Section(content: {
                // `FilterItemView` will determine whether it should be displayed or not by itself.
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .band)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .attribute)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .rarity)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .character)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .server)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .timelineStatus)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .released)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .eventType)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .gachaType)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .cardType)
                FilterItemView(filter: $filter, allKeys: includingKeys, key: .skill)
            }, header: {
                VStack(alignment: .leading) {
                    if sizeClass == .compact {
                        Color.clear.frame(height: 10)
                    }
                    Text("Filter")
                }
            })
            
            Section {
                Button(action: {
                    filter.clearAll()
                }, label: {
                    Text("Filter.clear-all")
                })
                .disabled(!filter.isFiltered)
//                .buttonStyle(.borderless)
            }
        }
    }
}


struct FilterItemView: View {
    @Binding var filter: DoriFrontend.Filter
    //    let titleName: LocalizedStringResource
    let allKeys: Set<DoriFrontend.Filter.Key>
    let key: DoriFrontend.Filter.Key
    
    @State var isHovering = false
    @State var characterRequiresMatchAll = false
    var body: some View {
        if allKeys.contains(key) {
            VStack(alignment: .leading) {
                if key.selector.type == .multiple {
                    //MARK: Title Part
                    HStack {
                        VStack {
                            Text(key.localizedString)
                                .bold()
                        }
                        if key == .character && allKeys.contains(.characterRequiresMatchAll) {
                            Menu(content: {
                                Picker(selection: $characterRequiresMatchAll, content: {
                                    Text("Filter.match-all.any-selected")
                                        .tag(false)
                                    Text("Filter.match-all.all-selected")
                                        .tag(true)
                                }, label: {
                                    Text("")
                                })
                                .pickerStyle(.inline)
                                .labelsHidden()
                                .multilineTextAlignment(.leading)
                            }, label: {
                                Text(getAttributedStringForMatchAll(isAllSelected: characterRequiresMatchAll))
                            })
                            .menuIndicator(.hidden)
                            .menuStyle(.borderlessButton)
                            .buttonStyle(.plain)
                            .onChange(of: characterRequiresMatchAll, {
                                filter.characterRequiresMatchAll = characterRequiresMatchAll
                            })
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                let allCases = key.selector.items.map { $0.item.value }
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    if filterSet.count == 0 {
                                        filter[key] = Set(allCases)
                                        if key == .band && allKeys.contains(.bandMatchesOthers) {
                                            filter.bandMatchesOthers = true
                                        }
                                    } else {
                                        if var filterSet = filter[key] as? Set<AnyHashable> {
                                            filterSet.removeAll()
                                            filter[key] = filterSet
                                            if key == .band && allKeys.contains(.bandMatchesOthers) {
                                                filter.bandMatchesOthers = false
                                            }
                                        }
                                    }
                                }
                            }
                        }, label: {
                            Group {
                                let allCases = key.selector.items.map { $0.item.value }
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    if key == .band && allKeys.contains(.bandMatchesOthers) {
                                        CompactToggle(isLit: (filterSet.count == allCases.count && filter.bandMatchesOthers) ? true : (filterSet.count == 0 && !filter.bandMatchesOthers ? false : nil))
                                    } else {
                                        CompactToggle(isLit: (filterSet.count == allCases.count) ? true : (filterSet.count == 0 ? false : nil))
                                    }
                                }
                            }
                            .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                    //MARK: Picker Part
                    // Multiple Selection
                    if key.selector.items.first?.imageURL != nil && key != .server { // `.server` is not expected to use flags in Greatdori!.
                                                                                     // Image Selection
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: filterItemHeight))]/*, spacing: 3*/) {
                            ForEach((key == .band && allKeys.contains(.bandMatchesOthers)) ? key.selector.items + [DoriFrontend.Filter.Key.bandMatchesOthers.selector.items.first!] : key.selector.items, id: \.self) { item in
                                Group {
                                    if item != DoriFrontend.Filter.Key.bandMatchesOthers.selector.items.first! {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.05)) {
                                                if var filterSet = filter[key] as? Set<AnyHashable> {
                                                    if filterSet.contains(item.item.value) {
                                                        filterSet.remove(item.item.value)
                                                    } else {
                                                        filterSet.insert(item.item.value)
                                                    }
                                                    filter[key] = filterSet
                                                }
                                            }
                                        }, label: {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.accent, lineWidth: 2)
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .opacity(((filter[key] as? Set<AnyHashable>)?.contains(item.item.value) == true) ? 1 : 0)
                                                WebImage(url: item.imageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .scaleEffect([DoriFrontend.Filter.Key.attribute, DoriFrontend.Filter.Key.character].contains(key) ? 0.9 : 0.75)
                                            }
                                            .contentShape(Circle())
                                        })
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.05)) {
                                                filter.bandMatchesOthers.toggle()
                                            }
                                        }, label: {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.accent, lineWidth: 2)
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .opacity(filter.bandMatchesOthers ? 1 : 0)
                                                if item.imageURL != nil {
                                                    WebImage(url: item.imageURL)
                                                        .antialiased(true)
                                                        .resizable()
                                                        .frame(width: filterItemHeight, height: filterItemHeight)
                                                        .scaleEffect([DoriFrontend.Filter.Key.attribute, DoriFrontend.Filter.Key.character].contains(key) ? 0.9 : 0.75)
                                                } else {
                                                    Image(systemName: "person.fill")
                                                        .frame(width: filterItemHeight*0.95, height: filterItemHeight*0.95)
                                                }
                                            }
                                            .contentShape(Circle())
                                        })
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityValue(Text(item.text))
                            }
                        }
                    } else {
                        FlowLayout(items: key.selector.items, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                            Button(action: {
                                //                                withAnimation(.easeInOut(duration: 0.05)) {
                                if var filterSet = filter[key] as? Set<AnyHashable> {
                                    if filterSet.contains(item.item.value) {
                                        filterSet.remove(item.item.value)
                                    } else {
                                        filterSet.insert(item.item.value)
                                    }
                                    filter[key] = filterSet
                                }
                                //                                }
                            }, label: {
                                FilterSelectionCapsuleView(isActive: ((filter[key] as? Set<AnyHashable>)?.contains(item.item.value) == true), content: {
                                    Text(item.text)
                                })
                                //                                .animation(.easeInOut(duration: 0.05))
                            })
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Single Selection
                    Picker(selection: $filter[key], content: {
                        ForEach(key.selector.items, id: \.self) { item in
                            Text(item.text)
                                .tag(item.item.value)
                        }
                    }, label: {
                        VStack {
                            Text(key.localizedString)
                                .bold()
                        }
                    })
                }
            }
            .onHover(perform: { isHovered in
                isHovering = isHovered
            })
        }
    }
    struct FilterSelectionCapsuleView<Content: View>: View {
        @Environment(\.horizontalSizeClass) var sizeClass
        var isActive: Bool
        let content: Content
        let cornerRadius: CGFloat = capsuleDefaultCornerRadius
        @State var textWidth: CGFloat = 0
        
        init(isActive: Bool, @ViewBuilder content: () -> Content) {
            self.isActive = isActive
            self.content = content()
        }
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(isActive ? Color.accent : getTertiaryLabelColor())
                    .frame(width: textWidth, height: filterItemHeight)
                content
                    .foregroundStyle(isActive ? .white : Color.gray)
                    .frame(height: filterItemHeight)
                    .padding(.horizontal, isMACOS ? 10 : nil)
                    .onFrameChange(perform: { geometry in
                        textWidth = geometry.size.width
                    })
                //FIXME: Text padding to much in macOS
            }
            .animation(.easeInOut(duration: 0.05), value: isActive)
        }
    }
    func getAttributedStringForMatchAll(isAllSelected: Bool = false) -> AttributedString {
        var attrString = AttributedString(String(localized: isAllSelected ? "Filter.match-all.all-selected" : "Filter.match-all.any-selected"))
        attrString.font = .system(.body, weight: .thin)
        attrString.foregroundColor = .secondary
        return attrString
    }
}



// You may ask why this View looks so weird and has so many warnings.
// It becuase it's generated by ChatGPT and it suprisingly works.
// --@ThreeManager785
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Hashable {
    let items: Data
    let verticalSpacing: CGFloat
    let horizontalSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .padding(.vertical, verticalSpacing)
                    .padding(.horizontal, horizontalSpacing)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geo.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0 // reset
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0 // reset
                        }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    self.totalHeight = geo.size.height
                }
                return Color.clear
            }
        )
        //        .offset(x: -horizontalSpacing)wo x
    }
}
