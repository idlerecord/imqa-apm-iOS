//
//  IMQAUploadType.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//
//import GRDB

public enum IMQAUploadType: Int {
    case spans = 0
    case logs
    case crash
}

//extension IMQAUploadType: DatabaseValueConvertible {
//    var databaseValue: DatabaseValue {
//        return self.rawValue.databaseValue
//    }
//
//    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> IMQAUploadType? {
//        guard let rawValue = Int.fromDatabaseValue(dbValue) else {
//            return nil
//        }
//        return IMQAUploadType(rawValue: rawValue)
//    }
//}
