//
//  DefaultFeedRepositoryTests.swift
//  FeedDataTests
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedData
@testable import FeedDataTesting
import FeedDomain
import BaseDomain
import Networking

@Suite
struct DefaultFeedRepositoryTests {

    // MARK: - submitFeed

    @Test("submitFeed 성공 시 올바른 content와 genres로 service 호출")
    func submitFeed_success_callsServiceWithCorrectParams() async throws {
        let (sut, service, _) = makeRepository()
        let draft = makeDraft(content: "테스트 피드", genre: [.romance, .fantasy])

        try await sut.submitFeed(draft)

        #expect(service.postFeedCallCount == 1)
        #expect(service.postedRequests[0].content == "테스트 피드")
        #expect(service.postedRequests[0].genres.contains("ROMANCE"))
        #expect(service.postedRequests[0].genres.contains("FANTASY"))
    }

    @Test("submitFeed 네트워크 오류 시 RepositoryError 변환")
    func submitFeed_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.submitFeed(makeDraft())
        }
    }

    // MARK: - editFeed

    @Test("editFeed 성공 시 올바른 feedID와 request로 service 호출")
    func editFeed_success_callsServiceWithCorrectParams() async throws {
        let (sut, service, _) = makeRepository()

        try await sut.editFeed(id: FeedID(10), draft: makeDraft(content: "수정된 피드"))

        #expect(service.patchFeedCallCount == 1)
        #expect(service.patchedFeedIDs == [10])
        #expect(service.patchedRequests[0].content == "수정된 피드")
    }

    // MARK: - deleteFeed

    @Test("deleteFeed 성공 시 올바른 feedID로 service 호출")
    func deleteFeed_success_callsServiceWithCorrectFeedID() async throws {
        let (sut, service, _) = makeRepository()

        try await sut.deleteFeed(id: FeedID(5))

        #expect(service.deletedFeedIDs == [5])
        #expect(service.deleteFeedCallCount == 1)
    }

    // MARK: - fetchFeedDetail

    @Test("fetchFeedDetail 성공 시 FeedDetail 반환")
    func fetchFeedDetail_success_returnsFeedDetail() async throws {
        let (sut, service, _) = makeRepository()
        service.getFeedDetailResult = .success(makeFeedDetailResponse(feedId: 1, likeCount: 5, nickname: "작성자"))

        let result = try await sut.fetchFeedDetail(id: FeedID(1))

        #expect(result.id == FeedID(1))
        #expect(result.likeCount == 5)
        #expect(result.author.nickname == "작성자")
    }

    @Test("fetchFeedDetail 네트워크 오류 시 RepositoryError 변환")
    func fetchFeedDetail_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.getFeedDetailResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.fetchFeedDetail(id: FeedID(1))
        }
    }

    @Test("fetchFeedDetail 잘못된 genre 문자열 시 invalidData 반환")
    func fetchFeedDetail_mappingError_throwsInvalidData() async {
        let (sut, service, _) = makeRepository()
        service.getFeedDetailResult = .success(makeFeedDetailResponse(withConnectedNovelGenre: "INVALID_GENRE"))

        await #expect(throws: RepositoryError.invalidData) {
            try await sut.fetchFeedDetail(id: FeedID(1))
        }
    }

    // MARK: - fetchSosoFeeds

    @Test("fetchSosoFeeds 성공 시 Paginated<TotalFeed> 반환")
    func fetchSosoFeeds_success_returnsPaginatedFeeds() async throws {
        let (sut, service, _) = makeRepository()
        service.getSosoFeedsResult = .success(makeFeedListResponse(count: 3, isLoadable: true))

        let result = try await sut.fetchSosoFeeds(option: .all, lastFeedID: FeedID(0))

        #expect(result.items.count == 3)
        #expect(result.hasNext == true)
    }

    @Test("fetchSosoFeeds 네트워크 오류 시 RepositoryError 변환")
    func fetchSosoFeeds_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.getSosoFeedsResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.fetchSosoFeeds(option: .all, lastFeedID: FeedID(0))
        }
    }

    // MARK: - fetchMyFeeds

    @Test("fetchMyFeeds 성공 시 올바른 파라미터로 service 호출")
    func fetchMyFeeds_success_callsServiceWithCorrectParams() async throws {
        let (sut, service, _) = makeRepository()
        service.getMyFeedsResult = .success(makeFeedListResponse(count: 2, isLoadable: false))
        let option = MyFeedOption(genres: [.romance], visibilityType: .publicOnly, sortType: .recent)

        _ = try await sut.fetchMyFeeds(option: option, lastFeedID: FeedID(100))

        #expect(service.getMyFeedsCallCount == 1)
        #expect(service.fetchedMyGenres[0] == ["ROMANCE"])
        #expect(service.fetchedMyVisibilityTypes[0] == "PUBLIC")
        #expect(service.fetchedMySortTypes[0] == "RECENT")
    }

    // MARK: - fetchNovelFeeds

    @Test("fetchNovelFeeds 성공 시 올바른 novelID로 service 호출")
    func fetchNovelFeeds_success_callsServiceWithCorrectNovelID() async throws {
        let (sut, service, _) = makeRepository()
        service.getNovelFeedsResult = .success(makeFeedListResponse(count: 1, isLoadable: false))

        _ = try await sut.fetchNovelFeeds(id: NovelID(7), lastFeedID: FeedID(0))

        #expect(service.fetchedNovelIDs == [7])
        #expect(service.getNovelFeedsCallCount == 1)
    }

    // MARK: - addLike

    @Test("addLike 성공 시 올바른 feedID로 service 호출")
    func addLike_success_callsServiceWithCorrectFeedID() async throws {
        let (sut, service, _) = makeRepository()

        try await sut.addLike(id: FeedID(3))

        #expect(service.likedFeedIDs == [3])
        #expect(service.postLikeCallCount == 1)
    }

    // MARK: - 네트워크 에러 → RepositoryError 변환

    @Test("NetworkingError.responseFailure 401은 authenticationRequired로 변환")
    func networkError_401_convertsToAuthenticationRequired() async {
        let (sut, service, _) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.responseFailure(code: 401, body: nil))

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.submitFeed(makeDraft())
        }
    }

    @Test("NetworkingError.responseFailure 404는 notFound로 변환")
    func networkError_404_convertsToNotFound() async {
        let (sut, service, _) = makeRepository()
        service.postFeedResult = .failure(NetworkingError.responseFailure(code: 404, body: nil))

        await #expect(throws: RepositoryError.notFound) {
            try await sut.submitFeed(makeDraft())
        }
    }
}

