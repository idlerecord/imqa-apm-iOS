//
//  ResourceSemantics.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/30/24.
//


public struct ResourceSemantics {
    /// sdk를 사용하는 app의 bundleId
    public static let serviceName = "service.name"
    ///sdk를 사용하는 app의 버전
    public static let serviceVersion = "service.version"
    /// sdk의 버전
    public static let imqaSDKVersion = "imqa.agent.version"
    /// device의 system의 이름
    public static let osName = "os.name"
    /// device의 system의 버전
    public static let osVersion = "os.version"
    /// dashboard에 정보를 기재한후 받는 서비스키
    public static let serviceKey = "service.key"
    /// 디바이스 아이디 UUID
    public static let deviceId = "device.id"
    /// 제좌사
    public static let deviceManufacturer = "device.manufacturer"
    /// 브랜드
    public static let deviceBrand = "device.brand"
    /// 모델
    public static let deviceModelIdentifier = "device.model.identifier"
}
