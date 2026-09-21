//
//  NovelInterestUseCaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct NovelInterestUseCaseTests {

    @Test("작품 관심을 정상적으로 추가한다")
    func addInterestSuccess() async throws {
        let mock = MockNovelRepository()
        mock.addInterestResult = .success(())

        let usecase = DefaultNovelInterestUseCase(novelRepository: mock)
        let novelID = NovelID(42)

        try await usecase.add(id: novelID)

        #expect(mock.addedInterestIDs.last == novelID)
        #expect(mock.addedInterestIDs.count == 1)
    }

    @Test("작품 관심 추가에 실패하면 에러를 던진다")
    func addInterestFailureThrows() async {
        let mock = MockNovelRepository()
        mock.addInterestResult = .failure(RepositoryError.unknown)

        let usecase = DefaultNovelInterestUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.add(id: NovelID(1))
        }
    }

    @Test("작품 관심을 정상적으로 삭제한다")
    func removeInterestSuccess() async throws {
        let mock = MockNovelRepository()
        mock.removeInterestResult = .success(())

        let usecase = DefaultNovelInterestUseCase(novelRepository: mock)
        let novelID = NovelID(42)

        try await usecase.remove(id: novelID)

        #expect(mock.removedInterestIDs.last == novelID)
        #expect(mock.removedInterestIDs.count == 1)
    }

    @Test("작품 관심 삭제에 실패하면 에러를 던진다")
    func removeInterestFailureThrows() async {
        let mock = MockNovelRepository()
        mock.removeInterestResult = .failure(RepositoryError.unknown)

        let usecase = DefaultNovelInterestUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.remove(id: NovelID(1))
        }
    }
}

extension NovelInterestUseCaseTests {
    private enum TestError: Error { case networkFail }
}
