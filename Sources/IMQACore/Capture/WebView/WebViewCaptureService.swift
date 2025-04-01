//
//  WebViewCaptureService.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

#if canImport(WebKit)
import Foundation
import WebKit
import OpenTelemetryApi
import IMQACommonInternal

/// Service that generates OpenTelemetry span events when a `WKWebView` loads an URL or throws an error.
@objc(IMQAWebViewCaptureService)
public final class WebViewCaptureService: CaptureService {

    @objc public let options: WebViewCaptureService.Options
    private let lock: NSLocking
    private var swizzlers: [any Swizzlable] = []
    var proxy: WKNavigationDelegateProxy

    @objc public convenience init(options: WebViewCaptureService.Options) {
        self.init(options: options, lock: NSLock())
    }

    public convenience override init() {
        self.init(lock: NSLock())
    }

    init(
        options: WebViewCaptureService.Options = WebViewCaptureService.Options(),
        lock: NSLocking
    ) {
        self.options = options
        self.lock = lock
        self.proxy = WKNavigationDelegateProxy()

        super.init()

        proxy.callback = { [weak self] url, statusCode in
            self?.createEvent(url: url, statusCode: statusCode)
        }
        
        proxy.callback = { [weak self] startTime, endTime in
            
        }
    }

    public override func onInstall() {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard state == .uninstalled else {
            return
        }

        initializeSwizzlers()

        swizzlers.forEach {
            do {
                try $0.install()
            } catch let exception {
                IMQA.logger.error("Capture service couldn't be installed: \(exception.localizedDescription)")
            }
        }
    }

    private func initializeSwizzlers() {
        swizzlers.append(WKWebViewSetNavigationDelegateSwizzler(proxy: proxy))
        swizzlers.append(WKWebViewLoadRequestSwizzler())
        swizzlers.append(WKWebViewLoadHTMLStringSwizzler())
        swizzlers.append(WKWebViewLoadFileURLSwizzler())
        swizzlers.append(WKWebViewLoadDataSwizzler())
        WKWebView.swizzleInitialization
    }

    private func createEvent(url: URL?, statusCode: Int?) {
//
//        guard let url = url else {
//            return
//        }
//
//        let urlString = getUrlString(url: url)
//
//        var attributes: [String: AttributeValue] = [
//            SpanEventSemantics.keyEmbraceType: .string(SpanEventType.webView.rawValue),
//            SpanEventSemantics.WebView.keyUrl: .string(urlString)
//        ]

//        if let errorCode = statusCode, errorCode != 200 {
//            attributes[SpanEventSemantics.WebView.keyErrorCode] = .int(errorCode)
//        }
//        
//        
        let baggage = otel?.baggage(key: "sessionId", value: IMQAOTel.sessionId.toString, metadata: nil)
//
//        let event = RecordingSpanEvent(
//            name: SpanEventSemantics.WebView.name,
//            timestamp: Date(),
//            attributes: attributes
//        )
//        otel?.add(event: event)
        
        
    }
    
    func createSpan(){
        
    }

    private func getUrlString(url: URL) -> String {
        guard options.stripQueryParams else {
            return url.absoluteString
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        components.query = nil

        return components.string ?? url.absoluteString
    }
}

struct WKWebViewSetNavigationDelegateSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (WKWebView, Selector, WKNavigationDelegate) -> Void
    typealias BlockImplementationType = @convention(block) (WKWebView, WKNavigationDelegate) -> Void
    static var selector: Selector = #selector(setter: WKWebView.navigationDelegate)
    var baseClass: AnyClass
    let proxy: WKNavigationDelegateProxy

    init(proxy: WKNavigationDelegateProxy, baseClass: AnyClass = WKWebView.self) {
        self.baseClass = baseClass
        self.proxy = proxy
    }

    func install() throws {
        try swizzleInstanceMethod { originalImplementation -> BlockImplementationType in
            return { webView, delegate in
                if !(webView.navigationDelegate is WKNavigationDelegateProxy) {
                    proxy.originalDelegate = delegate
                    originalImplementation(webView, Self.selector, proxy)
                } else {
                    originalImplementation(webView, Self.selector, delegate)
                }
            }
        }
    }
}

struct WKWebViewLoadRequestSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (WKWebView, Selector, URLRequest) -> WKNavigation?
    typealias BlockImplementationType = @convention(block) (WKWebView, URLRequest) -> WKNavigation?
    static var selector: Selector = #selector(WKWebView.load(_:))
    var baseClass: AnyClass

    init(baseClass: AnyClass = WKWebView.self) {
        self.baseClass = baseClass
    }

    func install() throws {
        try swizzleInstanceMethod { originalImplementation -> BlockImplementationType in
            return { webView, request in
                if webView.navigationDelegate == nil {
                    webView.navigationDelegate = nil // forceful trigger setNavigationDelegate swizzler
                }

                return originalImplementation(webView, Self.selector, request)
            }
        }
    }
}

struct WKWebViewLoadHTMLStringSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (WKWebView, Selector, String, URL?) -> WKNavigation?
    typealias BlockImplementationType = @convention(block) (WKWebView, String, URL?) -> WKNavigation?
    static var selector: Selector = #selector(WKWebView.loadHTMLString(_:baseURL:))
    var baseClass: AnyClass

    init(baseClass: AnyClass = WKWebView.self) {
        self.baseClass = baseClass
    }

    func install() throws {
        try swizzleInstanceMethod { originalImplementation -> BlockImplementationType in
            return { webView, htmlString, url in
                if webView.navigationDelegate == nil {
                    webView.navigationDelegate = nil // forcefully trigger setNavigationDelegate swizzler
                }

                return originalImplementation(webView, Self.selector, htmlString, url)
            }
        }
    }
}

struct WKWebViewLoadFileURLSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (WKWebView, Selector, URL, URL) -> WKNavigation?
    typealias BlockImplementationType = @convention(block) (WKWebView, URL, URL) -> WKNavigation?
    static var selector: Selector = #selector(WKWebView.loadFileURL(_:allowingReadAccessTo:))
    var baseClass: AnyClass

    init(baseClass: AnyClass = WKWebView.self) {
        self.baseClass = baseClass
    }

    func install() throws {
        try swizzleInstanceMethod { originalImplementation -> BlockImplementationType in
            return { webView, fileUrl, readAccessURL in
                if webView.navigationDelegate == nil {
                    webView.navigationDelegate = nil // forcefully trigger setNavigationDelegate swizzler
                }

                return originalImplementation(webView, Self.selector, fileUrl, readAccessURL)
            }
        }
    }
}

struct WKWebViewLoadDataSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (WKWebView, Selector, Data, String, String, URL?) -> WKNavigation?
    typealias BlockImplementationType = @convention(block) (WKWebView, Data, String, String, URL?) -> WKNavigation?
    static var selector: Selector = #selector(
        WKWebView.load(_:mimeType:characterEncodingName:baseURL:)
    )
    var baseClass: AnyClass

    init(baseClass: AnyClass = WKWebView.self) {
        self.baseClass = baseClass
    }

    func install() throws {
        try swizzleInstanceMethod { originalImplementation -> BlockImplementationType in
            return { webView, data, mimeType, encoding, url in
                if webView.navigationDelegate == nil {
                    webView.navigationDelegate = nil // forcefully trigger setNavigationDelegate swizzler
                }

                return originalImplementation(webView, Self.selector, data, mimeType, encoding, url)
            }
        }
    }
}

extension WKWebView {
    static let swizzleInitialization: Void = {
        let originalSelector = #selector(WKWebView.init(frame:configuration:))
        let swizzledSelector = #selector(WKWebView.swizzledInit(frame:configuration:))
        
        let originalMethod = class_getInstanceMethod(WKWebView.self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(WKWebView.self, swizzledSelector)!
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc private func swizzledInit(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        let config = configuration
        let sessionScriptString = "window.__imqa_session_id = '\(IMQAOTel.sessionId.toString)';"
        let userScript = WKUserScript(
            source: sessionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        
        let serviceNameScriptString = "window.__imqa_service_name = '\(Bundle.appName)';"
        let serviceNameScript = WKUserScript(
            source: serviceNameScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(serviceNameScript)
                
        //
        let serviceVersionScriptString = "window.__imqa_service_version = '\(Bundle.appBuildVersion)';"
        let serviceVersionScript = WKUserScript(
            source: serviceVersionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(serviceVersionScript)
        
        
        //imqaSharedSession
        var imqaSharedSessionScriptString = ""
        if IMQAOTel.isSharedSession {
            imqaSharedSessionScriptString = "window.__imqa_shared_session = true;"
        }else{
            imqaSharedSessionScriptString = "window.__imqa_shared_session = false;"
        }
        
        let imqaSharedSessionScript = WKUserScript(
            source: imqaSharedSessionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(imqaSharedSessionScript)

        
        //service Key
        var serviceKeyScriptString = "window.__imqa_service_key = '\(IMQAOTel.serviceKey)';"
        let serviceKeyScript = WKUserScript(
            source: serviceKeyScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(serviceKeyScript)

        
        
        if !SessionBasedSampler.sampler {
            let deactivatedScriptString = "window.__imqa_deactivated = true;"
            let deactivatedScript = WKUserScript(
                source: deactivatedScriptString,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            config.userContentController.addUserScript(deactivatedScript)
        }
        
        return self.swizzledInit(frame: frame, configuration: config)
    }
}
#endif
