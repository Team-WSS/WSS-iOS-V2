//
//  SosoFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import ProfileDomain
import Logger

enum FeedTab {
    case myFeed
    case sosoFeed
}

@Observable
@MainActor
final class SosoFeedViewModel {

    //MARK: - State

    struct State {
        var selectedTab: FeedTab = .myFeed
        var selectedSosoFeedOption: SosoFeedOption = .all

        var myFeeds: [TotalFeed] = []
        var sosoFeeds: [TotalFeed] = []

        /// 실제 fetch에 사용되는 커밋된 필터.
        var myFeedOption: MyFeedOption = MyFeedOption(
            genres: NovelGenre.allCases,
            visibilityType: .all,
            sortType: .recent
        )

        /// 필터 시트가 편집하는 임시 버퍼. CTA로 commit 되기 전까지 fetch에 영향 없음.
        var myFeedOptionDraft: MyFeedOption = MyFeedOption(
            genres: NovelGenre.allCases,
            visibilityType: .all,
            sortType: .recent
        )

        var hasMoreMyFeeds: Bool = true
        var hasMoreSosoFeeds: Bool = true

        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case selectTab(FeedTab)
        case selectSosoFeedOption(SosoFeedOption)
        case load
        case loadMore
        case toggleLike(FeedID)
        case toggleMyFeedSort

        // 필터 시트
        case resetMyFeedFilterDraft
        case toggleMyFeedFilterGenre(NovelGenre)
        case toggleMyFeedFilterPublic
        case toggleMyFeedFilterPrivate
        case applyMyFeedFilter
    }

    //MARK: - Filter Selection Helpers

    var isMyFeedFilterPublicSelected: Bool {
        state.myFeedOptionDraft.visibilityType != .privateOnly
    }

    var isMyFeedFilterPrivateSelected: Bool {
        state.myFeedOptionDraft.visibilityType != .publicOnly
    }

    func isMyFeedFilterGenreSelected(_ genre: NovelGenre) -> Bool {
        state.myFeedOptionDraft.genres.contains(genre)
    }

    // MARK: - Properties

    private(set) var state: State

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase
    private let logger: Logger?

    /// "내 피드" 목록 API가 작성자 정보(닉네임/프로필 이미지)를 내려주지 않아, 별도로 받아온 내 프로필로 채워 넣는다.
    /// 탭을 오갈 때마다 다시 조회하지 않도록 캐시한다.
    private var cachedMyProfile: Profile?

    init(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadsosoFeedsUseCase: LoadSosoFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        logger: Logger? = nil
    ) {
        self.state = State()

        self.loadMyFeedsUseCase = loadMyFeedsUseCase
        self.loadSosoFeedsUseCase = loadsosoFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.loadProfileUseCase = loadProfileUseCase
        self.logger = logger
    }

    //MARK: - Handle

    func handle(_ action: Action) {
        switch action {
        case .selectTab(let tab):
            state.selectedTab = tab
        case .selectSosoFeedOption(let option):
            state.selectedSosoFeedOption = option
            logger?.info("소소피드 옵션: \(option)")
        case .load:
            Task { await loadInitial() }
        case .loadMore:
            Task { await loadMore() }
        case .toggleLike(let feedID):
            Task { await toggleLike(feedID: feedID) }
        case .toggleMyFeedSort:
            toggleMyFeedSort()

        case .resetMyFeedFilterDraft:
            state.myFeedOptionDraft = state.myFeedOption
        case .toggleMyFeedFilterGenre(let genre):
            toggleMyFeedFilterGenre(genre)
        case .toggleMyFeedFilterPublic:
            toggleMyFeedFilterVisibility(togglingPublic: true)
        case .toggleMyFeedFilterPrivate:
            toggleMyFeedFilterVisibility(togglingPublic: false)
        case .applyMyFeedFilter:
            applyMyFeedFilter()
        }
    }

    //MARK: - Load

    /// 현재 탭 기준으로 첫 페이지를 새로 불러온다.
    private func loadInitial() async {
        switch state.selectedTab {
        case .myFeed:
            await loadMyFeeds(refresh: true)
        case .sosoFeed:
            await loadSosoFeeds(refresh: true)
        }
    }

    /// 현재 탭의 다음 페이지를 이어붙인다. hasNext가 false면 무시.
    private func loadMore() async {
        switch state.selectedTab {
        case .myFeed:
            await loadMyFeeds(refresh: false)
        case .sosoFeed:
            await loadSosoFeeds(refresh: false)
        }
    }

    private func loadMyFeeds(refresh: Bool) async {
        if !refresh, !state.hasMoreMyFeeds { return }

        state.isLoading = true
        defer { state.isLoading = false }

        let cursor: FeedID = refresh
            ? FeedID(0)
            : state.myFeeds.last?.feedId ?? FeedID(0)

        do {
            let profile = try await myProfile()
            let page = try await loadMyFeedsUseCase.execute(
                option: state.myFeedOption,
                lastFeedID: cursor
            )
            let items = page.items.map { applying(profile, to: $0) }
            state.myFeeds = refresh ? items : state.myFeeds + items
            state.hasMoreMyFeeds = page.hasNext
        } catch {
            state.errorMessage = "내 피드를 불러오지 못했어요."
        }
    }

    /// 캐시된 내 프로필이 있으면 재사용하고, 없으면 조회해 캐시한다.
    private func myProfile() async throws(RepositoryError) -> Profile {
        if let cachedMyProfile { return cachedMyProfile }
        let profile = try await loadProfileUseCase.execute(target: .me)
        cachedMyProfile = profile
        return profile
    }

