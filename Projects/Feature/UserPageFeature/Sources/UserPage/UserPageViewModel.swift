//
//  UserPageViewModel.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import ProfileDomain
import NovelDomain
import FeedDomain
import SocialDomain
import Logger

@MainActor
@Observable
final class UserPageViewModel {

    // MARK: - State

    struct State {
        var profile: Profile?
        var genrePreferences: [GenrePreference] = []
        var novelPreference: NovelPreference?
        var registeredNovelStats: RegisteredNovelStats?
        var isLoading = false
        var hasLoadError = false
        /// 상대가 프로필을 비공개로 설정해 접근할 수 없는 경우(`RepositoryError.privateProfile`) —
        /// 일반 로드 실패(`hasLoadError`)와 분리해 전용 화면("비공개 프로필이에요")으로 표현한다.
        var isProfilePrivate = false

        var feeds: [TotalFeed] = []
        var hasNextFeeds = true
        var isLoadingFeeds = false
        var feedsLoadFailed = false

        /// 차단 확인 알럿 표시 여부 — 툴바 드롭다운 "차단하기" 진입점.
        var isBlockAlertPresented = false
        var isBlockingUser = false
        /// 차단 성공 신호. View가 `onChange`로 소비해 dismiss한다 — 차단 후엔 이 프로필을 볼 수 없으므로
        /// 화면에 남아있을 이유가 없다(`WSSAlertType.blockUser` 설명: "상대의 프로필을 볼 수 없어요").
        var shouldDismiss = false

        /// 피드 셀 드롭다운(스포일러/부적절한 표현 신고)의 확인·완료 알럿 — `NovelDetailFeature`와 동일 2단 패턴.
        var presentedFeedAlert: FeedAlert?

        /// 차단·피드 신고 실패 공통 에러 토스트 — 둘 다 같은 문구(`WSSToastType.unknownError`)라 하나로 묶는다.
        var hasActionError = false
    }

    /// 피드 셀 신고 알럿의 **의미값**. 카피·버튼 구성 매핑은 View가 한다.
    /// 신고는 확인 → API 성공 → 접수 완료의 2단 알럿이라 완료 케이스가 따로 있다(문구가 종류별로 다름).
    enum FeedAlert: Equatable {
        case reportSpoiler(FeedID)
        case reportImproper(FeedID)
        case reportSpoilerCompleted
        case reportImproperCompleted
    }

    // MARK: - Derived

    var keywordPreferences: [KeywordPreference] {
        state.novelPreference?.keywords ?? []
    }

    /// 장르 취향이 비어있거나 있어도 전부 0개인 경우 → 장르 섹션 자체를 숨긴다. (MypageViewModel과 동일 규칙)
    var hasNoGenrePreferenceData: Bool {
        state.genrePreferences.allSatisfy { $0.count == 0 }
    }

    /// 작품 취향(매력 포인트+키워드) 데이터가 아예 없거나, 장르 취향이 있어도 전부 0개면 → 콘텐츠를 "데이터 없음"으로 대체.
    var hasNoPreferenceData: Bool {
        let hasNoNovelPreference = (state.novelPreference?.attractivePoints.isEmpty ?? true)
            && (state.novelPreference?.keywords.isEmpty ?? true)
        return hasNoNovelPreference || hasNoGenrePreferenceData
    }

    /// "활동" 탭은 미리보기로 최대 5개만 보여준다 — 전체 목록은 별도 화면(`UserFeedListView`, 무한스크롤)에서.
    var visibleFeeds: [TotalFeed] {
        Array(state.feeds.prefix(5))
    }

    /// 6개 이상(=5개 초과)이면 "전체보기" 버튼을 노출한다. 첫 페이지가 정확히 5개 이하로 왔어도
    /// `hasNextFeeds`가 true면 더 있는 것이므로 함께 본다.
    var hasMoreFeeds: Bool {
        state.feeds.count > 5 || state.hasNextFeeds
    }

    // MARK: - Action

    enum Action {
        case load
        case loadFeeds
        case toggleFeedLike(FeedID)
        case blockUserTapped
        case dismissBlockAlert
        case confirmBlockUser
        case reportSpoilerFeedTapped(FeedID)
        case reportImproperFeedTapped(FeedID)
        case confirmFeedAlert
        case dismissFeedAlert
        case dismissActionErrorToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    @ObservationIgnored private var hasLoadedFirstFeeds = false
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    /// 피드 신고는 한 번에 하나만 — 알럿을 거치므로 동시에 두 개가 뜰 일이 없다(`NovelDetailFeature`와 동일).
    @ObservationIgnored private var feedActionTask: Task<Void, Never>?

    // MARK: - Dependency

    private let userID: UserID
    private let logger: Logger?

    // ProfileDomain
    private let loadProfileUseCase: LoadProfileUseCase
    private let loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase
    private let loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase

    // NovelDomain
    private let loadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase

    // FeedDomain
    private let loadUserFeedsUseCase: LoadUserFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase

    // SocialDomain
    private let blockUserUseCase: BlockUserUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    // MARK: - Init

