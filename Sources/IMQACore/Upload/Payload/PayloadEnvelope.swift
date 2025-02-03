//
//  PayloadEnvelope.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation
internal import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk

struct PayloadEnvelope<T: Encodable>: Encodable {
    var resource: ResourcePayload
    var metadata: MetadataPayload
    var version: String = "1.0"
    var type: String
    var data = [String: T]()
}

extension PayloadEnvelope{
    static func requestLogProtobufData(logRecords:[ReadableLogRecord]) -> Data?{
        let exportRequest = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest.with {
            $0.resourceLogs = LogRecordAdapter.toProtoResourceRecordLog(logRecordList: logRecords)
        }
        do {
            let data = try exportRequest.serializedData()
            return data
        } catch {
            IMQA.logger.warning("Function::requestLogProbufData::serializedData Convert Error")
            return nil
        }
    }
    
    static func requestSpanProtobufData(spans: [SpanData]) -> Data?{
        let exportRequest = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
            $0.resourceSpans = SpanAdapter.toProtoResourceSpans(spanDataList: spans)
        }
        do {
            let data = try exportRequest.serializedData()
            return data
        } catch {
            IMQA.logger.warning("Function::requestSpanProbufData::serializedData Convert Error")
            return nil
        }
    }
}

extension PayloadEnvelope{
    func requestLogPayloadJsonData() -> Data?{
        
        return nil
    }
    
    static func requestSpanPayloadJsonData(spans: [SpanData]) -> Data?{
        let exportRequest = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
          $0.resourceSpans = SpanAdapter.toProtoResourceSpans(spanDataList: spans)
        }
        
        do {
            let jsonData = try exportRequest.jsonUTF8Data()
            let span = try JSONDecoder().decode(OtlpSpan.self, from: jsonData)
            let envelopeData = try JSONEncoder().encode(span).gzipped()
            return envelopeData
        } catch {
            IMQA.logger.warning("Function::requestSpanPayloadJsonData::jsonUTF8Data Convert Error")
        }
        return nil
    }
}

extension PayloadEnvelope<[LogPayload]> {
    init(data: [LogPayload], resource: ResourcePayload, metadata: MetadataPayload) {
        type = "logs"
        self.data["logs"] = data
        self.resource = resource
        self.metadata = metadata
    }
}

extension PayloadEnvelope<[SpanPayload]> {
    init(spans: [SpanPayload], spanSnapshots: [SpanPayload], resource: ResourcePayload, metadata: MetadataPayload) {
        type = "spans"
        self.data["spans"] = spans
        self.data["span_snapshots"] = spanSnapshots
        self.resource = resource
        self.metadata = metadata
    }
}


//        let attrbute1 = LogAttribute(key: "service.name", value: LogAttribute.Value(stringValue: Bundle.appName))
//        let attrbute2 = LogAttribute(key: "http.user_agent", value: LogAttribute.Value(stringValue: "IMQA.swift"))
//        let attrbute3 = LogAttribute(key: "service.name", value: LogAttribute.Value(stringValue: Bundle.appName))
//        var resource:LogResource = LogResource(attributes: [attrbute1,
//                                                            attrbute2,
//                                                            attrbute3],
//                                               droppedAttributesCount: 0)
//        let logPayloads = logs.map { LogPayloadBuilder.build(log: $0) }
//        let scopeLog = ScopeLog(scope: InstrumentationScopeInfo(name: Bundle.appName,
//                                                                version: IMQAMeta.sdkVersion),
//                                logRecords: logPayloads)
//
//        let resourceLogs = [ResourceLog(resource: resource,
//                                       scopeLogs: [scopeLog])]
//        let payload = RequestLogPayload(resourceLogs: resourceLogs)
