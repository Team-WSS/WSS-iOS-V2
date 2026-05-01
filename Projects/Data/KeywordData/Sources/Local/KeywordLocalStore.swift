//
//  KeywordLocalStore.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftData
import KeywordDomain
import BaseDomain

public final class KeywordLocalStore: Sendable {

    private let container: ModelContainer

    public init() throws {
        let schema = Schema(KeywordSchema.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        self.container = try ModelContainer(for: schema, configurations: [config])
    }

    // 로컬에서 키워드를 전부 가져온다.
    @MainActor func fetchAll() throws -> [KeywordGroup] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<KeywordGroupData>(
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map { Self.toDomain($0) }
    }

    // 로컬에서 특정 query를 검색해 키워드를 가져온다.
    @MainActor func search(_ query: String) throws -> [KeywordGroup] {
        let allGroups = try fetchAll()

        if query.isEmpty { return allGroups }

        return allGroups.compactMap { group in
            let matched = group.keywords.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
            guard !matched.isEmpty else { return nil }
            return KeywordGroup(name: group.name, image: group.image, keywords: matched)
        }
    }

    // 로컬에 있는 키워드를 groups로 모두 교체한다.
    @MainActor func replaceAll(with groups: [KeywordGroup]) throws {
        let context = container.mainContext

        try context.delete(model: KeywordGroupData.self)

        for group in groups {
            let keywordEntities = group.keywords.map {
                KeywordData(keywordID: $0.id.value, name: $0.name)
            }
            let groupEntity = KeywordGroupData(
                name: group.name,
                imageURL: group.image?.absoluteString ?? "",
                keywords: keywordEntities
            )
            context.insert(groupEntity)
        }

        try context.save()
    }

    // 로컬에 있는 키워드의 존재유무를 확인한다.
    @MainActor func isEmpty() throws -> Bool {
        let context = container.mainContext
        let descriptor = FetchDescriptor<KeywordGroupData>()
        let count = try context.fetchCount(descriptor)
        return count == 0
    }
    
    // 로컬 데이터에 저장된 키워드를 Domain Entity로 변환한다.
    private static func toDomain(_ entity: KeywordGroupData) -> KeywordGroup {
        let imageURL = URL(string: entity.imageURL)
        let keywords = entity.keywords.map {
            Keyword(id: KeywordID($0.keywordID), name: $0.name)
        }
        return KeywordGroup(name: entity.name, image: imageURL, keywords: keywords)
    }
}
