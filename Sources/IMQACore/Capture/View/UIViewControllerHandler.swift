//
//  UIViewControllerHandler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/13/24.
//
import OpenTelemetryApi
import IMQAOtelInternal
import IMQACommonInternal
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

protocol UIViewControllerHandlerDataSource: AnyObject {
    var state: CaptureServiceState { get }
    var otel: IMQAOpenTelemetry? { get }

    var instrumentVisibility: Bool { get }
    var instrumentFirstRender: Bool { get }
}

class UIViewControllerHandler{
    weak var dataSource: UIViewControllerHandlerDataSource?
#if canImport(UIKit) && !os(watchOS)
    private let queue: DispatchableQueue = DispatchQueue(label: "com.imqa.UIViewControllerHandler", qos: .utility)
    @ThreadSafe var parentSpans:[String: Span] = [:]
    @ThreadSafe var viewDidLoadSpans:[String: Span] = [:]
    @ThreadSafe var viewWillAppearSpans:[String: Span] = [:]
    @ThreadSafe var viewDidAppearSpans:[String: Span] = [:]
    @ThreadSafe var visibilitySpans:[String: Span] = [:]
    @ThreadSafe var viewdidLoadStartTimes: [String: Date] = [:]
    @ThreadSafe var viewdidLoadEndTimes: [String: Date] = [:]

    
    @ThreadSafe var uiReadySpans:[String: Span] = [:]
    @ThreadSafe var alreadyFinishedUiReadyIds: Set<String> = []
    var shouldNotBeCollectedClass: [String]{
        return ["UIEditingOverlayViewController",
                "UIInputWindowController",
                "UIAlertController"]
    }
    
    init() {
        
    }
    
    deinit {
            
    }
    
    func parentSpan(for vc: UIViewController) ->Span?{
        guard let id = vc.imqa_identifier else {
            return nil
        }
        
        return parentSpans[id]
    }
    
    @objc func foregroundSessionDidEnd(_ notification: Notification? = nil){
        let now = notification?.object as? Date ?? Date()
        queue.async{
            for span in self.visibilitySpans.values{
                span.end(time: now)
            }
            for id in self.parentSpans.keys{
                self.forcefullyEndSpans(id: id, time: now)
            }
            
            self.parentSpans.removeAll()
            self.viewDidLoadSpans.removeAll()
            self.viewWillAppearSpans.removeAll()
            self.viewDidAppearSpans.removeAll()
            self.visibilitySpans.removeAll()
            self.uiReadySpans.removeAll()
            self.alreadyFinishedUiReadyIds.removeAll()
        }
    }
    
    func onViewDidLoadStart(_ vc: UIViewController){
        guard !shouldNotBeCollectedClass.contains(vc.className) else{return}
        let id = UUID().uuidString
        vc.imqa_identifier = id

        queue.async{
            //generate id
            TapCaptureService.tapSpan = nil
            
            let className = vc.className
            self.viewdidLoadStartTimes[id] = Date()
        }
    }
    
    func onViewDidLoadEnd(_ vc: UIViewController){
        queue.async {
            guard let id = vc.imqa_identifier else {
                return
            }
            self.viewdidLoadEndTimes[id] = Date()
        }
    }
    
    func onViewWillAppearStart(_ vc: UIViewController){
        guard !shouldNotBeCollectedClass.contains(vc.className) else{return}
        IMQAScreen.name = vc.className
        
        queue.async {
            guard let id = vc.imqa_identifier else{
                return
            }
            
            let className = vc.className
            
            let startTime = self.viewdidLoadStartTimes[id] ?? Date()
            let parentSpan = SpanUtils.span(name: className,
                                          startTime: startTime,
                                          type: IMQASpanType.RENDER,
                                            attributes: [SpanSemantics.Common.screenName:.string(className)])
            self.parentSpans[id] = parentSpan
            
            let viewWillAppearSpanName = "\(className)[viewWillAppear]"
            let span = SpanUtils.span(name: viewWillAppearSpanName,
                                      parentSpan: parentSpan,
                                      startTime: Date(),
                                      type: IMQASpanType.RENDER,
                                      attributes: [SpanSemantics.Common.screenName:.string(className)])
            self.viewWillAppearSpans[id] = span
        }
    }
    
