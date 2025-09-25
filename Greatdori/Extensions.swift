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

// (In Alphabetical Order)

import Photos
import Vision
import DoriKit
import Network
import SwiftUI
import SDWebImageSwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

// MARK: Array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: Color
extension Color {
    func toHex() -> String? {
#if os(macOS)
        let nativeColor = NSColor(self).usingColorSpace(.deviceRGB)
        guard let color = nativeColor else { return nil }
#else
        let color = UIColor(self)
#endif
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
#if os(macOS)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
#else
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
#endif
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255))
        )
    }
    
    func hue(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            let newHue = (h * factor).truncatingRemainder(dividingBy: 1.0)
            return (newHue, s, b, a)
        }
    }
    
    func saturation(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, min(max(s * factor, 0), 1), b, a)
        }
    }
    
    func brightness(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, s, min(max(b * factor, 0), 1), a)
        }
    }
    
    private func modifyHSB(_ transform: (CGFloat, CGFloat, CGFloat, CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat)) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(UIColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#elseif canImport(AppKit)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(NSColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#else
        return self
#endif
    }
    
}

// MARK: Date
extension Date {
    public func corrected() -> Date? {
        if self.timeIntervalSince1970 >= 3786879600 {
            return nil
        } else {
            return self
        }
    }
}

extension DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>> {
    public enum CardSource {
        case event, gacha, loginCampaign
    }
    
    public func containsSource(from source: CardSource) -> Bool {
        for locale in DoriLocale.allCases {
            for item in Array(self.forLocale(locale) ?? Set()) {
                switch item {
                case .event:
                    if source == .event { return true }
                case .gacha:
                    if source == .gacha { return true }
                case .login:
                    if source == .loginCampaign { return true }
                default: continue
                }
            }
        }
        return false
    }
}


// MARK: Int
extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}

// MARK: Optional
extension Optional {
    var id: Self { self }
}

// MARK: View
public extension View {
    // MARK: inverseMask
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
    
    // MARK: onFrameChange
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
    
    // MARK: withSystemBackground
    @ViewBuilder
    func withSystemBackground() -> some View {
#if os(iOS)
        self
            .background(Color(.systemGroupedBackground))
#else
        self
#endif
    }
    
    // MARK: wrapIf
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

// MARK: NetworkMonitor
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

struct EmptyContainer<Content: View>: View {
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}

#if os(macOS)
/// Hi, what happened?
/// We NEED this to workaround a bug (maybe of SwiftUI?)
struct HereTheWorld<each T, V: View>: NSViewRepresentable {
    private var controller: NSViewController
    private var viewBuilder: (repeat each T) -> V
    init(arguments: (repeat each T) = (), @ViewBuilder view: @escaping (repeat each T) -> V) {
        self.controller = NSHostingController(rootView: view(repeat each arguments))
        self.viewBuilder = view
    }
    func makeNSView(context: Context) -> some NSView {
        self.controller.view
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    func updateArguments(_ arguments: (repeat each T)) {
        let newView = viewBuilder(repeat each arguments)
        controller.view = NSHostingView(rootView: newView)
    }
}
#else
/// Hi, what happened?
/// We NEED this to workaround a bug (maybe of SwiftUI?)
struct HereTheWorld<each T, V: View>: UIViewRepresentable {
    private var controller: UIViewController
    private var viewBuilder: (repeat each T) -> V
    init(arguments: (repeat each T) = (), @ViewBuilder view: @escaping (repeat each T) -> V) {
        self.controller = UIHostingController(rootView: view(repeat each arguments))
        self.viewBuilder = view
    }
    func makeUIView(context: Context) -> some UIView {
        self.controller.view
    }
    func updateUIView(_ nsView: UIViewType, context: Context) {}
    func updateArguments(_ arguments: (repeat each T)) {
        let newView = viewBuilder(repeat each arguments)
        let newUIViewController = UIHostingController(rootView: newView)
        let newUIView = newUIViewController.view
        newUIViewController.view = nil // detach
        controller.view = newUIView
    }
}
#endif

extension MutableCollection {
    @_transparent
    func swappedAt(_ i: Self.Index, _ j: Self.Index) -> Self {
        var copy = self
        copy.swapAt(i, j)
        return copy
    }
}

extension View {
    func scrollDisablesMultilingualTextPopover(_ isEnabled: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: ScrollDisableMultilingualTextPopoverModifier(isEnabled: isEnabled))
    }
}
private struct ScrollDisableMultilingualTextPopoverModifier: ViewModifier {
    var isEnabled: Bool
    @State private var disablesPopover = false
    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content
                .environment(\._multilingualTextDisablePopover, disablesPopover)
                .onScrollPhaseChange { _, newPhase in
                    disablesPopover = newPhase != .idle
                }
        } else {
            content
        }
    }
}
extension EnvironmentValues {
    @Entry var _multilingualTextDisablePopover: Bool = false
}