// MARK: - Helpers

private extension DefaultFeedRepositoryTests {

    func makeRepository() -> (
        DefaultFeedRepository,
        MockFeedService,
        MockFeedLogger
    ) {
        let service = MockFeedService()
        let logger = MockFeedLogger()
        let sut = DefaultFeedRepository(service: service, logger: logger)
        return (sut, service, logger)
    }

    func makeDraft(
        content: String = "피드 내용",
        genre: [NovelGenre] = [.romance]
    ) -> FeedDraft {
        FeedDraft(
            content: content,
            genre: genre,
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImages: []
        )
    }

    func makeAuthorResponse(nickname: String = "테스트유저") -> AuthorResponse {
        AuthorResponse(userId: 1, nickname: nickname, profileImage: "https://example.com/profile.jpg")
    }

    func makeFeedDetailResponse(
        feedId: Int = 1,
        likeCount: Int = 0,
        nickname: String = "테스트유저",
        withConnectedNovelGenre genre: String? = nil
    ) -> FeedDetailResponse {
        let connectedNovel = genre.map {
            ConnectedNovelDetailResponse(
                id: 1,
                title: "테스트 소설",
                genre: $0,
                rating: nil,
                thumbnailImage: "https://example.com/novel.jpg",
                description: "소설 설명",
                feedWriterRating: nil
            )
        }
        return FeedDetailResponse(
            feedId: feedId,
            author: makeAuthorResponse(nickname: nickname),
            createdDate: "2026-04-23",
            isModified: false,
            feedContent: "피드 내용",
            feedImageURLs: [],
            connectedNovel: connectedNovel,
            likeCount: likeCount,
            isLiked: false,
            commentCount: 0
        )
    }

    func makeTotalFeedResponse(feedId: Int = 1) -> TotalFeedResponse {
        TotalFeedResponse(
            feedId: feedId,
            createdDate: "2026-04-23",
            content: "피드 내용",
            author: makeAuthorResponse(),
            likeCount: 0,
            isLiked: false,
            commentCount: 0,
            connectedNovel: nil,
            isSpoiler: false,
            isModified: false,
            isPublic: true,
            thumbnailImageURL: nil,
            imageCount: 0
        )
    }

    func makeFeedListResponse(count: Int, isLoadable: Bool) -> FeedListResponse {
        let feeds = (1...max(1, count)).map { makeTotalFeedResponse(feedId: $0) }
        return FeedListResponse(
            feeds: count == 0 ? [] : feeds,
            isLoadable: isLoadable
        )
    }
}
