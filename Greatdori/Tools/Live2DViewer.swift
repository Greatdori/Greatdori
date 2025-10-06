//===---*- Greatdori! -*---------------------------------------------------===//
//
// Live2DViewer.swift
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
import SwiftUI

struct Live2DViewerView: View {
    @State var itemType: [LocalizedStringKey] = ["Tools.live2d-viewer.type.card", "Tools.live2d-viewer.type.costume", "Tools.live2d-viewer.type.seasonal-costume"]
    @State var selectedItemTypeIndex = 0
    @State var id: Int = 1
    @State var costume: Costume?
    @State var informationIsLoading = true
    @State var seasonalCostumes: [PreviewCostume]?
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox {
                        VStack {
                            ListItemView(title: {
                                Text("Tools.live2d-viewer.type")
                                    .bold()
                            }, value: {
                                Picker("", selection: $selectedItemTypeIndex, content: {
                                    ForEach(itemType.indices, id: \.self) { itemIndex in
                                        Text(itemType[itemIndex])
                                            .tag(itemIndex)
                                    }
                                })
                                .labelsHidden()
                            })
                            Divider()
                            ListItemView(title: {
                                Text("Tools.live2d-viewer.id")
                                    .bold()
                            }, value: {
                                TextField("Tools.live2d-viewer.id", value: $id, format: .number)
                            })
                        }
                    }
                    DetailSectionsSpacer()
                    if informationIsLoading {
                        CustomGroupBox {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    } else {
                        if let costume, [0, 1].contains(selectedItemTypeIndex) {
                            NavigationLink(destination: {
                                
                            }, label: {
                                CostumeInfo(costume)
                            })
                            .buttonStyle(.plain)
                        } else if let seasonalCostumes, !seasonalCostumes.isEmpty {
                            ForEach(seasonalCostumes.indices, id: \.self) { index in
                                NavigationLink(destination: {
                                    
                                }, label: {
                                    CostumeInfo(seasonalCostumes[index])
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            CustomGroupBox {
                                HStack {
                                    Spacer()
                                    Text("Tools.live2d-viewer.unavailable")
                                        .bold()
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 600)
                Spacer(minLength: 0)
            }
        }
        .navigationTitle("Tools.live2d-viewer")
        .onAppear {
            updateDestination()
        }
        .onChange(of: id) {
            updateDestination()
        }
    }
    func updateDestination() {
        informationIsLoading = true
        costume = nil
        if selectedItemTypeIndex == 0 {
            Task {
                let card = await Card(id: id)
                if let card {
                    costume = await Costume(id: card.costumeID)
                }
                informationIsLoading = false
            }
        } else if selectedItemTypeIndex == 1 {
            Task {
                costume = await Costume(id: id)
                informationIsLoading = false
            }
        } else if selectedItemTypeIndex == 2 {
            Task {
                let character = await ExtendedCharacter(id: id)
                seasonalCostumes = character?.costumes
                informationIsLoading = false
            }
        }
    }
}
