//
//  IMQAMeta.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

public class IMQAMeta {
    public static let sdkVersion = "1.0.7"
}

extension IMQAMeta {
    public static var userAgent: String { "IMQA/i/\(sdkVersion)" }
}
