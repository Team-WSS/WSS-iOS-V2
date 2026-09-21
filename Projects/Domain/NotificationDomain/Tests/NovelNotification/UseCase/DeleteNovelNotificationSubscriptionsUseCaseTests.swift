//
//  DeleteNovelNotificationSubscriptionsUseCaseTests.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("DeleteNovelNotificationSubscriptionsUseCase")
struct DeleteNovelNotificationSubscriptionsUseCaseTests {

    @Test("선택한 작품 ID 목록과 알림 타입을 그대로 레포지토리에 전달한다")
    func deletesSubscriptionsWithParameters() async throws {
        let repo = MockNovelNotificationRepository()
        repo.deleteSubscriptionsResult = .success(())

        let sut = DefaultDeleteNovelNotificationSubscriptionsUseCase(repository: repo)

        let novelIDs = [NovelID(1), NovelID(2)]
        try await sut.execute(type: .completion, novelIDs: novelIDs)

        #expect(repo.deleteSubscriptionsCallCount == 1)
        #expect(repo.deletedType == .completion)
        #expect(repo.deletedNovelIDs == novelIDs)
    }

    @Test("삭제 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelNotificationRepository()
        repo.deleteSubscriptionsResult = .failure(.networkUnavailable)

        let sut = DefaultDeleteNovelNotificationSubscriptionsUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(type: .hiatusReturn, novelIDs: [NovelID(1)])
        }

        #expect(repo.deleteSubscriptionsCallCount == 1)
    }
}
