//
//  KeywordSyncManager.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

// 서버 키워드 데이터 + 로컬 SwiftData 동기화 Manager
public final class KeywordSyncManager {

    private let keywordService: KeywordService
    private let localStore: KeywordLocalStore
    private let logger: DataLogger?

    init(
        keywordService: KeywordService,
        localStore: KeywordLocalStore,
        logger: DataLogger?
    ) {
        self.keywordService = keywordService
        self.localStore = localStore
        self.logger = logger
    }

    @MainActor
    public func syncIfNeeded() async {
        let action = KeywordAction.sync

        do {
            let request = SearchKeywordRequest(query: "")
            let response = try await keywordService.searchKeyword(request)
            let serverGroups = KeywordMapper.keywordGroups(from: response)

            let localGroups = try localStore.fetchAll()

            guard hasChanges(server: serverGroups, local: localGroups) else {
                logger?.logSuccess(action: action.text + " (변경 없음)")
                return
            }

            try localStore.replaceAll(with: serverGroups)
            logger?.logSuccess(action: action.text)
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
        }
    }

    private func hasChanges(server: [KeywordGroup], local: [KeywordGroup]) -> Bool {
        guard server.count == local.count else { return true }

        for (s, l) in zip(server.sorted(by: { $0.name < $1.name }),
                          local.sorted(by: { $0.name < $1.name })) {
            if s.name != l.name { return true }
            if s.keywords.count != l.keywords.count { return true }

            let serverIDs = Set(s.keywords.map { $0.id })
            let localIDs = Set(l.keywords.map { $0.id })
            if serverIDs != localIDs { return true }
        }

        return false
    }
}