    func onViewWillAppearEnd(_ vc: UIViewController){
        queue.async {
            guard let id = vc.imqa_identifier,
                  let span = self.viewWillAppearSpans.removeValue(forKey: id) else {
                return
            }

            span.end()
        }
    }
    
    func onViewDidAppearStart(_ vc: UIViewController){
//        print("\(vc)onViewDidAppearStart")
        guard !shouldNotBeCollectedClass.contains(vc.className) else{return}

        queue.async {
            guard let id = vc.imqa_identifier,
                  let parentSpan = self.parentSpans[id] else{
                return
            }

            //generate view did appear span
            let className = vc.className
            let viewDidAppearSpanName = "\(className)[viewDidAppear]"
            let span = SpanUtils.span(name: viewDidAppearSpanName,
                                      parentSpan: parentSpan,
                                      startTime: Date(),
                                      type: IMQASpanType.RENDER,
                                      attributes: [SpanSemantics.Common.screenName:.string(className)])
            self.viewDidAppearSpans[id] = span
        }
    }
    
    func onViewDidAppearEnd(_ vc: UIViewController){
        queue.async {
            guard let id = vc.imqa_identifier else{
                return
            }
            let className = vc.className
            
            if let span = self.viewDidAppearSpans.removeValue(forKey: id){
                span.end(time: Date())
            }
            guard let parentSpan = self.parentSpans.removeValue(forKey: id) else{
                return
            }


            if let startTime = self.viewdidLoadStartTimes[id],
                let endTime = self.viewdidLoadEndTimes[id]{
                
                let viewDidLoadSpanName = "\(className)[viewDidLoad]"
                let viewDidLoadSpan = SpanUtils.span(name: viewDidLoadSpanName,
                                          parentSpan: parentSpan,
                                          startTime: startTime ?? Date(),
                                          type: IMQASpanType.RENDER,
                                          attributes: [SpanSemantics.Common.screenName:.string(className)])
                viewDidLoadSpan.end(time: endTime ?? Date())
                self.viewdidLoadStartTimes[id] = nil
                self.viewdidLoadEndTimes[id] = nil
            }
            parentSpan.end(time: Date())
        }
    }
    
    func onViewDidDisappear(_ vc: UIViewController){
        queue.async {

        }
    }
    
    func onViewBecameInteractive(_ vc: UIViewController) {
        queue.async {
            
        }
    }
    
    private func forcefullyEndSpans(id: String, time: Date) {

        if let viewDidLoadSpan = self.viewDidLoadSpans[id] {
//            viewDidLoadSpan.end(errorCode: ErrorCode.userAbandon, time: time)
        }

        if let viewWillAppearSpan = self.viewWillAppearSpans[id] {
//            viewWillAppearSpan.end(errorCode: ErrorCode.userAbandon, time: time)
        }

        if let viewDidAppearSpan = self.viewDidAppearSpans[id] {
//            viewDidAppearSpan.end(errorCode: ErrorCode.userAbandon, time: time)
        }

        if let uiReadySpan = self.uiReadySpans[id] {
//            uiReadySpan.end(errorCode: ErrorCode.userAbandon, time: time)
        }

        if let parentSpan = self.parentSpans[id] {
//            parentSpan.end(errorCode: ErrorCode.userAbandon, time: time)
        }

        self.clear(id: id)
    }

    
    private func clear(id: String, vc: UIViewController? = nil){
        self.parentSpans[id] = nil
        self.viewDidLoadSpans[id] = nil
        self.viewWillAppearSpans[id] = nil
        self.viewDidAppearSpans[id] = nil
        self.uiReadySpans[id] = nil
        self.alreadyFinishedUiReadyIds.remove(id)
        
        vc?.imqa_identifier = nil
    }
#endif
}

extension Span {
    var isTimeToFirstRender: Bool {
        return name.contains("time-to-first-render")
    }

    var isTimeToInteractive: Bool {
        return name.contains("time-to-interactive")
    }
}
