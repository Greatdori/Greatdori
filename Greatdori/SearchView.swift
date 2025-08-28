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

let flowLayoutDefaultVerticalSpacing: CGFloat = 3
let flowLayoutDefaultHorizontalSpacing: CGFloat = 3
let capsuleDefaultCornerRadius: CGFloat = isMACOS ? 6 : 10

struct FilterView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var filter: DoriFrontend.Filter
    var includingKeys: [DoriFrontend.Filter.Key]
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key? = nil
    
    var body: some View {
        Form {
            Section(content: {
                //MARK: Attribute
                if includingKeys.contains(.attribute) {
                    ListItemViewSimplified(title: {
                        FilterTitleView(filter: $filter, titleName: "Filter.key.attribute", titleKey: .attribute)
                    }, value: {
                        HStack {
                            ForEach(DoriFrontend.Filter.Attribute.allCases, id: \.self) { item in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        if filter.attribute.contains(item) {
                                            filter.attribute.remove(item)
                                        } else {
                                            filter.attribute.insert(item)
                                        }
                                    }
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.accent, lineWidth: 2)
                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .opacity(filter.attribute.contains(item) ? 1 : 0)
                                        WebImage(url: item.iconImageURL)
                                            .antialiased(true)
                                            .resizable()
                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .scaleEffect(0.9)
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    })
                }
                
                //MARK: Character
                if includingKeys.contains(.character) {
                    ListItemViewSimplified(title: {
                        FilterTitleView(filter: $filter, titleName: "Filter.key.character", titleKey: .character)
                    }, value: {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: filterItemHeight))]/*, spacing: 3*/) {
                            ForEach(DoriFrontend.Filter.Character.allCases, id: \.self) { item in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        if filter.character.contains(item) {
                                            filter.character.remove(item)
                                        } else {
                                            filter.character.insert(item)
                                        }
                                    }
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.accent, lineWidth: 2)
                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .opacity(filter.character.contains(item) ? 1 : 0)
                                        WebImage(url: item.selectorImageURL)
                                            .antialiased(true)
                                            .resizable()
                                            .frame(width: filterItemHeight, height: filterItemHeight)
                                            .scaleEffect(0.9)
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    })
                }
                
                //MARK: Server
                if includingKeys.contains(.server) {
                    ListItemViewSimplified(title: {
                        FilterTitleView(filter: $filter, titleName: "Filter.key.server", titleKey: .server)
                    }, value: {
                        FlowLayout(items: DoriFrontend.Filter.Server.allCases, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.server.contains(item) {
                                        filter.server.remove(item)
                                    } else {
                                        filter.server.insert(item)
                                    }
                                }
                            }, label: {
                                FilterSelectionCapsuleView(isActive: filter.server.contains(item), content: {
                                    Text(item.rawValue.uppercased())
                                })
                            })
                            .buttonStyle(.plain)
                            
                        }
                    })
                }
                
                //MARK: TimelineStatus
                if includingKeys.contains(.timelineStatus) {
                    ListItemViewSimplified(title: {
                        FilterTitleView(filter: $filter, titleName: "Filter.key.timelineStatus", titleKey: .timelineStatus)
                    }, value: {
                        FlowLayout(items: DoriFrontend.Filter.TimelineStatus.allCases, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.timelineStatus.contains(item) {
                                        filter.timelineStatus.remove(item)
                                    } else {
                                        filter.timelineStatus.insert(item)
                                    }
                                }
                            }, label: {
                                FilterSelectionCapsuleView(isActive: filter.timelineStatus.contains(item), content: {
                                    Text(item.selectorText)
                                })
                            })
                            .buttonStyle(.plain)
                        }
                    })
                }
                
                //MARK: EventType
                if includingKeys.contains(.eventType) {
                    ListItemViewSimplified(title: {
                        FilterTitleView(filter: $filter, titleName: "Filter.key.eventType", titleKey: .eventType)
                            .bold()
                            .onTapGesture(count: 2, perform: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.eventType.count < DoriFrontend.Filter.EventType.allCases.count {
                                        filter.eventType = Set(DoriFrontend.Filter.EventType.allCases)
                                    } else {
                                        filter.eventType.removeAll()
                                    }
                                }
                            })
                    }, value: {
                        FlowLayout(items: DoriFrontend.Filter.EventType.allCases, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.eventType.contains(item) {
                                        filter.eventType.remove(item)
                                    } else {
                                        filter.eventType.insert(item)
                                    }
                                }
                            }, label: {
                                FilterSelectionCapsuleView(isActive: filter.eventType.contains(item), content: {
                                    Text(item.selectorText)
                                })
                            })
                            .buttonStyle(.plain)
                        }
                    })
                }
            }, header: {
                VStack(alignment: .leading) {
                    if sizeClass == .compact {
                        Color.clear.frame(height: 10)
                    }
                    Text("Filter")
                }
            }, footer: {
                VStack(alignment: .leading) {
                    Text("Filter.footer")
                }
            })
            
            Section {
                Button(action: {
                    filter.clearAll()
                }, label: {
                    Text("Filter.clear-all")
                })
            }
        }
    }
    struct FilterSelectionCapsuleView<Content: View>: View {
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
                    .foregroundStyle(isActive ? Color.accent : Color.secondary)
                    .frame(width: textWidth, height: filterItemHeight)
                content
                    .foregroundStyle(isActive ? .white : .primary)
                    .frame(height: filterItemHeight)
                //                    .scaleEffect(0.9)
                    .padding(.horizontal, isMACOS ? 10 : nil)
                    .onFrameChange(perform: { geometry in
                        textWidth = geometry.size.width
                    })
                //FIXME: Text padding to much in macOS
            }
        }
    }
    struct FilterTitleView: View {
        @Binding var filter: DoriFrontend.Filter
        //        @Binding var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key?
        //        @State var showSelectAllTips = false
        //        @State var showDeselectAllTips = false
        //        @State private var timer: Timer? = nil
        let titleName: LocalizedStringResource
        let titleKey: DoriFrontend.Filter.Key
        var body: some View {
            HStack {
                ZStack(alignment: .leading) {
                    Text(titleName)
                        .bold()
                }
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        let allCases = titleKey.selector.items.map { $0.item.value }
                        if let filterSet = filter[titleKey] as? Set<AnyHashable> {
                            if filterSet.count < allCases.count {
                                filter[titleKey] = Set(allCases)
                            } else {
                                if var filterSet = filter[titleKey] as? Set<AnyHashable> {
                                    filterSet.removeAll()
                                    filter[titleKey] = filterSet
                                }
                            }
                        }
                    }
                }, label: {
                    Group {
                        let allCases = titleKey.selector.items.map { $0.item.value }
                        if let filterSet = filter[titleKey] as? Set<AnyHashable> {
                            if filterSet.count < allCases.count {
                                Text("Filter.select-all")
                            } else {
                                Text("Filter.deselect-all")
                            }
                        }
                    }
                    .foregroundStyle(.secondary)
                    //                    .font(.headline)
                    .font(.subheadline)
                })
                .buttonStyle(.plain)
            }
            //            .onChange(of: displayingTipIndex) { oldValue, newValue in
            //                timer?.invalidate()
            //                if newValue != 0 {
            //                    timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            //                        displayingTipIndex = 0
            //                        timer = nil
            //                    }
            //                }
            //            }
        }
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
