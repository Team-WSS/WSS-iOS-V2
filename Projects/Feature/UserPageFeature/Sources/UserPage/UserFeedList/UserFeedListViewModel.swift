//
//  UserFeedListViewModel.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import SocialDomain
import Logger

/// `UserPageView` "활동" 탭 미리보기(최대 5개)에서 "전체보기"로 진입하는 전체 목록 화면.
/// 무한스크롤 페이지네이션·좋아요·신고 로직은 `UserPageViewModel`의 피드 부분과 동일 패턴이지만,
/// 이 화면 전용으로 독립 보유한다(NovelDetailFeature ↔ UserPageFeature도 각자 보유하는 것과 같은 이유).
@MainActor
@Observable
final class UserFeedListViewModel {

    // MARK: - State

    struct State {
        var feeds: [TotalFeed] = []
        var hasNextFeeds = true
        var isLoadingFeeds = false
        var feedsLoadFailed: RepositoryError?

        /// 피드 셀 드롭다운(스포일러/부적절한 표현 신고)의 확인·완료 알럿 — `UserPageViewModel`과 동일 2단 패턴.
        var presentedFeedAlert: FeedAlert?
        var hasActionError = false
    }

    enum FeedAlert: Equatable {
        case reportSpoiler(FeedID)
        case reportImproper(FeedID)
        case reportSpoilerCompleted
        case reportImproperCompleted
    }

    // MARK: - Action

    enum Action {
        case load
        case loadMoreFeeds
        case toggleFeedLike(FeedID)
        case reportSpoilerFeedTapped(FeedID)
        case reportImproperFeedTapped(FeedID)
        case confirmFeedAlert
        case dismissFeedAlert
        case dismissActionErrorToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoadedFirstPage = false
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    /// 마지막 첫 페이지(재조회) 요청 이후 좋아요를 토글한 셀 — 재조회 병합 보호용(`NovelDetailViewModel`과 동일, #236).
    @ObservationIgnored private var likeToggledDuringRefresh: Set<FeedID> = []
    @ObservationIgnored private var feedActionTask: Task<Void, Never>?

    // MARK: - Dependency

    private let userID: UserID
    /// 유저 피드 조회 응답엔 author 정보가 없어 호출 측이 채워야 한다(`FeedDomain` 제약) — 진입 시점에
    /// 이미 로드돼 있던 프로필 값을 그대로 물려받는다.
    private let nickname: String
    private let profileImage: URL?
    private let logger: Logger?

    // FeedDomain
    private let loadUserFeedsUseCase: LoadUserFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase

    // SocialDomain
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    // MARK: - Init

    init(
        userID: UserID,
        nickname: String,
        profileImage: URL?,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) {
        self.userID = userID
        self.nickname = nickname
        self.profileImage = profileImage
        self.loadUserFeedsUseCase = loadUserFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .loadMoreFeeds:
            loadMoreFeeds()
        case .toggleFeedLike(let feedID):
            toggleFeedLike(feedID)
        case .reportSpoilerFeedTapped(let feedID):
            presentFeedAlert(.reportSpoiler(feedID))
        case .reportImproperFeedTapped(let feedID):
            presentFeedAlert(.reportImproper(feedID))
        case .confirmFeedAlert:
            confirmFeedAlert()
        case .dismissFeedAlert:
            state.presentedFeedAlert = nil
        case .dismissActionErrorToast:
            state.hasActionError = false
        }
    }
}

// MARK: - Action Handling

private extension UserFeedListViewModel {
    /// 진입/재진입 로드. onAppear는 재진입마다 불린다(#236, push 재진입 재조회 복원 — V1 parity).
    /// - **첫 로드**: 로딩과 함께 첫 페이지. 실패는 가드를 소진하지 않아 재시도가 열려 있다.
    /// - **재진입**: 스피너·목록 비움 없이 **조용히 첫 페이지를 재조회**해 목록을 교체한다(V1의
    ///   "비우고 처음부터 + 로딩뷰" 대신 — 스크롤·화면 보존 재검토 결과). 실패해도 기존 목록 유지.
    ///   ⚠️ 재조회 성공은 페이지네이션을 첫 페이지로 되돌린다 — 깊이 스크롤한 채 복귀하면 스크롤이
    ///   당겨질 수 있는 감수(알림 목록과 동일).
    func load() {
        guard feedsTask == nil else { return }
        if hasLoadedFirstPage {
            feedsTask = Task { await loadFeedsPage(after: nil, isSilentRefresh: true) }
        } else {
            state.isLoadingFeeds = true
            state.feedsLoadFailed = nil
            feedsTask = Task { await loadFeedsPage(after: nil) }
        }
    }

    /// 다음 페이지. `lastFeedID` 커서는 현재 목록의 마지막 피드.
    func loadMoreFeeds() {
        guard state.hasNextFeeds,
              feedsTask == nil,
              let lastFeedID = state.feeds.last?.feedId else { return }
        state.isLoadingFeeds = true
        feedsTask = Task { await loadFeedsPage(after: lastFeedID) }
    }

