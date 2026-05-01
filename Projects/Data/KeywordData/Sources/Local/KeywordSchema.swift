//
//  KeywordSchemaV1.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftData

// 키워드 로컬 캐싱용 SwiftData 스키마
enum KeywordSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            KeywordGroupData.self,
            KeywordData.self
        ]
    }
    
    @Model
    final class KeywordGroupData {
        @Attribute(.unique) var name: String
        var imageURL: String
        @Relationship(deleteRule: .cascade) var keywords: [KeywordData]
        
        init(
            name: String,
            imageURL: String,
            keywords: [KeywordData] = []
        ) {
            self.name = name
            self.imageURL = imageURL
            self.keywords = keywords
        }
    }
    
    @Model
    final class KeywordData {
        @Attribute(.unique) var keywordID: Int
        var name: String
        
        init(
            keywordID: Int,
            name: String
        ) {
            self.keywordID = keywordID
            self.name = name
        }
    }
}

typealias KeywordGroupData = KeywordSchema.KeywordGroupData
typealias KeywordData = KeywordSchema.KeywordData
