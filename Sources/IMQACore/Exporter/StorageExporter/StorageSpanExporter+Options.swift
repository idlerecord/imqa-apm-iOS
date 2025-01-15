//
//  StorageSpanExporter+Options.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/11.
//

extension StorageSpanExporter {
    class Options {

        let storage: IMQAStorage
        let validators: [SpanDataValidator]

        init(storage: IMQAStorage, validators: [SpanDataValidator] = .default) {
            self.storage = storage
            self.validators = validators
        }
    }
}