    init(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        blockUserUseCase: BlockUserUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) {
        self.userID = userID
        self.loadProfileUseCase = loadProfileUseCase
        self.loadGenrePreferencesUseCase = loadGenrePreferencesUseCase
        self.loadNovelPreferencesUseCase = loadNovelPreferencesUseCase
        self.loadUserRegisteredNovelStatsUseCase = loadUserRegisteredNovelStatsUseCase
        self.loadUserFeedsUseCase = loadUserFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.blockUserUseCase = blockUserUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .loadFeeds:
            loadFeeds()
        case .toggleFeedLike(let feedID):
            toggleFeedLike(feedID)
        case .blockUserTapped:
            state.isBlockAlertPresented = true
        case .dismissBlockAlert:
            state.isBlockAlertPresented = false
        case .confirmBlockUser:
            confirmBlockUser()
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

private extension UserPageViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadUserPage() }
    }

    /// "활동" 탭 첫 진입 시 지연 로드(`NovelDetailFeature` 피드 탭과 동일 패턴). 미리보기라 첫 페이지만
    /// 가져온다 — 5개 넘게 있으면 전체 목록은 `UserFeedListView`(무한스크롤)로 넘어간다.
    func loadFeeds() {
        guard !hasLoadedFirstFeeds, feedsTask == nil else { return }
        state.isLoadingFeeds = true
        state.feedsLoadFailed = false
        feedsTask = Task { await loadFirstFeedsPage() }
    }

    /// 피드 좋아요 토글. 정책(카운트 증감·음수 방지)은 엔티티 `TotalFeed.toggleLike()`에 위임하고,
    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(NovelDetailFeature와 동일 패턴).
    func toggleFeedLike(_ feedID: FeedID) {
        guard !syncingLikeFeedIDs.contains(feedID),
              let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) else { return }
        let before = state.feeds[index]
        var feed = before
        guard (try? feed.toggleLike()) != nil else { return }

        state.feeds[index] = feed
        syncingLikeFeedIDs.insert(feedID)
        Task { await syncFeedLike(to: feed.isLiked, feedID: feedID, rollbackTo: before) }
    }

    func confirmBlockUser() {
        guard !state.isBlockingUser else { return }
        state.isBlockAlertPresented = false
        state.isBlockingUser = true
        Task { await blockUser() }
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

private extension UserPageViewModel {
    /// 프로필/장르 뱃지/작품 취향/서재 통계를 병렬로 로드한다. 대상은 모두 `ProfileTarget.user(userID)` /
    /// 서재 통계는 `LoadUserRegisteredNovelStatsUseCase(id:)`로 동일한 userID를 사용한다.
    /// 하나가 실패해도(구조적 동시성으로 나머지 자식 태스크는 스코프 종료 시 자동 정리) 화면 전체를 에러로 취급한다.
    func loadUserPage() async {
        defer { loadTask = nil }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            async let profile = loadProfileUseCase.execute(target: .user(userID))
            async let genrePreferences = loadGenrePreferencesUseCase.execute(.user(userID))
            async let novelPreference = loadNovelPreferencesUseCase.execute(.user(userID))
            async let registeredNovelStats = loadUserRegisteredNovelStatsUseCase.execute(id: userID)

            state.profile = try await profile
            state.genrePreferences = try await genrePreferences
            state.novelPreference = try await novelPreference
            state.registeredNovelStats = try await registeredNovelStats
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }

    func loadFirstFeedsPage() async {
        defer {
            feedsTask = nil
            state.isLoadingFeeds = false
        }

        do {
            // 유저 피드 조회는 이 화면(유저 페이지)에서만 일어나므로, 이미 로드된 프로필의
            // 닉네임·프로필 이미지를 그대로 재사용한다(응답에 author 정보가 없어 호출 측이 채워야 함).
            let page = try await loadUserFeedsUseCase.execute(
                userID: userID,
                nickname: state.profile?.nickname ?? "",
                profileImage: state.profile?.characterImage,
                lastFeedID: FeedID(0)
            )
            state.feeds = page.items
            state.hasNextFeeds = page.hasNext
            hasLoadedFirstFeeds = true
        } catch RepositoryError.privateProfile {
            state.isProfilePrivate = true
        } catch {
            state.feedsLoadFailed = true
            logger?.error("UserPage 피드 로드 실패: \(String(describing: error))")
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
                state.feeds[index] = before
            }
            logger?.error("UserPage 피드 좋아요 동기화 실패: \(String(describing: error))")
        }
    }

    func blockUser() async {
        defer { state.isBlockingUser = false }
        do {
            try await blockUserUseCase.execute(id: userID)
            state.shouldDismiss = true
        } catch {
            presentActionError(error, context: "차단")
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
}

// MARK: - Error Mapping

private extension UserPageViewModel {
    func presentError(_ error: Error) {
        guard (error as? RepositoryError) != .privateProfile else {
            state.isProfilePrivate = true
            return
        }
        logger?.error("UserPage 로드 실패: \(String(describing: error))")
        state.hasLoadError = true
    }

    func presentActionError(_ error: Error, context: String) {
        logger?.error("UserPage \(context) 실패: \(String(describing: error))")
        state.hasActionError = true
    }
}
