//
//  DefaultFeedRepositoryTests.swift
//  FeedDataTests
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing
@testable import FeedData
@testable import FeedDataTesting
import FeedDomain
import BaseDomain
import Networking

@Suite
struct DefaultFeedRepositoryTests {

    // MARK: - submitFeed

    @Test("submitFeed 성공 시 올바른 feedContent로 service 호출")
    func submitFeed_success_callsServiceWithCorrectParams() async throws {
        let (sut, service) = makeRepository()
        let draft = makeDraft(content: "테스트 피드")

        try await sut.submitFeed(draft, imageDatas: [])

        #expect(service.postFeedCallCount == 1)
        #expect(service.postedRequests[0].feedContent == "테스트 피드")
        #expect(service.postedRequests[0].imageDatas == [])
    }

    @Test("submitFeed 시 디코딩 불가한 데이터는 압축기를 거쳐도 원본 그대로 전달된다")
    func submitFeed_nonImageData_passesThroughUncompressed() async throws {
        let (sut, service) = makeRepository()
        // 이미지로 디코딩되지 않는 데이터는 압축기가 원본을 그대로 반환한다.
        let imageDatas = [Data("image1".utf8), Data("image2".utf8)]

        try await sut.submitFeed(makeDraft(), imageDatas: imageDatas)

        #expect(service.postedRequests[0].imageDatas == imageDatas)
    }