    /// 피드 좋아요 토글. `UserPageViewModel`과 동일 패턴(엔티티 정책 위임 + 낙관 반영 + 실패 롤백).
    func toggleFeedLike(_ feedID: FeedID) {
        guard !syncingLikeFeedIDs.contains(feedID),
              let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) else { return }
        let before = state.feeds[index]
        var feed = before
        guard (try? feed.toggleLike()) != nil else { return }

        state.feeds[index] = feed
        syncingLikeFeedIDs.insert(feedID)
        likeToggledDuringRefresh.insert(feedID)
        Task { await syncFeedLike(to: feed.isLiked, feedID: feedID, rollbackTo: before) }
    }

    /// 피드 신고 확인 알럿 표시. 진행 중인 신고가 있으면 무시한다.
    func presentFeedAlert(_ alert: FeedAlert) {
        guard feedActionTask == nil else { return }
        state.presentedFeedAlert = alert
    }

    /// 알럿에서 확정. 접수 완료 알럿(1버튼)의 "확인"은 dismiss로만 들어오므로 여기 오지 않는다.
    func confirmFeedAlert() {
        guard let alert = state.presentedFeedAlert else { return }
        state.presentedFeedAlert = nil
        guard feedActionTask == nil else { return }
        switch alert {
        case .reportSpoiler(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: true) }
        case .reportImproper(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: false) }
        case .reportSpoilerCompleted, .reportImproperCompleted:
            break
        }
    }
}

// MARK: - UseCase Handling

private extension UserFeedListViewModel {
    /// `isSilentRefresh`는 재진입의 조용한 재조회(#236) — 실패해도 기존 목록을 실패 뷰로 덮지 않는다.
    func loadFeedsPage(after lastFeedID: FeedID?, isSilentRefresh: Bool = false) async {
        defer {
            feedsTask = nil
            state.isLoadingFeeds = false
        }
        // 보호 대상 좋아요(요청 시작 시 in-flight + 요청 중 토글) — 첫 페이지 교체에서만 쓴다(#236).
        var likeProtectedIDs = syncingLikeFeedIDs
        if lastFeedID == nil { likeToggledDuringRefresh = [] }

        do {
            let page = try await loadUserFeedsUseCase.execute(
                userID: userID,
                nickname: nickname,
                profileImage: profileImage,
                lastFeedID: lastFeedID ?? FeedID(0)
            )
            // 첫 페이지는 교체, 다음 페이지는 append — 재조회(교체)가 이전 방문의 목록 위에 겹치지 않게.
            if lastFeedID == nil {
                likeProtectedIDs.formUnion(likeToggledDuringRefresh)
                var items = page.items
                // 보호 셀은 좋아요 두 필드만 로컬 우선(`preservingLikeState`) — 통째 교체가 낙관 토글을 되덮지 않게.
                if !likeProtectedIDs.isEmpty {
                    for index in items.indices where likeProtectedIDs.contains(items[index].feedId) {
                        if let local = state.feeds.first(where: { $0.feedId == items[index].feedId }) {
                            items[index] = items[index].preservingLikeState(of: local)
                        }
                    }
                }
                state.feeds = items
                hasLoadedFirstPage = true
            } else {
                state.feeds.append(contentsOf: page.items)
            }
            state.hasNextFeeds = page.hasNext
        } catch {
            if lastFeedID == nil, !isSilentRefresh { state.feedsLoadFailed = (error as? RepositoryError) ?? .unknown }
            logger?.error("UserFeedList 로드 실패: \(String(describing: error))")
        }
    }

    func syncFeedLike(to isLiked: Bool, feedID: FeedID, rollbackTo before: TotalFeed) async {
        defer { syncingLikeFeedIDs.remove(feedID) }
        do {
            if isLiked {
                try await feedLikeUseCase.like(feedID: feedID)
            } else {
                try await feedLikeUseCase.unlike(feedID: feedID)
            }
        } catch {
            if let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) {
                // 좋아요 두 필드만 되돌림 — 재조회가 가져온 최신 본문을 이전 스냅샷으로 물리지 않게(병합과 대칭).
                state.feeds[index] = state.feeds[index].preservingLikeState(of: before)
            }
            logger?.error("UserFeedList 좋아요 동기화 실패: \(String(describing: error))")
        }
    }

    /// 피드 신고. 성공하면 접수 완료 알럿으로 전환한다(신고는 목록에 보이는 변화가 없다).
    func reportFeed(_ feedID: FeedID, spoiler: Bool) async {
        defer { feedActionTask = nil }
        do {
            if spoiler {
                try await reportSpoilerFeedUseCase.execute(id: feedID)
            } else {
                try await reportImproperFeedUseCase.execute(id: feedID)
            }
            state.presentedFeedAlert = spoiler ? .reportSpoilerCompleted : .reportImproperCompleted
        } catch {
            presentActionError(error, context: "피드 신고")
        }
    }

    func presentActionError(_ error: Error, context: String) {
        logger?.error("UserFeedList \(context) 실패: \(String(describing: error))")
        state.hasActionError = true
    }
}
