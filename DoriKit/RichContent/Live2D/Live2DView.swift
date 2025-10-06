//===---*- Greatdori! -*---------------------------------------------------===//
//
// Live2DView.swift
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

#if canImport(SwiftUI) && canImport(WebKit)

import WebKit
import SwiftUI
internal import os
internal import SwiftyJSON

public struct Live2DView<Placeholder: View, ErrorView: View>: View {
    private var makePlaceholder: () -> Placeholder
    private var makeErrorView: () -> ErrorView
    private var absoluteResourcePath: String
    @State private var isModelLoaded = false
    @State private var model: Live2DModel?
    @State private var isFailed = false
    
    public init(
        resourceURL: URL,
        placeholder: @escaping () -> Placeholder = { EmptyView() },
        errorView: @escaping () -> ErrorView = { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow) }
    ) {
        self.makePlaceholder = placeholder
        self.makeErrorView = errorView
        
        let resourcePath = resourceURL.absoluteString
        if resourcePath.hasPrefix("/") {
            absoluteResourcePath = "https://bestdori.com/assets\(resourcePath)"
        } else if resourcePath.hasPrefix("http://") || resourcePath.hasPrefix("https://") {
            absoluteResourcePath = resourcePath
        } else {
            logger.fault("Unrecognized resource path for Live2DView, this may cause undefined behaviors")
            absoluteResourcePath = resourcePath
        }
    }
    
    public var body: some View {
        VStack { // data only
            if let model {
                _Live2DNativeView(model: model)
                    .allowsHitTesting(false)
            } else {
                if !isFailed {
                    makePlaceholder()
                } else {
                    makeErrorView()
                }
            }
        }
        .task {
            if !isModelLoaded {
                isModelLoaded = true
                Task {
                    let result = await requestJSON(absoluteResourcePath)
                    if case .success(let respJSON) = result {
                        model = .init(json: respJSON)
                    } else {
                        isFailed = true
                    }
                }
            }
        }
    }
}
extension EnvironmentValues {
    @Entry fileprivate var l2dSwayEnabled = true
    @Entry fileprivate var l2dBreathEnabled = true
    @Entry fileprivate var l2dEyeBlinkEnabled = true
    @Entry fileprivate var l2dOnMotionsUpdate: (([Live2DMotion]) -> Void)?
    @Entry fileprivate var l2dOnExpressionsUpdate: (([Live2DExpression]) -> Void)?
    @Entry fileprivate var l2dCurrentMotion: Live2DMotion?
    @Entry fileprivate var l2dCurrentExpression: Live2DExpression?
}
extension View {
    public func live2dSwayDisabled(_ disabled: Bool = true) -> some View {
        environment(\.l2dSwayEnabled, !disabled)
    }
    public func live2dBreathDisabled(_ disabled: Bool = true) -> some View {
        environment(\.l2dBreathEnabled, !disabled)
    }
    public func live2dEyeBlinkDisabled(_ disabled: Bool = true) -> some View {
        environment(\.l2dEyeBlinkEnabled, !disabled)
    }
    public func onLive2DMotionsUpdate(perform action: (([Live2DMotion]) -> Void)?) -> some View {
        environment(\.l2dOnMotionsUpdate, action)
    }
    public func onLive2DExpressionsUpdate(perform action: (([Live2DExpression]) -> Void)?) -> some View {
        environment(\.l2dOnExpressionsUpdate, action)
    }
    public func live2dMotion(_ motion: Live2DMotion?) -> some View {
        environment(\.l2dCurrentMotion, motion)
    }
    public func live2dExpression(_ expr: Live2DExpression?) -> some View {
        environment(\.l2dCurrentExpression, expr)
    }
}

public struct Live2DMotion: Sendable, Hashable {
    internal var _file: Live2DModel.File
    internal var preload: DoriCache.PreloadDescriptor<String>
    
    public var name: String {
        _file.fileName.components(separatedBy: ".").first!
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._file == rhs._file
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_file)
    }
}
public struct Live2DExpression: Sendable, Hashable {
    internal var _file: Live2DModel.File
    internal var preload: DoriCache.PreloadDescriptor<String>
    
    public var name: String {
        _file.fileName.components(separatedBy: ".").first!
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._file == rhs._file
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_file)
    }
}