    /// `fetchMyFeeds` 응답엔 작성자 닉네임/프로필 이미지가 없어(FeedData 쪽 DTO 자체가 안 내려줌),
    /// 별도로 받아온 내 프로필 정보로 채워 넣는다. userId는 이미 올바르게 채워져 있으므로 유지한다.
    private func applying(_ profile: Profile, to feed: TotalFeed) -> TotalFeed {
        TotalFeed(
            feedId: feed.feedId,
            createdDate: feed.createdDate,
            content: feed.content,
            author: Author(
                userId: feed.author.userId,
                nickname: profile.nickname,
                profileImage: profile.characterImage
            ),
            likeCount: feed.likeCount,
            isLiked: feed.isLiked,
            commentCount: feed.commentCount,
            connectedNovel: feed.connectedNovel,
            isSpoiler: feed.isSpoiler,
            isModified: feed.isModified,
            isPublic: feed.isPublic,
            thumbnailImageURL: feed.thumbnailImageURL,
            imageCount: feed.imageCount
        )
    }

    private func loadSosoFeeds(refresh: Bool) async {
        if !refresh, !state.hasMoreSosoFeeds { return }

        state.isLoading = true
        defer { state.isLoading = false }

        let cursor: FeedID = refresh
            ? FeedID(0)
            : state.sosoFeeds.last?.feedId ?? FeedID(0)

        do {
            let page = try await loadSosoFeedsUseCase.execute(
                option: state.selectedSosoFeedOption,
                lastFeedID: cursor
            )
            state.sosoFeeds = refresh ? page.items : state.sosoFeeds + page.items
            state.hasMoreSosoFeeds = page.hasNext
        } catch {
            state.errorMessage = "소소피드를 불러오지 못했어요."
        }
    }

    //MARK: - Sort

    private func toggleMyFeedSort() {
        let draft = state.myFeedOption
        let nextSortType: SortType = draft.sortType == .recent ? .old : .recent

        state.myFeedOption = MyFeedOption(
            genres: draft.genres,
            visibilityType: draft.visibilityType,
            sortType: nextSortType
        )
        logger?.info("내 피드 정렬: \(nextSortType)")
        Task { await loadMyFeeds(refresh: true) }
    }

    //MARK: - Like

    /// 낙관적 업데이트: 먼저 엔티티의 toggleLike()로 즉시 UI 반영,
    /// 서버 호출이 실패하면 동일 토글을 다시 실행해 이전 상태로 되돌린다.
    private func toggleLike(feedID: FeedID) async {
        let wasLiked = state.myFeeds.first(where: { $0.feedId == feedID })?.isLiked
            ?? state.sosoFeeds.first(where: { $0.feedId == feedID })?.isLiked

        guard let wasLiked else { return }

        toggleLikeLocally(feedID: feedID)

        do {
            if wasLiked {
                try await feedLikeUseCase.unlike(feedID: feedID)
            } else {
                try await feedLikeUseCase.like(feedID: feedID)
            }
        } catch {
            toggleLikeLocally(feedID: feedID)
            state.errorMessage = "좋아요 처리에 실패했어요."
        }
    }

    private func toggleLikeLocally(feedID: FeedID) {
        if let index = state.myFeeds.firstIndex(where: { $0.feedId == feedID }) {
            try? state.myFeeds[index].toggleLike()
        }
        if let index = state.sosoFeeds.firstIndex(where: { $0.feedId == feedID }) {
            try? state.sosoFeeds[index].toggleLike()
        }
    }

    //MARK: - Filter Draft

    /// 필터 시트의 draft를 실제 fetch에 쓰는 커밋된 필터로 반영하고 재조회한다.
    private func applyMyFeedFilter() {
        state.myFeedOption = state.myFeedOptionDraft
        logger?.info("\(state.myFeedOption.genres.map { $0.displayName }), \(state.myFeedOption.visibilityType)")
        Task { await loadMyFeeds(refresh: true) }
    }

    private func toggleMyFeedFilterGenre(_ genre: NovelGenre) {
        let draft = state.myFeedOptionDraft
        let newGenres: [NovelGenre] = draft.genres.contains(genre)
            ? draft.genres.filter { $0 != genre }
            : draft.genres + [genre]

        state.myFeedOptionDraft = MyFeedOption(
            genres: newGenres,
            visibilityType: draft.visibilityType,
            sortType: draft.sortType
        )
    }

    /// 공개/비공개 체크박스는 독립 토글이지만 둘 다 해제되는 상태는 허용하지 않는다(무시).
    private func toggleMyFeedFilterVisibility(togglingPublic: Bool) {
        let draft = state.myFeedOptionDraft
        var includesPublic = draft.visibilityType != .privateOnly
        var includesPrivate = draft.visibilityType != .publicOnly

        if togglingPublic {
            includesPublic.toggle()
        } else {
            includesPrivate.toggle()
        }

        guard includesPublic || includesPrivate else { return }

        let nextVisibility: VisibilityType
        if includesPublic, includesPrivate {
            nextVisibility = .all
        } else if includesPublic {
            nextVisibility = .publicOnly
        } else {
            nextVisibility = .privateOnly
        }

        state.myFeedOptionDraft = MyFeedOption(
            genres: draft.genres,
            visibilityType: nextVisibility,
            sortType: draft.sortType
        )
    }
}
