//
//  File.swift
//  IMQA-iOS-P
//
//  Created by Hunta on 2024/10/15.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal
import OpenTelemetryApi
import OpenTelemetrySdk
//import OpenTelemetryProtocolExporterHttp
//import OpenTelemetryProtocolExporterCommon
import IMQACollectDeviceInfo



public class IMQAOTel{
    static let sessionId: SessionIdentifier = SessionIdentifier.random

    private let serviceName: String = Bundle.appIdentifier
    
    private var serviceVersion: String = Bundle.appVersion
    
    private var instrumentationName: String = "imqa.sdk.iOS"
    
    private var instrumentationVersion: String = IMQAMeta.sdkVersion

    /**************************************************************************************************************************************/
    
    /// trace
    internal var tracer: Tracer {
        OpenTelemetry.instance.tracerProvider.get(
            instrumentationName: instrumentationName,
            instrumentationVersion: instrumentationVersion
        )
    }
            
    /// log기록
    internal var logger: Logger {
        OpenTelemetry.instance.loggerProvider.get(instrumentationScopeName: instrumentationName)
    }
        
    ///webview에서 URL 변화할때 span 을 추적하기 위해서는 것   //baggageManager업무용 propagators추적용
    internal var propagators: ContextPropagators{
        OpenTelemetry.instance.propagators
    }
    
    /// 민감 하지않은 data 를 추가합니다.
    internal var baggageManager: BaggageManager{
        OpenTelemetry.instance.baggageManager
    }
    
    /// carrier 전파
    private var carrier: [String: String] = [:]
    var setter: DefaultTextMapCarrier {
        DefaultTextMapCarrier(carrier: &carrier)
    }

            
    /// Resource 추가하기
    /// - Parameters:
    ///   - serviceKey: 서비스키
    ///   - deviceId: 디바이스 아이디
    /// - Returns: Resource
    static func setUpResource(serviceKey: String, deviceId: String) -> Resource{
        var dict:[String: AttributeValue] = [:]
        dict[ResourceSemantics.serviceName] = AttributeValue.string(Bundle.appIdentifier)
        dict[ResourceSemantics.serviceVersion] = AttributeValue.string(Bundle.appVersion)
        dict[ResourceSemantics.osName] = AttributeValue.string(DeviceModel.systemName)
        dict[ResourceSemantics.osVersion] = AttributeValue.string(DeviceModel.systemVersion)
        dict[ResourceSemantics.imqaSDKVersion] = AttributeValue(IMQAMeta.sdkVersion)
        dict[ResourceSemantics.serviceKey] = AttributeValue.string(serviceKey)
        dict[ResourceSemantics.deviceManufacturer] = AttributeValue.string(DeviceModel.manufacturer)
        dict[ResourceSemantics.deviceBrand] = AttributeValue.string(DeviceModel.brand)
        dict[ResourceSemantics.deviceModelIdentifier] = AttributeValue.string(DeviceModel.model)
        let resource = DefaultResources().get().merging(other: Resource(attributes: dict))
        return resource
    }
    
    
    /// 공동으로 들러가는 attribute 추가하기
    /// - Parameter config:
    static func setUpCommonSpanAttributeValues(){
        //한번만 호출하면 된는 Data
        //session.id
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.sessionId,
                                                   value: AttributeValue(sessionId.toString))
        