#if canImport(AppKit)

private struct _Live2DNativeView: NSViewRepresentable {
    var model: Live2DModel
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.underPageBackgroundColor = .clear
        webView.setValue(false, forKey: "drawsBackground")
        setupWebView(webView, with: model, env: context.environment)
        
        var motions = [Live2DMotion]()
        for motion in model.motions {
            motions.append(.init(_file: motion, preload: motion.preload()))
        }
        DispatchQueue.main.async {
            context.environment.l2dOnMotionsUpdate?(motions)
        }
        var expressions = [Live2DExpression]()
        for expression in model.expressions {
            expressions.append(.init(_file: expression, preload: expression.preload()))
        }
        DispatchQueue.main.async {
            context.environment.l2dOnExpressionsUpdate?(expressions)
        }
        
        updateStoredContext(in: context)
        
        return webView
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {
        updateWebView(nsView, fromStored: context.coordinator, toEnv: context.environment)
        updateStoredContext(in: context)
    }
    func makeCoordinator() -> _NativeViewCoordinator {
        .init(model: model)
    }
    
    func updateStoredContext(in context: Context) {
        context.coordinator.currentEnvrionment = context.environment
    }
}

#elseif canImport(UIKit) // canImport(AppKit)

private struct _Live2DNativeView: UIViewRepresentable {
    var model: Live2DModel
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.scrollView.bounces = false
        setupWebView(webView, with: model)
        return webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

#else // canImport(AppKit) || canImport(UIKit)

#error("AppKit and UIKit are unavailable but SwiftUI is available?!")

#endif // canImport(AppKit) || canImport(UIKit)

private class _NativeViewCoordinator {
    internal var model: Live2DModel
    
    internal init(model: Live2DModel) {
        self.model = model
    }
    
