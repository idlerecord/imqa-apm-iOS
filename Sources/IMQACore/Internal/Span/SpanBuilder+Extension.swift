//
//  SpanBuilder+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//
import Foundation
import IMQAOtelInternal
import OpenTelemetryApi


extension SpanBuilder{
    @discardableResult
    func setAttributes(attributes: [String: AttributeValue]) -> SpanBuilder{
        for (key, value) in attributes {
            self.setAttribute(key: key, value: value)
        }
        return self
    }
    
    func setCommonSpanAttributes(attributes: [String: AttributeValue]) -> SpanBuilder{
        //memory start
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceMemoryTotal,
                                                value: AttributeValue(MemoryModel.memoryTotal))
        
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceMemoryFree,
                                                value: AttributeValue(MemoryModel.memoryFree))
        
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.appMemoryAllocated,
                                                value: AttributeValue(MemoryModel.memoryAllocated))
        //memory end
        
        //cpu start
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceCpuUsage,
                                                value: AttributeValue(CpuModel.AppCPUUsage))
        //cpu end
        
        //device.battery.level
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceBatteryLevel,
                                                value: AttributeValue(BatteryModel.level))
        
        //device.battery.charging
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.deviceBatteryIsCharging,
                                                value: AttributeValue(BatteryModel.isCharging))

        
        
        let vcName = IMQAScreen.name ?? SpanSemantics.CommonValue.noScreenValue
        SpanAttributesUtils.updateCommonAttributes(key: SpanSemantics.Common.screenName,
                                                value: AttributeValue(vcName))
        
        return setAttributes(attributes: attributes)
    }
}
