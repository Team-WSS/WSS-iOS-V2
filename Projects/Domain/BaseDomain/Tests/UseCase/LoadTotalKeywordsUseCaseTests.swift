//
//  LoadTotalKeywordsUseCaseTests.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import BaseDomainTesting

@Suite("전체 키워드 불러오기")
struct LoadTotalKeywordsUseCaseTests {

    private let regression = Keyword(id: KeywordID(11), name: "회귀")

    @Test("처음 불러오기에 성공하면 동기화하지 않는다")
    func firstLoadSucceedsWithoutSync() async throws {
        let repository = MockKeywordRepository()
        repository.fetchKeywordsResult = .success([KeywordGroup(category: .material, keywords: [regression])])

        let groups = try await DefaultLoadTotalKeywordsUseCase(keywordRepository: repository).execute()

        #expect(groups.flatMap(\.keywords) == [regression])
        #expect(repository.syncKeywordsCallCount == 0)
    }

    @Test("불러오기에 실패하면 동기화한 뒤 다시 불러온 결과를 준다")
    func failedLoadSyncsAndLoadsAgain() async throws {
        let repository = MockKeywordRepository()
        repository.fetchKeywordsResult = .failure(.notFound)
        repository.fetchKeywordsResultAfterSync = .success([KeywordGroup(category: .material, keywords: [regression])])

        let groups = try await DefaultLoadTotalKeywordsUseCase(keywordRepository: repository).execute()

        #expect(groups.flatMap(\.keywords) == [regression])
    }

    @Test("동기화한 뒤에도 실패하면 그 에러를 전한다")
    func failedAfterSyncPassesError() async {
        let repository = MockKeywordRepository()
        repository.fetchKeywordsResult = .failure(.notFound)
        repository.fetchKeywordsResultAfterSync = .failure(.networkUnavailable)
        let useCase = DefaultLoadTotalKeywordsUseCase(keywordRepository: repository)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.execute()
        }
    }
}