    internal var currentEnvrionment: EnvironmentValues = .init()
}

@MainActor
private func setupWebView(_ webView: WKWebView, with model: Live2DModel, env: EnvironmentValues) {
    func textureArrayLiteral(from preloads: [DoriCache.PreloadDescriptor<String>]) async -> String {
        var paths = [String]()
        for preload in preloads {
            if let value = await preload.value {
                paths.append(value)
            } else {
                return ""
            }
        }
        return "\"\(paths.map { "file://\($0)" }.joined(separator: "\", \""))\""
    }
    
    webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    webView.configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
    let modelFile = model.model.preload()
    let textureFiles = model.textures.map { $0.preload() }
    Task {
        let tmpFile = URL(filePath: NSHomeDirectory() + "/tmp/\(UUID()).html")
        try! """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body onload="Simple()" style="margin: 0; height: 100%; overflow: hidden;">
        <canvas id="glcanvas" style="width: 100vmin; height: 100vmin; position: absolute;"></canvas>
        <script>\(_live2dLibJS)</script>
        <script>\(_live2dFrameworkJS)</script>
        <script>
        // Environment
        var eyeBlinkEnabled = \(env.l2dEyeBlinkEnabled);
        var breathEnabled = \(env.l2dBreathEnabled);
        var swayEnabled = \(env.l2dSwayEnabled);
        
        var Simple = function() {
        this.live2DModel = null;
        this.requestID = null;
        this.loadLive2DCompleted = false;
        this.initLive2DCompleted = false;
        this.loadedImages = [];
        this.modelDef = {
            "model":"file://\(await modelFile.value ?? "")",
            "textures":[\(await textureArrayLiteral(from: textureFiles))]
        };
        this.motionManager = new L2DMotionManager();
        this.expressionManager = new L2DMotionManager();
        this.eyeBlink = new L2DEyeBlink();
        Live2D.init();
        var canvas = document.getElementById("glcanvas");
        const dpr = window.devicePixelRatio || 1;
        canvas.width = canvas.clientWidth * dpr;
        canvas.height = canvas.clientHeight * dpr;
        canvas.addEventListener("webglcontextlost", function(e) {
            Simple.myerror("context lost");
            loadLive2DCompleted = false;
            initLive2DCompleted = false;
            var cancelAnimationFrame =
                window.cancelAnimationFrame ||
                window.mozCancelAnimationFrame;
            cancelAnimationFrame(requestID);
            e.preventDefault();
        }, false);
        canvas.addEventListener("webglcontextrestored" , function(e){
            Simple.myerror("webglcontext restored");
            Simple.initLoop(canvas);
        }, false);
        Simple.initLoop(canvas);
        };
        Simple.initLoop = function(canvas) {
        var para = {
            premultipliedAlpha : true,
            alpha : false
        };
        var gl = Simple.getWebGLContext(canvas, para);
        if (!gl) {
            console.log("Failed to create WebGL context.");
            return;
        }
        gl.viewport(0, 0, canvas.width, canvas.height);
        Live2D.setGL(gl);
        Simple.loadBytes(modelDef.model, function(buf){
            live2DModel = Live2DModelWebGL.loadModel(buf);
        });
        var loadCount = 0;
        for(var i = 0; i < modelDef.textures.length; i++){
            (function ( tno ){
                loadedImages[tno] = new Image();
                loadedImages[tno].src = modelDef.textures[tno];
                loadedImages[tno].onload = function(){
                    if((++loadCount) == modelDef.textures.length) {
                        loadLive2DCompleted = true;
                    }
                }
                loadedImages[tno].onerror = function() {
                    Simple.myerror("Failed to load image : " + modelDef.textures[tno]);
                }
            })( i );
        }
        (function tick() {
            Simple.draw(gl);
            var requestAnimationFrame =
                window.requestAnimationFrame ||
                window.mozRequestAnimationFrame ||
                window.webkitRequestAnimationFrame ||
                window.msRequestAnimationFrame;
                requestID = requestAnimationFrame( tick , canvas );
        })();
        };
        Simple.draw = function(gl) {
        gl.clearColor( 0.0 , 0.0 , 0.0 , 0.0 );
        gl.clear(gl.COLOR_BUFFER_BIT);
        if( ! live2DModel || ! loadLive2DCompleted )
            return;
        if( ! initLive2DCompleted ){
            initLive2DCompleted = true;
            for( var i = 0; i < loadedImages.length; i++ ){
                var texName = Simple.createTexture(gl, loadedImages[i]);
                live2DModel.setTexture(i, texName);
            }
            loadedImages = null;
            var s = 2 / live2DModel.getCanvasWidth();
            var matrix4x4 = [
                s, 0, 0, 0,
                0,-s, 0, 0,
                0, 0, 1, 0,
                -1, 1, 0, 1
            ];
            live2DModel.setMatrix(matrix4x4);
        }
        live2DModel.loadParam();
        if (!motionManager.isFinished()) {
            motionManager.updateParam(live2DModel);
        }
        live2DModel.saveParam();
        if (!expressionManager.isFinished()) {
            expressionManager.updateParam(live2DModel);
        }
        
        if (eyeBlinkEnabled) {
            eyeBlink.updateParam(live2DModel);
        }
        
        let seed = (new Date).valueOf() / 1e3 * 2 * Math.PI || 0;
        
        if (breathEnabled) {
            live2DModel.setParamFloat("PARAM_BREATH", .5 + .5 * Math.sin(seed / 3.2345), 1);
        }
        
        if (swayEnabled) {
            live2DModel.setParamFloat("PARAM_ANGLE_X", 15 * Math.sin(seed / 6.5345) * .5, .5);
            live2DModel.setParamFloat("PARAM_ANGLE_Y", 8 * Math.sin(seed / 3.5345) * .5, .5);
            live2DModel.setParamFloat("PARAM_ANGLE_Z", 10 * Math.sin(seed / 5.5345) * .5, .5);
            live2DModel.setParamFloat("PARAM_BODY_ANGLE_X", 4 * Math.sin(seed / 15.5345) * .5, .5)
        }
        
        live2DModel.update();
        live2DModel.draw();
        };
        Simple.getWebGLContext = function(canvas) {
        var NAMES = [ "webgl" , "experimental-webgl" , "webkit-3d" , "moz-webgl"];
        var param = {
            alpha : true,
            premultipliedAlpha : true
        };
        for( var i = 0; i < NAMES.length; i++ ){
            try{
                var ctx = canvas.getContext( NAMES[i], param );
                if( ctx ) return ctx;
            }
            catch(e){}
        }
        return null;
        };
        Simple.createTexture = function(gl, image)
        {
        var texture = gl.createTexture();
        if ( !texture ){
            mylog("Failed to generate gl texture name.");
            return -1;
        }
        
        if(live2DModel.isPremultipliedAlpha() == false){
            gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);
        }
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1);
        gl.activeTexture( gl.TEXTURE0 );
        gl.bindTexture( gl.TEXTURE_2D , texture );
        gl.texImage2D( gl.TEXTURE_2D , 0 , gl.RGBA , gl.RGBA , gl.UNSIGNED_BYTE , image);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
        gl.generateMipmap(gl.TEXTURE_2D);
        gl.bindTexture( gl.TEXTURE_2D , null );
        return texture;
        };
        Simple.loadBytes = function(path , callback)
        {
        var request = new XMLHttpRequest();
        request.open("GET", path , true);
        request.responseType = "arraybuffer";
        request.onload = function(){
            switch( request.status ){
            case 0:
                callback( request.response );
                break;
            default:
                console.log("Failed to load (" + request.status + ") : " + path);
                break;
            }
        }
        request.send(null);
        };
        </script>
        </body>
        </html>
        """.write(to: tmpFile, atomically: true, encoding: .utf8)
        webView.loadFileURL(tmpFile, allowingReadAccessTo: URL(filePath: NSHomeDirectory() + "/tmp/"))
    }
}

@MainActor
private func updateWebView(
    _ webView: WKWebView,
    fromStored coordinator: _NativeViewCoordinator,
    toEnv newEnv: EnvironmentValues
) {
    let oldEnv = coordinator.currentEnvrionment
    if oldEnv.l2dSwayEnabled != newEnv.l2dSwayEnabled {
        webView.evaluateJavaScript("swayEnabled = \(newEnv.l2dSwayEnabled);")
    }
    if oldEnv.l2dBreathEnabled != newEnv.l2dBreathEnabled {
        webView.evaluateJavaScript("breathEnabled = \(newEnv.l2dSwayEnabled);")
    }
    if oldEnv.l2dEyeBlinkEnabled != newEnv.l2dEyeBlinkEnabled {
        webView.evaluateJavaScript("eyeBlinkEnabled = \(newEnv.l2dSwayEnabled);")
    }
    
    if oldEnv.l2dCurrentMotion != newEnv.l2dCurrentMotion {
        if let motion = newEnv.l2dCurrentMotion {
            Task {
                _ = try? await webView.evaluateJavaScript("""
                Simple.loadBytes('\(await motion.preload.value ?? "")', function(buf) {
                    let motion = Live2DMotion.loadMotion(buf);
                    motionManager.startMotionPrio(motion, false, 1);
                });
                """)
            }
        }
    }
    if oldEnv.l2dCurrentExpression != newEnv.l2dCurrentExpression {
        if let expression = newEnv.l2dCurrentExpression {
            Task {
                if case .success(let json) = await requestJSON("file://\(await expression.preload.value ?? "")") {
                    _ = try? await webView.evaluateJavaScript("""
                    function f() {
                        let motion = new AMotion();
                        motion.setFadeIn(\(json["fade_in"].int ?? 1000));
                        motion.setFadeOut(\(json["fade_out"].int ?? 1000));
                        motion.params = \(json["params"].rawString()!);
                        motion.paramList = motion.params.map((function(t) {
                            switch (t.calc) {
                            case "set":
                                return {
                                    type: "set",
                                    id: t.id,
                                    val: t.val
                                };
                            case "mult":
                                return {
                                    type: "mult",
                                    id: t.id,
                                    val: t.val / (t.def || 1)
                                };
                            default:
                                return {
                                    type: "add",
                                    id: t.id,
                                    val: t.val - (t.def || 0)
                                }
                            }
                        }));
                        motion.updateParamExe = function(t, e, a) {
                            this.paramList.forEach((function(e) {
                                switch (e.type) {
                                case "set":
                                    t.setParamFloat(e.id, e.val, a);
                                    break;
                                case "mult":
                                    t.multParamFloat(e.id, e.val, a);
                                    break;
                                case "add":
                                    t.addToParamFloat(e.id, e.val, a);
                                    break
                                }
                            }))
                        }
                        expressionManager.startMotion(motion);
                    }
                    f();
                    """)
                }
            }
        }
    }
}

#endif // canImport(SwiftUI) && canImport(WebKit)
