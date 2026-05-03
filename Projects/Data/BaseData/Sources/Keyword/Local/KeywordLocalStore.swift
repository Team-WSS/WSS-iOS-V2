//
//  KeywordLocalStore.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftData
import BaseDomain

public final class KeywordLocalStore: Sendable {

    private let container: ModelContainer

    public init() throws {
        let schema = Schema(KeywordSchema.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        self.container = try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor func fetchAll() throws -> [KeywordGroup] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<KeywordGroupData>(
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map { Self.toDomain($0) }
    }

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

    @MainActor func isEmpty() throws -> Bool {
        let context = container.mainContext
        let descriptor = FetchDescriptor<KeywordGroupData>()
        let count = try context.fetchCount(descriptor)
        return count == 0
    }

    private static func toDomain(_ entity: KeywordGroupData) -> KeywordGroup {
        let imageURL = URL(string: entity.imageURL)
        let keywords = entity.keywords.map {
            Keyword(id: KeywordID($0.keywordID), name: $0.name)
        }
        return KeywordGroup(name: entity.name, image: imageURL, keywords: keywords)
    }
}
