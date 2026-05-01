//
//  KeywordSyncManager.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import KeywordDomain
import BaseData

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
            // 서버에 저장된 키워드 데이터
            let request = SearchKeywordRequest(query: "")
            let response = try await keywordService.searchKeyword(request)
            let serverGroups = KeywordMapper.keywordGroups(from: response)
            
            // 로컬에 저장된 키워드 데이터
            let localGroups = try localStore.fetchAll()
            
            // 변경 여부 확인
            guard hasChanges(server: serverGroups, local: localGroups) else {
                logger?.logSuccess(action: action.text + " (변경 없음)")
                return
            }
            
            // 변경 존재 시 로컬 데이터 전부 삭제 후 새 데이터로 교체
            try localStore.replaceAll(with: serverGroups)
            logger?.logSuccess(action: action.text)
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
        }
    }

    private func hasChanges(server: [KeywordGroup], local: [KeywordGroup]) -> Bool {
        // 키워드 데이터 개수가 다를 시
        guard server.count == local.count else { return true }
        
        // 이름 순 정렬 -> 일대일 비교
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