    @Test("submitFeed 네트워크 오류 시 RepositoryError 변환")
    func submitFeed_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.submitFeed(makeDraft(), imageDatas: [])
        }
    }

    // MARK: - editFeed

    @Test("editFeed 성공 시 올바른 feedID와 request로 service 호출")
    func editFeed_success_callsServiceWithCorrectParams() async throws {
        let (sut, service) = makeRepository()
        // 이미지로 디코딩되지 않는 데이터는 압축기가 원본을 그대로 반환한다.
        let imageDatas = [Data("edited".utf8)]

        try await sut.editFeed(id: FeedID(10), draft: makeDraft(content: "수정된 피드"), imageDatas: imageDatas)

        #expect(service.patchFeedCallCount == 1)
        #expect(service.patchedFeedIDs == [10])
        #expect(service.patchedRequests[0].feedContent == "수정된 피드")
        #expect(service.patchedRequests[0].imageDatas == imageDatas)
    }

    // MARK: - deleteFeed

    @Test("deleteFeed 성공 시 올바른 feedID로 service 호출")
    func deleteFeed_success_callsServiceWithCorrectFeedID() async throws {
        let (sut, service) = makeRepository()

        try await sut.deleteFeed(id: FeedID(5))

        #expect(service.deletedFeedIDs == [5])
        #expect(service.deleteFeedCallCount == 1)
    }

    // MARK: - fetchFeedDetail

    @Test("fetchFeedDetail 성공 시 FeedDetail 반환")
    func fetchFeedDetail_success_returnsFeedDetail() async throws {
        let (sut, service) = makeRepository()
        service.getFeedDetailResult = .success(makeFeedDetailResponse(feedId: 1, likeCount: 5, nickname: "작성자"))

        let result = try await sut.fetchFeedDetail(id: FeedID(1))

        #expect(result.id == FeedID(1))
        #expect(result.likeCount == 5)
        #expect(result.author.nickname == "작성자")
    }

    @Test("fetchFeedDetail 네트워크 오류 시 RepositoryError 변환")
    func fetchFeedDetail_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.getFeedDetailResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.fetchFeedDetail(id: FeedID(1))
        }
    }

    @Test("fetchFeedDetail 잘못된 genre 문자열 시 connectedNovel이 nil로 폴백")
    func fetchFeedDetail_invalidGenre_fallsBackToNilConnectedNovel() async throws {
        let (sut, service) = makeRepository()
        service.getFeedDetailResult = .success(makeFeedDetailResponse(withConnectedNovelGenre: "INVALID_GENRE"))

        let result = try await sut.fetchFeedDetail(id: FeedID(1))

        #expect(result.connectedNovel == nil)
    }

    // MARK: - fetchSosoFeeds

    @Test("fetchSosoFeeds 성공 시 Paginated<TotalFeed> 반환")
    func fetchSosoFeeds_success_returnsPaginatedFeeds() async throws {
        let (sut, service) = makeRepository()
        service.getSosoFeedsResult = .success(makeFeedListResponse(count: 3, isLoadable: true))

        let result = try await sut.fetchSosoFeeds(option: .all, lastFeedID: FeedID(0))

        #expect(result.items.count == 3)
        #expect(result.hasNext == true)
    }

    @Test("fetchSosoFeeds 네트워크 오류 시 RepositoryError 변환")
    func fetchSosoFeeds_networkError_throwsRepositoryError() async {
        let (sut, service) = makeRepository()
        service.getSosoFeedsResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.fetchSosoFeeds(option: .all, lastFeedID: FeedID(0))
        }
    }

    // MARK: - fetchMyFeeds

    @Test("fetchMyFeeds 성공 시 올바른 파라미터로 service 호출")
    func fetchMyFeeds_success_callsServiceWithCorrectParams() async throws {
        let (sut, service) = makeRepository()
        service.getMyFeedsResult = .success(makeUserFeedListResponse(count: 2, isLoadable: false))
        let option = MyFeedOption(genres: [.romance], visibilityType: .publicOnly, sortType: .recent)

        _ = try await sut.fetchMyFeeds(option: option, lastFeedID: FeedID(100))

        #expect(service.getMyFeedsCallCount == 1)
        #expect(service.fetchedMyGenres[0] == ["romance"])
        #expect(service.fetchedMyVisibilityTypes[0] == "PUBLIC")
        #expect(service.fetchedMySortTypes[0] == "recent")
    }

    // MARK: - fetchNovelFeeds

    @Test("fetchNovelFeeds 성공 시 올바른 novelID로 service 호출")
    func fetchNovelFeeds_success_callsServiceWithCorrectNovelID() async throws {
        let (sut, service) = makeRepository()
        service.getNovelFeedsResult = .success(makeNovelFeedListResponse(count: 1, isLoadable: false))

        _ = try await sut.fetchNovelFeeds(id: NovelID(7), lastFeedID: FeedID(0))

        #expect(service.fetchedNovelIDs == [7])
        #expect(service.getNovelFeedsCallCount == 1)
    }

    // MARK: - addLike

    @Test("addLike 성공 시 올바른 feedID로 service 호출")
    func addLike_success_callsServiceWithCorrectFeedID() async throws {
        let (sut, service) = makeRepository()

        try await sut.addLike(id: FeedID(3))

        #expect(service.likedFeedIDs == [3])
        #expect(service.postLikeCallCount == 1)
    }

    // MARK: - 네트워크 에러 → RepositoryError 변환

    @Test("NetworkingError.responseFailure 401은 authenticationRequired로 변환")
    func networkError_401_convertsToAuthenticationRequired() async {
        let (sut, service) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.responseFailure(code: 401, body: nil))

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.submitFeed(makeDraft(), imageDatas: [])
        }
    }

    @Test("NetworkingError.responseFailure 404는 notFound로 변환")
    func networkError_404_convertsToNotFound() async {
        let (sut, service) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.responseFailure(code: 404, body: nil))

        await #expect(throws: RepositoryError.notFound) {
            try await sut.submitFeed(makeDraft(), imageDatas: [])
        }
    }
}

// MARK: - Helpers

private extension DefaultFeedRepositoryTests {

    func makeRepository() -> (
        DefaultFeedRepository,
        MockFeedService
    ) {
        let service = MockFeedService()
        let sut = DefaultFeedRepository(service: service)
        return (sut, service)
    }

    func makeDraft(
        content: String = "피드 내용"
    ) -> FeedDraft {
        FeedDraft(
            content: content,
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImages: []
        )
    }

