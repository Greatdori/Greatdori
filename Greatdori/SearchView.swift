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

struct FilterView: View {
    @Binding var filter: DoriFrontend.Filter
    var includingKeys: [DoriFrontend.Filter.Key]
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key? = nil
    @State private var timer: Timer? = nil
    var body: some View {
        Form {
            Section(content: {
                //MARK: Attribute
                if includingKeys.contains(.attribute) {
                    ListItemView(title: {
                        ZStack(alignment: .leading) {
                            Text("Filter.key.attribute")
                                .opacity(theItemThatShowsSelectAllTips == .attribute ? 0 : 1)
                                .bold()
                            Text(lastSelectAllActionIsDeselect ? "Filter.double-tap-tips.unselected" : "Filter.double-tap-tips.selected")
                                .opacity(theItemThatShowsSelectAllTips == .attribute ? 1 : 0)
                                .fontWeight(.light)
                        }
                        .animation(.easeIn(duration: 0.2), value: theItemThatShowsSelectAllTips)
//                        .bold()
                        .onTapGesture(count: 2, perform: {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                if filter.attribute.count < DoriFrontend.Filter.Attribute.allCases.count {
                                    filter.attribute = Set(DoriFrontend.Filter.Attribute.allCases)
                                    lastSelectAllActionIsDeselect = false
                                } else {
                                    lastSelectAllActionIsDeselect = true
                                    filter.attribute.removeAll()
                                }
                            }
                            theItemThatShowsSelectAllTips = .attribute
                        })
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
                    ListItemView(title: {
                        HStack {
                            Text("Filter.key.character")
                                .bold()
                                .onTapGesture(count: 2, perform: {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        if filter.character.count < DoriFrontend.Filter.Character.allCases.count {
                                            filter.character = Set(DoriFrontend.Filter.Character.allCases)
                                        } else {
                                            filter.character.removeAll()
                                        }
                                    }
                                })
                            Spacer()
                            //FIXME: Keep the comment below
//                            Text("Filter.key.character.bool-operator-hint.or")
//                                .onTapGesture {
////                                    filter.
//                                }
                        }
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
                    }, displayMode: .expandedOnly)
                }
                
                //MARK: Server
                if includingKeys.contains(.server) {
                    ListItemView(title: {
                        Text("Filter.key.server")
                            .bold()
                            .onTapGesture(count: 2, perform: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.server.count < DoriFrontend.Filter.Server.allCases.count {
                                        filter.server = Set(DoriFrontend.Filter.Server.allCases)
                                    } else {
                                        filter.server.removeAll()
                                    }
                                }
                            })
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
                    ListItemView(title: {
                        Text("Filter.key.timelineStatus")
                            .bold()
                            .onTapGesture(count: 2, perform: {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    if filter.timelineStatus.count < DoriFrontend.Filter.TimelineStatus.allCases.count {
                                        filter.timelineStatus = Set(DoriFrontend.Filter.TimelineStatus.allCases)
                                    } else {
                                        filter.timelineStatus.removeAll()
                                    }
                                }
                            })
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
                    ListItemView(title: {
                        Text("Filter.key.eventType")
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
                    Color.clear.frame(height: 10)
                    Text("Filter")
                }
            }, footer: {
                VStack(alignment: .leading) {
                    Text("Filter.footer")
                }
            })
            .onChange(of: theItemThatShowsSelectAllTips) { newValue in
                // 先取消旧的 Timer
                timer?.invalidate()
                
                if newValue != nil {
                    // 新建 Timer
                    timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        theItemThatShowsSelectAllTips = nil
                        timer = nil
                    }
                }
            }
            
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
        let cornerRadius: CGFloat = 10
        @State var textWidth: CGFloat = 0
        
        init(isActive: Bool, @ViewBuilder content: () -> Content) {
            self.isActive = isActive
            self.content = content()
        }
        var body: some View {
            ZStack {
//                Capsule()
//                    .stroke(Color.accent, lineWidth: 2)
//                    .frame(width: textWidth, height: filterItemHeight)
//                Capsule()
//                    .foregroundStyle(Color.accent.opacity(isActive ? 1 : 0.3))
//                    .frame(width: textWidth, height: filterItemHeight)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(isActive ? Color.accent : Color.secondary)
                    .frame(width: textWidth, height: filterItemHeight)
                content
                    .frame(height: filterItemHeight)
                //                    .scaleEffect(0.9)
                    .padding(.horizontal)
                    .onFrameChange(perform: { geometry in
                        textWidth = geometry.size.width
                    })
                //                    .border(.green)
            }
        }
    }
    struct FilterTitleView: View {
        @Binding var filter: DoriFrontend.Filter
        @Binding var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key?
        @Binding var lastSelectAllActionIsDeselect: Bool
        let titleName: LocalizedStringResource
        let titleKey: DoriFrontend.Filter.Key
        var body: some View {
            ZStack(alignment: .leading) {
                Text(titleName)
                    .opacity(theItemThatShowsSelectAllTips == titleKey ? 0 : 1)
                    .bold()
                Text(lastSelectAllActionIsDeselect ? "Filter.double-tap-tips.unselected" : "Filter.double-tap-tips.selected")
                    .opacity(theItemThatShowsSelectAllTips == titleKey ? 1 : 0)
                    .fontWeight(.light)
            }
            .animation(.easeIn(duration: 0.2), value: theItemThatShowsSelectAllTips)
            .onTapGesture(count: 2, perform: {
                //FIXME: [250823] Cannot access `filter` via `titleKey`.
//                withAnimation(.easeInOut(duration: 0.05)) {
////                    filter.
//                    if filter[titleKey].count < titleKey.allCases.count {
//                        filter.attribute = Set(DoriFrontend.Filter.Attribute.allCases)
//                        lastSelectAllActionIsDeselect = false
//                    } else {
//                        lastSelectAllActionIsDeselect = true
//                        filter.attribute.removeAll()
//                    }
//                }
                theItemThatShowsSelectAllTips = .attribute
            })
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
