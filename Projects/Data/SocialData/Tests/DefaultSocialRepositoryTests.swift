//
//  DefaultSocialRepositoryTests.swift
//  SocialDataTests
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import SocialData
@testable import SocialDataTesting
import SocialDomain
import BaseDomain
import BaseData
import Networking

@Suite
struct DefaultSocialRepositoryTests {

    // MARK: - blockUser

    @Test("blockUser 성공 시 올바른 userID로 service 호출")
    func blockUser_success_callsServiceWithCorrectUserID() async throws {
        let (sut, service) = makeRepository()

        try await sut.blockUser(id: UserID(42))

        #expect(service.blockedUserIDs == [42])
        #expect(service.postBlockUserCallCount == 1)
    }

    @Test("blockUser 네트워크 오류 시 RepositoryError 변환")
    func blockUser_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.postBlockUserResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.blockUser(id: UserID(1))
        }
    }

    // MARK: - unblockUser

    @Test("unblockUser 성공 시 올바른 blockID로 service 호출")
    func unblockUser_success_callsServiceWithCorrectBlockID() async throws {
        let (sut, service) = makeRepository()

        try await sut.unblockUser(id: BlockID(7))

        #expect(service.deletedBlockIDs == [7])
        #expect(service.deleteBlockCallCount == 1)
    }

    @Test("unblockUser 네트워크 오류 시 RepositoryError 변환")
    func unblockUser_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.deleteBlockResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.unblockUser(id: BlockID(1))
        }
    }

    // MARK: - loadBlockedUsers

    @Test("loadBlockedUsers 성공 시 BlockedUser 목록 반환")
    func loadBlockedUsers_success_returnsBlockedUsers() async throws {
        let (sut, service) = makeRepository()
        service.getBlockedUsersResult = .success(BlockedUserResponse(blocks: [
            BlockdUser(blockId: 1, userId: 10, nickname: "차단유저", avatarImage: ""),
            BlockdUser(blockId: 2, userId: 20, nickname: "또차단", avatarImage: "")
        ]))

        let result = try await sut.loadBlockedUsers()

        #expect(result.count == 2)
        #expect(result[0].blockID == BlockID(1))
        #expect(result[0].userID == UserID(10))
        #expect(result[0].nickname == "차단유저")
        #expect(result[1].blockID == BlockID(2))
    }

    @Test("loadBlockedUsers 빈 목록 반환")
    func loadBlockedUsers_emptyList_returnsEmptyArray() async throws {
        let (sut, service) = makeRepository()
        service.getBlockedUsersResult = .success(BlockedUserResponse(blocks: []))

        let result = try await sut.loadBlockedUsers()

        #expect(result.isEmpty)
    }

    @Test("loadBlockedUsers 네트워크 오류 시 RepositoryError 변환")
    func loadBlockedUsers_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.getBlockedUsersResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.loadBlockedUsers()
        }
    }

    // MARK: - reportSpoilerFeed

    @Test("reportSpoilerFeed 성공")
    func reportSpoilerFeed_success() async throws {
        let (sut, service) = makeRepository()

        try await sut.reportSpoilerFeed(id: FeedID(5))

        #expect(service.reportedSpoilerFeedIDs == [5])
        #expect(service.postReportSpoilerFeedCallCount == 1)
    }

    // MARK: - reportImproperFeed

    @Test("reportImproperFeed 성공")
    func reportImproperFeed_success() async throws {
        let (sut, service) = makeRepository()

        try await sut.reportImproperFeed(id: FeedID(6))

        #expect(service.reportedImproperFeedIDs == [6])
        #expect(service.postReportImproperFeedCallCount == 1)
    }

    // MARK: - reportSpoilerComment

    @Test("reportSpoilerComment 성공")
    func reportSpoilerComment_success() async throws {
        let (sut, service) = makeRepository()

        try await sut.reportSpoilerComment(feedID: FeedID(1), commentID: CommentID(3))

        #expect(service.reportedSpoilerCommentFeedIDs == [1])
        #expect(service.reportedSpoilerCommentIDs == [3])
        #expect(service.postReportSpoilerCommentCallCount == 1)
    }

    // MARK: - reportImproperComment

    @Test("reportImproperComment 성공")
    func reportImproperComment_success() async throws {
        let (sut, service) = makeRepository()

        try await sut.reportImproperComment(feedID: FeedID(1), commentID: CommentID(4))

        #expect(service.reportedImproperCommentFeedIDs == [1])
        #expect(service.reportedImproperCommentIDs == [4])
        #expect(service.postReportImproperCommentCallCount == 1)
    }

    // MARK: - 네트워크 에러 → RepositoryError 변환

    @Test("NetworkingError.responseFailure 401은 authenticationRequired로 변환")
    func networkError_401_convertsToAuthenticationRequired() async {
        let (sut, service) = makeRepository()
        service.postBlockUserResult = .failure(NetworkingError.responseFailure(code: 401, body: nil))

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.blockUser(id: UserID(1))
        }
    }

    @Test("NetworkingError.responseFailure 404는 notFound로 변환")
    func networkError_404_convertsToNotFound() async {
        let (sut, service) = makeRepository()
        service.postBlockUserResult = .failure(NetworkingError.responseFailure(code: 404, body: nil))

        await #expect(throws: RepositoryError.notFound) {
            try await sut.blockUser(id: UserID(1))
        }
    }
}

// MARK: - Helpers

private extension DefaultSocialRepositoryTests {

    func makeRepository() -> (DefaultSocialRepository, MockSocialService) {
        let service = MockSocialService()
        let logger = DataLogger(moduleName: "SocialDataTests", underlying: nil)
        let sut = DefaultSocialRepository(service: service, logger: logger)
        return (sut, service)
    }
}