        //source.address
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.sourceAddress,
                                                   value: AttributeValue(NetworkInfoManager.sharedInstance.publicIP))
        

        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.screenName,
                                                   value: AttributeValue(IMQAScreen.name ?? SpanSemantics.CommonValue.noScreenValue))
        
        //screen.type
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.screenType,
                                                   value: AttributeValue(SpanSemantics.CommonValue.viewValue))
        
        //user.id
        let userId = UserModel.id ?? ""
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.userId,
                                                   value: AttributeValue(userId))
        
        //area.code
        let areaCode = AreaCodeModel.areaCode ?? ""
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.areaCode,
                                                   value: AttributeValue(areaCode))
        
        //network.carrier.name
        CarrierModel.getCarrierInfo()
        let carrierName = CarrierModel.carrierName
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.networkCarrierName,
                                                   value: AttributeValue(carrierName))
        
        //device.battery.level
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceBatteryLevel,
                                                   value: AttributeValue(BatteryModel.level))
        
        //device.battery.charging
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceBatteryIsCharging,
                                                   value: AttributeValue(BatteryModel.isCharging))
        
        //app.cpu.usage
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceCpuUsage,
                                                   value: AttributeValue(CpuModel.AppCPUUsage))
        
        //device.memory.total
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceMemoryTotal,
                                                   value: AttributeValue(MemoryModel.memoryTotal))
        
        //device.memory.total
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceMemoryTotal,
                                                   value: AttributeValue(MemoryModel.memoryTotal))
        
        //app.memory.allocated
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.appMemoryAllocated,
                                                   value: AttributeValue(MemoryModel.memoryAllocated))
        
        //network.available
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.networkAvailable,
                                                   value: AttributeValue(NetworkModel.isReachable))
        
        //network.cellular
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.networkCellular,
                                                   value: AttributeValue(NetworkModel.isCellular))
        
        //network.wifi
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.networkWifi,
                                                   value: AttributeValue(NetworkModel.isWifi))
        
    }
    
    static var resources: Resource?

    
    static func setUp(option: IMQA.Options,
                      storage: IMQAStorage,
                      logController: LogControllable){
        
        //Resource Setting
        let deviceId = DeviceIdentifier.retrieve(from: storage)
        let resource = setUpResource(serviceKey: option.serviceKey, deviceId: deviceId.hex)
        resources = resource
        
        //공동으로 들어가는 Attributes속성 setting
        setUpCommonSpanAttributeValues()

        
        //tracer
        let baseUrl = option.endpoints?.baseURL
        let uploadUrl:String = baseUrl!
        
        let tracerUrlStr = IMQA.Endpoints.OpentelemetryBaseUrl.tracer(uploadUrl).baseUrl()
        guard let tracerUrl = URL(string: tracerUrlStr) else{
            return
        }
        
        let tracerExporter = CustomOtlpHttpTraceExporter(endpoint: tracerUrl, storage: storage)

        //logs
        let logsUrlStr = IMQA.Endpoints.OpentelemetryBaseUrl.logs(uploadUrl).baseUrl()
        guard let logsUrl = URL(string: logsUrlStr) else{
            return
        }
        
        let logsExporter = CustomOtlpHttpLogExporter(endpoint: logsUrl)

        
        let opentelemetryExporter = OpenTelemetryExporter(spanExporter: tracerExporter,
                                                        logExporter: logsExporter)
        
        let sampler = SessionBasedSampler(probability: option.sampleRate, storage: storage)
        OpenTelemetry.registerTracerProvider(
            tracerProvider:TracerProviderBuilder()
                .with(resource: resource)
                .with(sampler: sampler)
                .add(spanProcessors: .processors(for: storage, export: opentelemetryExporter))
                .build()
        )
        
        let logSharedState = DefaultIMQALogSharedState.create(
            storage: storage,
            controller: logController,
            exporter: nil//logsExporter
        )
        
        OpenTelemetry.registerLoggerProvider(loggerProvider: DefaultIMQALoggerProvider(sharedState: logSharedState))

                        
        //metric
//        let metricUrlStr = IMQA.Endpoints.OpentelemetryBaseUrl.metric(uploadUrl).baseUrl()
//        guard let metricUrl = URL(string: metricUrlStr) else{
//            return
//        }
//        let metricExporter = StableOtlpHTTPMetricExporter(endpoint: metricUrl)
//        let reader = StablePeriodicMetricReaderBuilder(exporter: metricExporter).setInterval(timeInterval: 60).build()
//        
//        let metricProvider = StableMeterProviderBuilder()
//            .setResource(resource: resource)
//            .registerMetricReader(reader: reader)
//            .build()
//        OpenTelemetryApi.OpenTelemetry.registerStableMeterProvider(meterProvider: metricProvider)

        
        // 同时使用W3C Trace Context、B3、Jaeger三种Trace透传格式。
        OpenTelemetry.registerPropagators(textPropagators: [W3CTraceContextPropagator()],
                                          baggagePropagator: W3CBaggagePropagator())
        
    }
}