extension WebImage {
    func imageContextMenu(url: URL, description: LocalizedStringResource? = nil) -> some View {
        _WebImageContentMenuWrapperView(content: self, url: url, description: description)
    }
    
    private struct _WebImageContentMenuWrapperView: View {
        var content: WebImage
        var url: URL
        var description: LocalizedStringResource?
        @State private var info: _ImageContextMenuModifier.ImageInfo?
        var body: some View {
            content
                .onSuccess { _, data, _ in
                    info = .init(url: url, data: data, description: description)
                }
                .modifier(_ImageContextMenuModifier(imageInfo: info != nil ? [info!] : []))
        }
    }
}
extension View {
    func imageContextMenu(_ info: [_ImageContextMenuModifier.ImageInfo]) -> some View {
        self
            .modifier(_ImageContextMenuModifier(imageInfo: info))
    }
}
struct _ImageContextMenuModifier: ViewModifier {
    @State var imageInfo: [ImageInfo]
    @State private var isFileExporterPresented = false
    @State private var exportingImageDocument: ImageFileDocument?
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Section {
                    #if os(macOS)
                    forEachImageInfo { info in
                        Button("存储\(info.description ?? "图片")到“下载”", systemImage: "square.and.arrow.down") {
                            Task {
                                guard let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
                                try? await info.resolvedData()?.write(to: downloadsFolder.appending(path: info.url.lastPathComponent))
                            }
                        }
                    }
                    forEachImageInfo { info in
                        Button("存储\(info.description ?? "图片")为…", systemImage: "square.and.arrow.down") {
                            Task {
                                if let data = await info.resolvedData() {
                                    exportingImageDocument = .init(data: data)
                                    isFileExporterPresented = true
                                }
                            }
                        }
                    }
                    #endif
                    forEachImageInfo { info in
                        Button("添加\(info.description ?? "图片")到相册", systemImage: "photo.badge.plus") {
                            Task {
                                // FIXME: This crashes on `PHPhotoLibrary.shared().performChanges(_:)`
                                // ???: Why
                                // FIXME: Fix this problem tomorrow (Sep. 25)
                                // FIXME: #0    0x000000010142dbe0 in dispatch_async ()
                                // FIXME: #1    0x00000001b4cf0a18 in -[PHPhotoLibrary _performCancellableChanges:withInstrumentation:onExecutionContext:completionHandler:] ()
                                // FIXME: #2    0x00000001b4cf0d2c in -[PHPhotoLibrary _performCancellableChanges:withInstrumentation:completionHandler:] ()
                                // FIXME: #3    0x00000001b4cf0c20 in -[PHPhotoLibrary performChanges:completionHandler:] ()
                                // FIXME: #4    0x00000001024c9568 in closure #1 in closure #1 in closure #1 in closure #1 in closure #1 in _ImageContextMenuModifier.body(content:) at /Users/memz233/Desktop/Projects/Greatdori/Greatdori/Extensions.swift:454
                                // FIXME: #5    0x0000000199e2138c in swift::runJobInEstablishedExecutorContext ()
                                // FIXME: #6    0x0000000199e22800 in swift_job_runImpl ()
                                // FIXME: #7    0x00000001014633a4 in _dispatch_main_queue_drain.cold.5 ()
                                // FIXME: #8    0x0000000101438778 in _dispatch_main_queue_drain ()
                                // FIXME: #9    0x00000001014386b4 in _dispatch_main_queue_callback_4CF ()
                                // FIXME: #10    0x000000019b924520 in __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ ()
                                // FIXME: #11    0x000000019b8d6d14 in __CFRunLoopRun ()
                                // FIXME: #12    0x000000019b8d5c44 in _CFRunLoopRunSpecificWithOptions ()
                                // FIXME: #13    0x000000023acca498 in GSEventRunModal ()
                                // FIXME: #14    0x00000001a1250ddc in -[UIApplication _run] ()
                                // FIXME: #15    0x00000001a11f5b0c in UIApplicationMain ()
                                // FIXME: #16    0x00000001a43aa6f0 in closure #1 (Swift.UnsafeMutablePointer<Swift.Optional<Swift.UnsafeMutablePointer<Swift.Int8>>>) -> Swift.Never in SwiftUI.KitRendererCommon(Swift.AnyObject.Type) -> Swift.Never ()
                                // FIXME: #17    0x00000001a43a722c in runApp ()
                                // FIXME: #18    0x00000001a43a6d18 in static SwiftUI.App.main() -> () ()
                                // FIXME: #19    0x0000000102518fb4 in static GreatdoriApp.$main() ()
                                // FIXME: #20    0x000000010251b2a8 in main ()
                                // FIXME: #21    0x000000019894ee28 in start ()
                                if let data = await info.resolvedData() {
                                    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                                    if case .authorized = status {
                                        try? await PHPhotoLibrary.shared().performChanges {
                                            PHAssetChangeRequest.creationRequestForAsset(from: .init(data: data)!)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Section {
                    forEachImageInfo { info in
                        Button("拷贝\(info.description ?? "图片")地址", systemImage: "document.on.document") {
                            #if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(info.url.absoluteString, forType: .string)
                            #else
                            UIPasteboard.general.string = info.url.absoluteString
                            #endif
                        }
                    }
                    forEachImageInfo { info in
                        Button("拷贝\(info.description ?? "图片")", systemImage: "document.on.document") {
                            Task {
                                if let data = await info.resolvedData() {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setData(data, forType: .png)
                                    #else
                                    UIPasteboard.general.image = .init(data: data)!
                                    #endif
                                }
                            }
                        }
                    }
                    if #available(iOS 18.0, macOS 15.0, *) {
                        forEachImageInfo { info in
                            Button("拷贝\(info.description ?? "图片")主体") {
                                // FIXME: Quality is too low
                                Task {
                                    if let data = await info.resolvedData() {
                                        guard let image = CIImage(data: data) else { return }
                                        do {
                                            let request = GeneratePersonSegmentationRequest()
                                            request.qualityLevel = .accurate
                                            let observation = try await request.perform(on: image)
                                            
                                            guard let maskCGImage = try? observation.cgImage else { return }
                                            var ciMaskImage = CIImage(cgImage: maskCGImage)
                                            
                                            let originalExtent = image.extent
                                            ciMaskImage = CIImage(cgImage: maskCGImage).transformed(by: CGAffineTransform(scaleX: originalExtent.width / CGFloat(maskCGImage.width), y: originalExtent.height / CGFloat(maskCGImage.height)))
                                            
                                            let mauveBackground = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
                                                .cropped(to: image.extent)
                                            
                                            let blendFilter = CIFilter.blendWithMask()
                                            blendFilter.inputImage = image
                                            blendFilter.backgroundImage = mauveBackground
                                            blendFilter.maskImage = ciMaskImage
                                            
                                            let context = CIContext()
                                            guard let outputImage = blendFilter.outputImage,
                                                  let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
                                            
                                            #if os(macOS)
                                            let _imageData = NSMutableData()
                                            if let dest = CGImageDestinationCreateWithData(_imageData, UTType.png.identifier as CFString, 1, nil) {
                                                CGImageDestinationAddImage(dest, cgImage, nil)
                                                if CGImageDestinationFinalize(dest) {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setData(_imageData as Data, forType: .png)
                                                }
                                            }
                                            #else
                                            let _imageData = NSMutableData()
                                            if let dest = CGImageDestinationCreateWithData(_imageData, UTType.png.identifier as CFString, 1, nil) {
                                                CGImageDestinationAddImage(dest, cgImage, nil)
                                                if CGImageDestinationFinalize(dest) {
                                                    UIPasteboard.general.image = .init(data: _imageData as Data)!
                                                }
                                            }
                                            #endif
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .fileExporter(isPresented: $isFileExporterPresented, document: exportingImageDocument, contentType: .image) { _ in
                exportingImageDocument = nil
            }
            .onAppear {
                for (index, info) in imageInfo.enumerated() where info.data == nil {
                    Task {
                        imageInfo[index].data = await info.resolvedData()
                    }
                }
            }
    }
    
    @ViewBuilder
    private func forEachImageInfo<Content: View>(@ViewBuilder content: @escaping (ImageInfo) -> Content) -> some View {
        ForEach(imageInfo, id: \.self) { info in
            content(info)
        }
    }
    
    struct ImageInfo: Hashable {
        var url: URL
        var data: Data?
        var description: LocalizedStringResource?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
            hasher.combine(data)
            if let description {
                hasher.combine(String(localized: description))
            }
        }
        
        func resolvedData() async -> Data? {
            if let data {
                return data
            }
            return await withCheckedContinuation { continuation in
                DispatchQueue(label: "com.memz233.Greatdori.Resolve-Image-From-URL", qos: .userInitiated).async {
                    let data = try? Data(contentsOf: url)
                    continuation.resume(returning: data)
                }
            }
        }
    }
    struct ImageFileDocument: FileDocument {
        static let readableContentTypes: [UTType] = [.image]
        
        var imageData: Data
        
        init(data imageData: Data) {
            self.imageData = imageData
        }
        init(configuration: ReadConfiguration) throws {
            if let data = configuration.file.regularFileContents {
                imageData = data
            } else {
                throw CocoaError(.fileReadUnknown)
            }
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            .init(regularFileWithContents: imageData)
        }
    }
}
