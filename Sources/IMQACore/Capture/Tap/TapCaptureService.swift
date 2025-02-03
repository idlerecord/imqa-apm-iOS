//
//  TapCaptureService.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import OpenTelemetryApi
import IMQAOtelInternal
import IMQACommonInternal
import Foundation


#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Service that generates OpenTelemetry span events for taps on the screen.
/// Note that any taps done on a keyboard view will be automatically ignored.
@objc(IMQATapCaptureService)
internal final class TapCaptureService: CaptureService {
#if canImport(UIKit) && !os(watchOS)

    public let options: TapCaptureService.Options

    private var swizzler: UIWindowSendEventSwizzler?
    private let lock: NSLocking

    @objc public convenience init(options: TapCaptureService.Options = TapCaptureService.Options()) {
        self.init(options: options, lock: NSLock())
    }

    init(options: TapCaptureService.Options, lock: NSLock) {
        self.options = options
        self.lock = lock
    }

    override public func onInstall() {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard state == .uninstalled else {
            return
        }

        do {
            swizzler = UIWindowSendEventSwizzler()
            swizzler?.onEvent = { [weak self] event in
                self?.handleCapturedEvent(event)
            }

            try swizzler?.install()
        } catch let exception {
            IMQA.logger.error("An error occurred while swizzling UIWindow.sendEvent: \(exception.localizedDescription)")
        }
    }

    func handleCapturedEvent(_ event: UIEvent) {
        guard state == .active else {
            return
        }

        // get touch data
        guard event.type == .touches,
              let allTouches = event.allTouches,
              let touch = allTouches.first,
              touch.phase == .began,
              let target = touch.view else {
            return
        }

        // check if the view type should be ignored
        let shouldCapture = options.delegate?.shouldCaptureTap(onView: target) ?? true
        guard shouldCapture else {
            return
        }

        guard options.ignoredViewTypes.first(where: { type(of: target) == $0 }) == nil else {
            return
        }
        

        // get view name
        let accessibilityIdentifier = target.accessibilityIdentifier
        let targetClass = type(of: target)

        let className = String(describing: targetClass)
        if className.hasPrefix("UIKeyboardLayoutStar") {
            return
        }
        
        let viewName = accessibilityIdentifier ?? String(describing: targetClass)
        var buttonName:String? = target.findTitle()
        
        
        var attributes: [String: AttributeValue] = [:]
        attributes[SpanSemantics.Event.eventType] = AttributeValue(SpanSemantics.EventValue.eventClick.rawValue)
        
        if let buttonName = buttonName {
            attributes[SpanSemantics.Event.targetElementText] = AttributeValue(buttonName)
        }
        attributes[SpanSemantics.Event.targetElement] = AttributeValue(viewName)
        
        
        // get coordinates
        if shouldRecordCoordinates(from: target) {
            let point = touch.location(in: target.window)
            attributes[SpanSemantics.Event.tapCoords] = AttributeValue(point.toString())
            IMQA.logger.debug("Captured tap at \(point) on: \(viewName)")
        } else {
            IMQA.logger.debug("Captured tap with no coordinates on: \(viewName)")
        }

        let spanName = (buttonName ?? viewName) + "[click]"
        let clickSpan = SpanUtils.span(name: spanName,
                                       startTime: Date(),
                                       type: IMQASpanType.EVENT,
                                       attributes: attributes)
        clickSpan.end()        
        TapCaptureService.tapSpan = clickSpan
    }
    
    func shouldRecordCoordinates(from target: UIView) -> Bool {
        let shouldCapture =
            options.delegate?.shouldCaptureTapCoordinates(onView: target) ??
            options.captureTapCoordinates
        guard shouldCapture else {
            return false
        }

        guard let keyboardViewClass = NSClassFromString("UIKeyboardLayout"),
              let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow")
        else {
            return false
        }

        return !(target.isKind(of: keyboardViewClass) || target.isKind(of: keyboardWindowClass))
    }

#endif
    /// spanContext저장
    static var tapSpan:Span?

}


#if canImport(UIKit) && !os(watchOS)
class UIWindowSendEventSwizzler: Swizzlable {
    typealias ImplementationType = @convention(c) (UIWindow, Selector, UIEvent) -> Void
    typealias BlockImplementationType = @convention(block) (UIWindow, UIEvent) -> Void
    static var selector: Selector = #selector(
        UIWindow.sendEvent(_:)
    )

    var baseClass: AnyClass = UIWindow.self

    var onEvent: ((UIEvent) -> Void)?

    func install() throws {
        try swizzleInstanceMethod { originalImplementation in { [weak self] uiWindow, uiEvent -> Void in
                self?.onEvent?(uiEvent)
                originalImplementation(uiWindow, UIWindowSendEventSwizzler.selector, uiEvent)
            }
        }
    }
}
#endif