// MARK: - Tracing
extension IMQAOTel{
    public func recordSpan<T>(
        name: String,
        type: IMQASpanType,
        attributes: [String: String] = [:],
        spanOperation: () -> T
    ) -> T {
        let span = buildSpan(name: name, type: type, attributes: attributes)
                        .startSpan()
        let result = spanOperation()
        span.end()

        return result
    }

    public func buildSpan(
        name: String,
        type: IMQASpanType,
        attributes: [String: String] = [:]
    ) -> SpanBuilder {
        let builder = tracer.spanBuilder(spanName: name)
            .setAttribute(key: SpanSemantics.spanType,
                          value: type.rawValue)
            .setSpanKind(spanKind: .client)
        
        for (key, value) in SpanAttributesUtils.spanCommonAttributes{
            builder.setAttribute(key: key, value: value)
        }
        for (key, value) in attributes {
            builder.setAttribute(key: key, value: value)
        }
        return builder
    }
    // MARK: - Logging

    public func log(
        _ message: String,
        severity: LogSeverity,
        attributes: [String: String]
    ) {
        log(message, severity: severity, timestamp: Date(), attributes: attributes)
    }

    public func log(
        _ message: String,
        severity: LogSeverity,
        timestamp: Date,
        attributes: [String: String]
    ) {
        let otelAttributes = attributes.reduce(into: [String: AttributeValue]()) {
            $0[$1.key] = AttributeValue.string($1.value)
        }
        if let context = OpenTelemetry.instance.contextProvider.activeSpan?.context{
            logger
                .logRecordBuilder()
                .setBody(.string(message))
                .setTimestamp(timestamp)
                .setAttributes(otelAttributes)
                .setSpanContext(context)
                .setSeverity(Severity.fromLogSeverity(severity) ?? .info)
                .emit()
            return
        }
        logger
            .logRecordBuilder()
            .setBody(.string(message))
            .setTimestamp(timestamp)
            .setAttributes(otelAttributes)
            .setSeverity(Severity.fromLogSeverity(severity) ?? .info)
            .emit()
    }
    
    public func log(
        _ message: String,
        severity: LogSeverity,
        spanContext: SpanContext,
        timestamp: Date,
        attributes: [String: String])
    {
        let otelAttributes = attributes.reduce(into: [String: AttributeValue]()) {
            $0[$1.key] = AttributeValue.string($1.value)
        }
        logger
            .logRecordBuilder()
            .setBody(.string(message))
            .setTimestamp(timestamp)
            .setAttributes(otelAttributes)
            .setSpanContext(spanContext)
            .setSeverity(Severity.fromLogSeverity(severity) ?? .info)
            .emit()
    }
}

extension IMQAOTel{
    
    func propagators(spanContext: SpanContext){
        // 将 Span 的上下文注入到 HTTP 请求头中
        propagators.textMapPropagator.inject(spanContext: spanContext,
                                             carrier: &carrier,
                                             setter: setter)
    }
    
    func baggage(key: String, value: String, metadata:String?) -> Baggage?{
        guard let key = EntryKey(name: key) else { return  nil}
        guard let value = EntryValue(string: value) else { return nil }
        let metadata = EntryMetadata(metadata: metadata)
        return baggageManager.baggageBuilder().put(key: key, value: value, metadata: metadata).build()
    }
    
}

struct DefaultTextMapCarrier: Setter {
    
    var carrier: [String: String]
    
    init(carrier: inout [String: String]) {
        self.carrier = carrier
    }
    
    // 提供取值方法，用于从 carrier 中获取值
    func get(key: String) -> String? {
        return carrier[key]
    }
    
    // 提供赋值方法，用于向 carrier 中插入值
    mutating func set(key: String, value: String) {
        carrier[key] = value
    }
    
    func set(carrier: inout [String : String], key: String, value: String) {
        carrier[key] = value
    }
}
