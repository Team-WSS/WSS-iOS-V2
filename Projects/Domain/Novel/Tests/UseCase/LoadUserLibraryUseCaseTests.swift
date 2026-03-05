//
//  LoadUserLibraryUseCaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NovelDomain
@testable import BaseDomain
import NovelDomainTesting

@Suite
struct LoadUserLibraryUseCaseTests {

    @Test("유저 서재 목록을 정상적으로 불러온다")
    func loadUserLibrarySuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeLibraryPage()
        mock.fetchUserLibraryResult = .success((expected, 2))

        let usecase = DefaultLoadUserLibraryUseCase(novelRepository: mock)
        let userID = UserID(1003)

        let result = try await usecase.execute(id: userID)

        #expect(result.0.items.count == expected.items.count)
        #expect(result.0.hasNext == expected.hasNext)
        #expect(mock.fetchedUserLibraryIDs.last == userID)
        #expect(mock.fetchedUserLibraryIDs.count == 1)
    }

    @Test("유저 서재 조회 결과에 전체 작품 수가 포함된다")
    func loadUserLibraryReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .success((makeLibraryPage(), 15))

        let usecase = DefaultLoadUserLibraryUseCase(novelRepository: mock)
        let result = try await usecase.execute(id: UserID(1003))

        #expect(result.1 == 15)
    }

    @Test("유저 서재 조회에 실패하면 에러를 던진다")
    func loadUserLibraryFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .failure(TestError.networkFail)

        let usecase = DefaultLoadUserLibraryUseCase(novelRepository: mock)

        await #expect(throws: TestError.networkFail) {
            try await usecase.execute(id: UserID(1))
        }
    }
}

extension LoadUserLibraryUseCaseTests {

    private enum TestError: Error { case networkFail }

    private func makeLibraryPage() -> Paginated<LibraryNovel> {
        Paginated(
            items: [
                LibraryNovel(
                    id: NovelID(1),
                    title: "어쿠스틱 러브",
                    thumbnailImage: URL(filePath: "https://example.com/image.jpg"),
                    rating: 3.45,
                    isInterested: false,
                    userReview: nil,
                    writtenFeeds: ["이 작품은 너무 재밌어요"]
                )
            ],
            hasNext: true
        )
    }
}