    func makeFeedDetailResponse(
        feedId: Int = 1,
        likeCount: Int = 0,
        nickname: String = "테스트유저",
        withConnectedNovelGenre genre: String? = nil
    ) -> FeedDetailResponse {
        FeedDetailResponse(
            feedId: feedId,
            userId: 1,
            nickname: nickname,
            avatarImage: "https://example.com/profile.jpg",
            createdDate: "2026-04-23",
            feedContent: "피드 내용",
            likeCount: likeCount,
            isLiked: false,
            commentCount: 0,
            novelId: genre.map { _ in 1 },
            title: genre.map { _ in "테스트 소설" },
            novelRatingCount: nil,
            novelRating: nil,
            relevantCategories: nil,
            isSpoiler: false,
            isModified: false,
            isMyFeed: false,
            isPublic: true,
            images: [],
            novelThumbnailImage: genre.map { _ in "https://example.com/novel.jpg" },
            novelGenre: genre,
            novelAuthor: nil,
            feedWriterNovelRating: nil,
            novelDescription: genre.map { _ in "소설 설명" }
        )
    }

    func makeTotalFeedResponse(feedId: Int = 1) -> TotalFeedResponse {
        TotalFeedResponse(
            userId: 1,
            nickname: "테스트유저",
            avatarImage: "https://example.com/profile.jpg",
            feedId: feedId,
            createdDate: "2026-04-23",
            feedContent: "피드 내용",
            likeCount: 0,
            isLiked: false,
            commentCount: 0,
            novelId: nil,
            title: nil,
            novelRatingCount: nil,
            novelRating: nil,
            relevantCategories: nil,
            isSpoiler: false,
            isModified: false,
            isMyFeed: false,
            isPublic: true,
            thumbnailUrl: nil,
            imageCount: 0,
            genreName: nil,
            userNovelRating: nil,
            feedWriterNovelRating: nil
        )
    }

    func makeFeedListResponse(count: Int, isLoadable: Bool) -> FeedListResponse {
        let feeds = (1...max(1, count)).map { makeTotalFeedResponse(feedId: $0) }
        return FeedListResponse(
            category: nil,
            isLoadable: isLoadable,
            feeds: count == 0 ? [] : feeds
        )
    }

    func makeUserFeedResponse(feedId: Int = 1) -> UserFeedResponse {
        UserFeedResponse(
            feedId: feedId,
            feedContent: "피드 내용",
            createdDate: "2026-04-23",
            isSpoiler: false,
            isModified: false,
            likerUsers: [],
            isLiked: false,
            likeCount: 0,
            commentCount: 0,
            novelId: nil,
            title: nil,
            novelRating: nil,
            novelRatingCount: nil,
            relevantCategories: nil,
            isPublic: true,
            genre: nil,
            userNovelRating: nil,
            thumbnailUrl: nil,
            imageCount: 0,
            feedWriterNovelRating: nil
        )
    }

    func makeUserFeedListResponse(count: Int, isLoadable: Bool) -> UserFeedListResponse {
        let feeds = (1...max(1, count)).map { makeUserFeedResponse(feedId: $0) }
        return UserFeedListResponse(
            isLoadable: isLoadable,
            feedsCount: count,
            feeds: count == 0 ? [] : feeds
        )
    }

    func makeNovelFeedResponse(feedId: Int = 1) -> NovelFeedResponse {
        NovelFeedResponse(
            userId: 1,
            nickname: "테스트유저",
            avatarImage: "https://example.com/profile.jpg",
            feedId: feedId,
            createdDate: "2026-04-23",
            feedContent: "피드 내용",
            likeCount: 0,
            isLiked: false,
            commentCount: 0,
            novelId: nil,
            title: nil,
            novelRatingCount: nil,
            novelRating: nil,
            relevantCategories: nil,
            isSpoiler: false,
            isModified: false,
            isMyFeed: false,
            isPublic: true,
            thumbnailUrl: nil,
            imageCount: 0,
            genreName: nil,
            userNovelRating: nil,
            feedWriterNovelRating: nil
        )
    }

    func makeNovelFeedListResponse(count: Int, isLoadable: Bool) -> NovelFeedListResponse {
        let feeds = (1...max(1, count)).map { makeNovelFeedResponse(feedId: $0) }
        return NovelFeedListResponse(
            isLoadable: isLoadable,
            feeds: count == 0 ? [] : feeds
        )
    }
}
