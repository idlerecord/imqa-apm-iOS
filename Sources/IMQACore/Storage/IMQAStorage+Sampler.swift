//
//  IMQAStorage+Sampler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 1/10/25.
//

public class SessionSamplerRecord: Codable, VVIdenti {
    var sessionId: String
    //쌤플링 하는가 않하는가
    var sampler: Bool
    
    var vvid: String {
        sessionId
    }
    
    init(sessionId: String, sampler: Bool) {
        self.sessionId = sessionId
        self.sampler = sampler
    }
}

public extension IMQAStorage {
    func addSamplerRecord(_ record: SessionSamplerRecord) {
        let storage = IMQAMuti<SessionSamplerRecord>()
       storage.save(record)
    }
    
    func getSamplerRecord(_ sessionId: String) -> SessionSamplerRecord? {
        let storage = IMQAMuti<SessionSamplerRecord>()
        let record = storage.fetch(sessionId)
        return record
    }
}
