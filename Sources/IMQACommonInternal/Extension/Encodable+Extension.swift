//
//  Encodable+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//
import Foundation

public extension Encodable{
    func toString() -> String? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return nil
        } catch {
            
            return nil
        }
    }
}
