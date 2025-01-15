//
//  SessionBasedSampler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 1/10/25.
//

import OpenTelemetrySdk
import OpenTelemetryApi

class SessionBasedSampler: Sampler {
    let storage: IMQAStorage
    static var sampler: Bool = true
    
    func shouldSample(parentContext: OpenTelemetryApi.SpanContext?,
                      traceId: OpenTelemetryApi.TraceId,
                      name: String,
                      kind: OpenTelemetryApi.SpanKind,
                      attributes: [String : OpenTelemetryApi.AttributeValue],
                      parentLinks: [OpenTelemetrySdk.SpanData.Link]) -> any OpenTelemetrySdk.Decision {
        
        if let sessionId = attributes[CommonSpanSemantics.sessionId]?.toString(){
            if let sessionSamplerRecord = storage.getSamplerRecord(sessionId){
                SessionBasedSampler.sampler = sessionSamplerRecord.sampler
                return SampleResult(isSampled: sessionSamplerRecord.sampler)
            }else{
                let randomDouble = Double.random(in: 0.00...1.00)
                if randomDouble <= samplingProbability {
                    storage.addSamplerRecord(SessionSamplerRecord(sessionId: sessionId, sampler: true))
                    SessionBasedSampler.sampler = true
                    return SampleResult(isSampled: true)
                }else{
                    storage.addSamplerRecord(SessionSamplerRecord(sessionId: sessionId, sampler: false))
                    SessionBasedSampler.sampler = true
                    return SampleResult(isSampled: false)
                }
            }
        }else {
            SessionBasedSampler.sampler = false
            return SampleResult(isSampled: false)
        }
    }
    
    
    private let samplingProbability: Double

    init(probability: Double, storage: IMQAStorage) {
        self.samplingProbability = probability
        self.storage = storage
    }

    var description: String {
        return "SessionBasedSampler with probability \(samplingProbability)"
    }
}

class SampleResult: Decision{
    var isSampled: Bool
    
    var attributes: [String : OpenTelemetryApi.AttributeValue] = [:]
    
    init(isSampled: Bool) {
        self.isSampled = isSampled
        self.attributes = [:]
    }
}
