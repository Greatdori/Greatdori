//===---*- Greatdori! -*---------------------------------------------------===//
//
// Extensions.swift
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

// (In Alphabetic Order)

import DoriKit
import Network
import SwiftUI

//MARK: Array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

//MARK: Int
extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}

//MARK: Optional
extension Optional {
    var id: Self { self }
}

//MARK: View
public extension View {
    //MARK: inverseMask
    public func inverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask,
        alignment: Alignment = .center
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
    
    //MARK: onFrameChange
    /// Performs action when frame of attached view changes.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         MyView()
    ///             .onFrameChange { geometry in
    ///                 print(geometry)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A view that triggers `action` when its frame changes.
    func onFrameChange(perform action: @escaping (_ geometry: GeometryProxy) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        action(geometry)
                    }
                    .onChange(of: geometry.size) {
                        action(geometry)
                    }
            }
        )
    }
    
    //MARK: withSystemBackground
    @ViewBuilder
    func withSystemBackground() -> some View {
#if os(iOS)
        self
            .background(Color(.systemGroupedBackground))
#else
        self
#endif
    }
    
    //MARK: wrapIf
    /// Wraps a view into a specific container when `condition` is `true`.
    ///
    /// Use this modifier to conditionally wrap a view into a container.
    /// ```swift
    /// struct MyView: View {
    ///     @State private var navigatable = false
    ///     var body: some View {
    ///         List {
    ///             Button("Switch Navigatability") {
    ///                 navigatable.toggle()
    ///             }
    ///             NavigationLink("Navigate", destination: { /* some view... */ })
    ///         }
    ///         .wrapIf(navigatable) { content in
    ///             NavigationStack { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the specific container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    /// - Returns: A view that wrapped into the specific container when `condition` is `true`.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            self
        }
    }
    
    /// Wraps a view into a specific container when `condition` is `true`,
    /// and wraps it into the other container when `condition` is `false`.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @State private var appearance = false
    ///     var body: some View {
    ///         Button("Switch Appearance") {
    ///             appearance.toggle()
    ///         }
    ///         .wrapIf(appearance) { content in
    ///             VStack { content }
    ///         } else: { content in
    ///             List { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the `true` container or the `false` container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    ///   - elseContainer: Wrapping container which makes sence when `condition` is `false`.
    /// - Returns: A view that wrapped into the `true` container when `condition` is `true`, vice versa.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View, @ViewBuilder else elseContainer: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            elseContainer(self)
        }
    }
}

//MARK: NetworkMonitor
final class NetworkMonitor: Sendable {
    @MainActor static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @MainActor private(set) var isConnected: Bool = false
    @MainActor private(set) var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }
}







