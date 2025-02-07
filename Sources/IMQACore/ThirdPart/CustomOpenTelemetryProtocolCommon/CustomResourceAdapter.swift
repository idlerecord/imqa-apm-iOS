//
//  CustomResourceAdapter.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/6/25.
//

import Foundation
import OpenTelemetrySdk

public struct CustomResourceAdapter {
  public static func toProtoResource(resource: Resource) -> Opentelemetry_Proto_Resource_V1_Resource {
    var outputResource = Opentelemetry_Proto_Resource_V1_Resource()
    resource.attributes.forEach {
      let protoAttribute = CustomCommonAdapter.toProtoAttribute(key: $0.key, attributeValue: $0.value)
      outputResource.attributes.append(protoAttribute)
    }
    return outputResource
  }
}
