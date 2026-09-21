//
//  CreateFeedUseCaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import FeedDomain
import FeedDomainTesting
import BaseDomain
import SwiftUI

@Suite
struct CreateFeedUseCaseTests {

    @Test("피드를 생성하면 레포지토리에 draft와 imageDatas가 전달된다.")
    func createFeedPassesDraft() async throws {
        let mock = MockFeedRepository()
        let usecase = DefaultCreateFeedUseCase(repository: mock)
        let draft = makeFeedDraft()
        let imageDatas = [Data("image1".utf8), Data("image2".utf8)]

        try await usecase.execute(draft, imageDatas: imageDatas)

        #expect(mock.submittedDrafts.count == 1)
        #expect(mock.submittedImageDatas == [imageDatas])
    }

    @Test("피드 생성에 실패하면 에러를 던진다.")
    func createFeedFailureThrows() async {
        let mock = MockFeedRepository()
        mock.submitResult = .failure(RepositoryError.notFound)

        let usecase = DefaultCreateFeedUseCase(repository: mock)

        await #expect(throws: RepositoryError.notFound) {
            try await usecase.execute(makeFeedDraft(), imageDatas: [])
        }
    }
}

extension CreateFeedUseCaseTests {
    private func makeFeedDraft(
        userId: UserID = UserID(1),
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> FeedDraft {
        FeedDraft(
            content: "안녕",
            isSpoiler: true,
            isPrivate: false,
            connectedNovel: nil,
            attachedImages: [])
    }
}
