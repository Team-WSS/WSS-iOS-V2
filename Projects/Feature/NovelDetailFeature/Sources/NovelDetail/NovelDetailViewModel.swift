//
//  NovelDetailViewModel.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import NovelDomain
import NovelReviewDomain
import SocialDomain
import Logger
import PushAuthorization
import Analytics

@MainActor
@Observable
final class NovelDetailViewModel {

    // MARK: - State

    struct State {
        /// 작품 상세 집합 정보. 로드 전 nil.
        var information: NovelInformation?
        /// 관심 토글이 반영되는 작품 기본 정보.
        /// `NovelInformation.novel`은 let이라 토글 정책(`Novel.toggleInterest`)을 적용할 수 없어 분리 보유한다.
        var novel: Novel?
        var selectedTab: Tab = .info
        var feeds: [TotalFeed] = []
        var hasNextFeeds = true
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 실패 뷰(`information == nil && !isLoading`)가 스친다.
        var isLoading = true
        /// 본체 로드 실패 시 잡은 에러 종류 — 실패 뷰(`information == nil && !isLoading`)가 문구를
        /// 3분류(서버/일반/네트워크)로 가르는 데 쓴다. 게이트 조건 자체는 information/isLoading이 정한다.
        var loadError: RepositoryError?
        var isLoadingFeeds = false
        /// 피드 로드 실패 시 잡은 에러 종류(첫 페이지·더보기 **공통**, nil이면 실패 아님) — 탭 자리를
        /// 실패 뷰로 대체할지 가르고, 그 뷰 문구를 3분류(서버/일반/네트워크)로 가른다.
        /// ⚠️ 더보기 실패를 여기서 빼고 토스트로 가르지 말 것 — 토스트는 사라지면 재시도 경로가 없다.
        /// 규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약".
        var feedsLoadFailed: RepositoryError?
        var shouldDismiss = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// 어느 서버 호출에서 발생하든 여기로 모이며, View가 `onChange`로 소비한다(`shouldDismiss`와 대칭).
        var requiresAuthentication = false
        /// 평가 삭제 확인 알럿 표시 여부 — 삭제 가능 판단(평가 존재)이 필요해 VM이 소유한다.
        var isDeleteReviewAlertPresented = false
        /// 피드 셀 액션(삭제/신고)의 확인·완료 알럿 — 확정 시 실행할 대상 피드를 함께 보관한다.
        var presentedFeedAlert: FeedAlert?
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 작품 본체 로드 실패는 전면 실패 뷰(`information == nil && !isLoading`)가 표현하므로 여기 없다.
        var presentedToast: DetailToast?
        /// 첫 진입 평가 온보딩 오버레이 표시 여부(#221, V1 parity). 앱 전역 1회 — 첫 로드 성공 시
        /// 아직 안 봤으면 세우고, 닫으면 `markSeen` 후 내린다. 스포트라이트 좌표는 View가 상태바를 실측한다.
        var showReviewOnboarding = false
        /// 종 아이콘 탭 → 알림 설정 시트를 열어도 되는지(#193 `SettingFeature.notificationMenuTapped`와
        /// 동일 판단) — VM이 시스템 푸시 권한을 확인해 판단한다(순수 표시 상태가 아니라 VM 판단이 필요).
        var isNotificationSettingSheetPresented = false
        /// 시트 대신 이 알럿(기기 설정 유도)을 띄워야 하는지 — 시스템 푸시 권한이 denied일 때.
        var isPushAuthorizationAlertPresented = false
    }

    enum Tab: CaseIterable, Equatable {
        case info
        case feed
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    /// 실패들은 모두 네트워크 실패로 정상 도달 가능한 경로다(도달 불가 가정으로 뭉치지 않고 맥락을 남긴다).
    /// ⚠️ **피드 로드 실패는 여기 없다** — 첫 페이지든 더보기든 탭 자리에 `NetworkErrorView`(재시도 버튼)로
    /// 표현한다. 남은 토스트는 전부 **사용자 액션의 실패/완료**다(→ Feature CLAUDE.md "로드 실패 표현 계약").
    enum DetailToast: Equatable {
        case interestFailed
        case deleteReviewFailed
        case likeFailed
        case deleteFeedFailed
        case reportFeedFailed
        /// 이미 신고한 피드에 같은 종류의 신고를 다시 시도함(#255 QA, 서버 `REPORT-002`) — `reportFeedFailed`와
        /// 분리해 "이미 신고한 피드예요" 전용 문구로 안내한다.
        case reportFeedAlreadyReported
        /// 평가 삭제 완료 — 결과가 화면 재로드로만 보이면 알아차리기 어려워 성공도 토스트로 알린다.
        case reviewDeleted
        /// ⚠️ 유일하게 네트워크 실패가 아닌 케이스 — 피드 탭 셀 프로필을 탭했는데 그 작성자가 탈퇴한
        /// 유저(`Author.userId == -1`, 서버가 실제 유저 대신 이 값을 내려준다)일 때. 로컬 판정이라
        /// UseCase 호출 자체가 없다(#197 후속, 2026-08-28 — `SosoFeedView`/`NovelDetailFeedTab`이
        /// `userId == nil` 가드만 두고 있었는데 매퍼가 `Int`를 항상 `UserID`로 감싸 nil이 될 일이 없어
        /// 죽은 가드였다).
        case unavailableUser
    }

    /// 피드 셀 액션의 알럿 **의미값**. 카피·버튼 구성 매핑은 View가 한다.
    /// 신고는 확인 → API 성공 → 접수 완료의 2단 알럿이라 완료 케이스가 따로 있다(문구가 종류별로 다름).
    enum FeedAlert: Equatable {
        case deleteFeed(FeedID)
        case reportSpoiler(FeedID)
        case reportImproper(FeedID)
        case reportSpoilerCompleted
        case reportImproperCompleted
    }

    // MARK: - Action

    enum Action {
        case load
        case selectTab(Tab)
        case toggleInterest
        case loadMoreFeeds
        /// 피드 실패 뷰의 재시도 — 첫 페이지부터 다시 세운다.
        case retryFeeds
        /// View가 이 피드로 화면을 떠나기(셀 탭 → 피드 상세, "수정하기" → 수정) 직전에 부른다 —
        /// 돌아오면 그 셀만 상세 API로 맞춘다(`SosoFeedViewModel`과 동일 패턴, #256).
        case feedVisited(FeedID)
        /// 이 화면에서 피드 작성 성공 후 복귀(App 신호 소비) — 피드 섹션을 초기 로드처럼 리셋한다(#256).
        case reloadFeedsForCreatedFeed
        case toggleFeedLike(FeedID)
        case deleteFeedTapped(FeedID)
        case reportSpoilerFeedTapped(FeedID)
        case reportImproperFeedTapped(FeedID)
        case confirmFeedAlert
        case dismissFeedAlert
        case deleteReviewTapped
        case confirmDeleteReview
        case dismissDeleteReviewAlert
        case requestClose
        case dismissToast
        /// 피드 셀 프로필 탭이 탈퇴 유저를 가리킬 때(`unavailableUser` 토스트) — 화면 전환 콜백을
        /// 부르지 않고 여기서 그친다. `NovelDetailFeedTab`이 판정(`Author.accessibleUserId == nil`)해서
        /// `onUnavailableUserProfileTapped()`를 부르면 여기까지 이어진다.
        case userProfileUnavailable
        /// 첫 진입 평가 온보딩 오버레이를 닫는다(어디를 탭하든) — 봤음을 기록해 다시 뜨지 않게 한다.
        case dismissReviewOnboarding
        /// 네비바 종 아이콘 탭 — 시스템 푸시 권한을 먼저 확인한다(#193 `SettingFeature`와 동일 패턴).
        case notificationBellTapped
        case dismissNotificationSettingSheet
        case dismissPushAuthorizationAlert
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    // 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다(NovelReview 교훈).
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var hasLoadedFirstFeeds = false
    @ObservationIgnored private var isSyncingInterest = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    @ObservationIgnored private var deleteReviewTask: Task<Void, Never>?
    /// 피드 삭제/신고는 한 번에 하나만 — 알럿을 거치므로 동시에 두 개가 뜰 일이 없다.
    @ObservationIgnored private var feedActionTask: Task<Void, Never>?
    /// 좋아요는 셀별 독립 동기화 — 같은 피드의 연타만 막고 다른 피드는 병행을 허용한다.
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    /// 다녀온 셀 동기화 Task — 목록 로드(`feedsTask`)와 별개 슬롯(셀 하나를 ID로 교체할 뿐이라 겹쳐도 무해).
    @ObservationIgnored private var cellSyncTask: Task<Void, Never>?
    /// 화면을 떠나며 들어간 피드들 — 복귀 `.load`에서 꺼내 상세로 동기화한다(`SosoFeedViewModel`과 동일 패턴, #256).
    @ObservationIgnored private var pendingSyncFeedIDs: Set<FeedID> = []
    @ObservationIgnored private var isClosing = false
    /// 종 아이콘 탭마다 새로 스폰되는 시스템 권한 조회 Task — 연타 시 이전 조회를 취소해 `requestAuthorization()`
    /// 중복 호출(중복 프롬프트)을 막고, 화면이 닫히면(`close()`) 함께 취소한다.
    @ObservationIgnored private var notificationBellTask: Task<Void, Never>?

    // MARK: - Dependency

    private let novelID: NovelID
    private let logger: Logger?
    private let analyticsTracker: AnalyticsTracker?

    // NovelDomain
    private let loadNovelUseCase: LoadNovelUseCase
    private let novelInterestUseCase: NovelInterestUseCase

    // FeedDomain
    private let loadNovelFeedsUseCase: LoadNovelFeedsUseCase
    /// 다녀온 셀 동기화용(`syncVisitedFeeds`) — 목록 API가 아니라 피드 상세 API로 그 셀 하나만 다시 받는다.
    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase

    // NovelReviewDomain
    private let deleteNovelReviewUseCase: DeleteNovelReviewUseCase

    // SocialDomain
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    // BaseDomain — 첫 진입 평가 온보딩 힌트 1회성 판정/기록(#221).
    private let onboardingHintUseCase: OnboardingHintUseCase

    // PushAuthorization — 종 아이콘 탭 시 시스템 푸시 권한 확인용(#193 SettingFeature와 동일 목적).
    private let pushAuthorizationChecker: PushAuthorizationChecker

    // MARK: - Init

    init(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        deleteNovelReviewUseCase: DeleteNovelReviewUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        onboardingHintUseCase: OnboardingHintUseCase,
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.novelID = novelID
        self.loadNovelUseCase = loadNovelUseCase
        self.novelInterestUseCase = novelInterestUseCase
        self.loadNovelFeedsUseCase = loadNovelFeedsUseCase
        self.loadFeedDetailUseCase = loadFeedDetailUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.deleteFeedUseCase = deleteFeedUseCase
        self.deleteNovelReviewUseCase = deleteNovelReviewUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.onboardingHintUseCase = onboardingHintUseCase
        self.pushAuthorizationChecker = pushAuthorizationChecker
        self.logger = logger
        self.analyticsTracker = analyticsTracker
        self.state = State()
    }

    /// 이벤트 트래킹 pass-through(#249) — `state`를 건드리지 않아 `handle(_:)`을 거치지 않는다.
    func track(_ event: NovelDetailAnalyticsEvent, properties: [String: AnalyticsPropertyValue]? = nil) {
        analyticsTracker?.track(event, properties: properties)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .selectTab(let tab):
            selectTab(tab)
        case .toggleInterest:
            toggleInterest()
        case .loadMoreFeeds:
            loadMoreFeeds()
        case .retryFeeds:
            retryFeeds()
        case .feedVisited(let feedID):
            pendingSyncFeedIDs.insert(feedID)
        case .reloadFeedsForCreatedFeed:
            reloadFeedsForCreatedFeed()
        case .toggleFeedLike(let feedID):
            toggleFeedLike(feedID)
        case .deleteFeedTapped(let feedID):
            presentFeedAlert(.deleteFeed(feedID))
        case .reportSpoilerFeedTapped(let feedID):
            presentFeedAlert(.reportSpoiler(feedID))
        case .reportImproperFeedTapped(let feedID):
            presentFeedAlert(.reportImproper(feedID))
        case .confirmFeedAlert:
            confirmFeedAlert()
        case .dismissFeedAlert:
            state.presentedFeedAlert = nil
        case .deleteReviewTapped:
            presentDeleteReviewAlert()
        case .confirmDeleteReview:
            confirmDeleteReview()
        case .dismissDeleteReviewAlert:
            state.isDeleteReviewAlertPresented = false
        case .requestClose:
            close()
        case .dismissToast:
            state.presentedToast = nil
        case .userProfileUnavailable:
            state.presentedToast = .unavailableUser
        case .dismissReviewOnboarding:
            dismissReviewOnboarding()
        case .notificationBellTapped:
            notificationBellTapped()
        case .dismissNotificationSettingSheet:
            state.isNotificationSettingSheetPresented = false
        case .dismissPushAuthorizationAlert:
            state.isPushAuthorizationAlertPresented = false
        }
    }
}

// MARK: - Action Handling

private extension NovelDetailViewModel {

    /// 진입/재진입 상세 로드. onAppear는 재진입마다 불린다.
    /// - **첫 로드**(`!hasLoaded`): 전면 스피너를 세우고 로드한다.
    /// - **재진입**(`hasLoaded`): 작품 정보는 스피너 없이 **조용히 재조회**해 `information`/`novel`을
    ///   갈아끼운다(평가 화면 등에서 바뀐 유저 평가·별점·집계를 복귀 즉시 반영, 실패해도 기존 화면 유지).
    ///   피드는 목록을 다시 받지 않고 **다녀온 셀만** 상세 API로 동기화한다(`syncVisitedFeeds`, #256 —
    ///   예전의 조용한 전체 재조회(refreshFeeds)는 `size = 보던 개수` window 교체라 그 사이 새 글이 생기면
    ///   기존 글이 창 밖으로 밀려 "사라져 보이는" 실결함이 있어 제거했다. 이 화면발 작성 성공 복귀는
    ///   `.reloadFeedsForCreatedFeed`가 초기 로드식 리셋으로 따로 담당한다).
    /// 실패는 가드(`hasLoaded`)를 소진하지 않아 재진입 시 재시도가 열려 있다.
    func load() {
        if hasLoaded {
            syncVisitedFeeds()
        }
        guard loadTask == nil, !isClosing else { return }
        if !hasLoaded {
            state.isLoading = true
        }
        loadTask = Task { await loadNovel() }
    }

    /// 탭 전환. 피드 탭은 첫 성공 전까지 진입(재탭 포함)마다 첫 페이지 로드를 시도한다.
    func selectTab(_ tab: Tab) {
        track(tab == .info ? .infoTabViewed : .feedTabViewed)
        state.selectedTab = tab
        if tab == .feed, !hasLoadedFirstFeeds, feedsTask == nil, !isClosing {
            // ⚠️ 실패 플래그를 **함께 내려야** 한다 — `NovelDetailFeedTab`이 실패를 목록보다 먼저 판단하므로,
            // 안 내리면 요청이 도는 내내 실패 뷰가 그려지고 그 재시도 버튼은 `retryFeeds()`의
            // `feedsTask == nil` 가드에 막혀 **눌러도 아무 반응이 없다**(느린 망에서 수 초 지속).
            state.feedsLoadFailed = nil
            state.isLoadingFeeds = true
            feedsTask = Task { await loadFeeds(after: nil) }
        }
    }

    /// 관심 토글. 정책(카운트 증감·중복 방지)은 엔티티 `Novel`에 위임하고,
    /// UI에는 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다.
    func toggleInterest() {
        guard !isSyncingInterest, !isClosing, var novel = state.novel else { return }
        track(.interestToggled)
        let before = novel
        novel.toggleInterest()
        // isInterested가 nil이면 엔티티 정책상 변화가 없다(비로그인 등) → 서버 호출도 하지 않는다.
        guard novel.isInterested != before.isInterested else { return }

        state.novel = novel
        isSyncingInterest = true
        Task { await syncInterest(to: novel.isInterested == true, rollbackTo: before) }
    }

    /// 피드 다음 페이지. `lastFeedID` 커서는 현재 목록의 마지막 피드.
    func loadMoreFeeds() {
        guard state.hasNextFeeds,
              feedsTask == nil,
              !isClosing,
              let lastFeedID = state.feeds.last?.feedId else { return }
        state.isLoadingFeeds = true
        feedsTask = Task { await loadFeeds(after: lastFeedID) }
    }

    /// 피드 실패 뷰의 재시도 — **첫 페이지부터 다시 세운다.**
    /// 더보기가 실패했을 때도 이 경로로 오므로 기존 목록을 비워야 같은 피드가 두 번 붙지 않는다.
    func retryFeeds() {
        guard feedsTask == nil, !isClosing else { return }

        state.feeds = []
        state.hasNextFeeds = true
        state.feedsLoadFailed = nil
        hasLoadedFirstFeeds = false
        state.isLoadingFeeds = true
        feedsTask = Task { await loadFeeds(after: nil) }
    }

    /// 이 화면에서 피드 작성 성공 후 복귀 — 피드 섹션을 초기 로드처럼 리셋한다(#256, 새 글이 맨 위).
    /// 진행 중 로드·셀 동기화는 취소하고 슬롯·로딩 표시를 직접 되돌린다(취소된 `loadFeeds`의 defer는
    /// 아무것도 정리하지 않는 불변식이라 — 그 defer에 맡기면 정리가 새 로드를 지운다).
    /// 피드 탭을 보고 있으면 즉시 첫 페이지를 받고, 정보 탭이면("나도 한마디" 발화) 지연 로드에 맡긴다
    /// (`selectTab`의 `!hasLoadedFirstFeeds` 경로가 처리).
    func reloadFeedsForCreatedFeed() {
        guard !isClosing else { return }
        feedsTask?.cancel()
        feedsTask = nil
        cellSyncTask?.cancel()
        cellSyncTask = nil
        pendingSyncFeedIDs = []
        state.feeds = []
        state.hasNextFeeds = true
        state.feedsLoadFailed = nil
        hasLoadedFirstFeeds = false
        if state.selectedTab == .feed {
            state.isLoadingFeeds = true
            feedsTask = Task { await loadFeeds(after: nil) }
        } else {
            state.isLoadingFeeds = false
        }
    }

    /// 피드 좋아요 토글. 정책(카운트 증감·음수 방지)은 엔티티 `TotalFeed.toggleLike()`에 위임하고,
    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(관심 토글과 같은 패턴).
    func toggleFeedLike(_ feedID: FeedID) {
        guard !isClosing,
              !syncingLikeFeedIDs.contains(feedID),
              let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) else { return }
        track(.feedLikeTapped)
        let before = state.feeds[index]
        var feed = before
        // 정책 위반(카운트 음수)이면 반영하지 않는다 — 서버 호출도 없다.
        guard (try? feed.toggleLike()) != nil else { return }

        state.feeds[index] = feed
        syncingLikeFeedIDs.insert(feedID)
        Task { await syncFeedLike(to: feed.isLiked, feedID: feedID, rollbackTo: before) }
    }

    /// 피드 삭제/신고 확인 알럿 표시. 진행 중인 액션이 있으면 무시한다.
    func presentFeedAlert(_ alert: FeedAlert) {
        guard !isClosing, feedActionTask == nil else { return }
        state.presentedFeedAlert = alert
    }

    /// 알럿에서 확정. 접수 완료 알럿(1버튼)의 "확인"은 dismiss로만 들어오므로 여기 오지 않는다.
    func confirmFeedAlert() {
        guard let alert = state.presentedFeedAlert else { return }
        state.presentedFeedAlert = nil
        guard feedActionTask == nil, !isClosing else { return }
        switch alert {
        case .deleteFeed(let feedID):
            feedActionTask = Task { await deleteFeed(feedID) }
        case .reportSpoiler(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: true) }
        case .reportImproper(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: false) }
        case .reportSpoilerCompleted, .reportImproperCompleted:
            break
        }
    }

    /// 평가 삭제 진입(드롭다운). 삭제할 평가가 없으면(미평가·비로그인) 알럿 없이 무시한다 —
    /// 관심 토글의 no-op과 같은 정책.
    func presentDeleteReviewAlert() {
        guard state.information?.userReview != nil,
              deleteReviewTask == nil,
              !isClosing else { return }
        state.isDeleteReviewAlertPresented = true
    }

    /// 알럿에서 삭제 확정.
    func confirmDeleteReview() {
        state.isDeleteReviewAlertPresented = false
        guard deleteReviewTask == nil, !isClosing else { return }
        deleteReviewTask = Task { await deleteReview() }
    }

    /// 뒤로가기 요청. 진행 중인 로드를 취소하고 닫기 신호만 View로 발화한다.
    func close() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        feedsTask?.cancel()
        cellSyncTask?.cancel()
        deleteReviewTask?.cancel()
        feedActionTask?.cancel()
        notificationBellTask?.cancel()
        state.shouldDismiss = true
    }

    /// 첫 진입 평가 온보딩 오버레이 닫기 — 봤음을 기록해 앱 전역에서 다시 뜨지 않게 한다.
    func dismissReviewOnboarding() {
        guard state.showReviewOnboarding else { return }
        onboardingHintUseCase.markSeen(.novelDetailReview)
        state.showReviewOnboarding = false
    }

    /// 네비바 종 아이콘 탭 — 시트를 열기 전에 시스템 푸시 권한을 확인한다(`SettingFeature.notificationMenuTapped`와
    /// 동일 판단, #193). **denied면 시트를 열지 않고 기기 설정 유도 알럿만 띄운다**(사용자 확정 — 권한이 없는
    /// 채로 그 시트에 들어갈 이유가 없다). `notDetermined`면 시스템 프롬프트를 띄운 뒤 시트로 이동한다(알럿은
    /// 안 띄움). 연타 시 이전 조회를 취소해 `requestAuthorization()` 중복 호출을 막는다.
    func notificationBellTapped() {
        guard !isClosing else { return }
        notificationBellTask?.cancel()
        notificationBellTask = Task { [weak self] in
            guard let self else { return }
            switch await pushAuthorizationChecker.authorizationStatus() {
            case .authorized:
                guard !isClosing, !Task.isCancelled else { return }
                state.isNotificationSettingSheetPresented = true
            case .notDetermined:
                _ = await pushAuthorizationChecker.requestAuthorization()
                guard !isClosing, !Task.isCancelled else { return }
                state.isNotificationSettingSheetPresented = true
            case .denied:
                guard !isClosing, !Task.isCancelled else { return }
                state.isPushAuthorizationAlertPresented = true
            }
        }
    }
}

// MARK: - UseCase Handling

private extension NovelDetailViewModel {

    func loadNovel() async {
        defer {
            loadTask = nil
            if !isClosing { state.isLoading = false }
        }
        do {
            let information = try await loadNovelUseCase.execute(id: novelID)
            guard !isClosing, !Task.isCancelled else { return }
            let isFirstLoad = !hasLoaded
            state.information = information
            state.novel = information.novel
            state.loadError = nil
            hasLoaded = true
            // 첫 로드 성공 시에만 온보딩을 판정한다(재진입 조용한 갱신에선 다시 뜨지 않게).
            if isFirstLoad, !onboardingHintUseCase.hasSeen(.novelDetailReview) {
                state.showReviewOnboarding = true
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰 대신 로그인 유도로 일원화한다(이 catch는 presentError를 안 거치므로 직접 감지).
            if routeToLoginIfAuthenticationRequired(error) { return }
            // 본체 로드 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
            // 잡은 에러 종류를 실어보내 실패 뷰가 문구를 3분류로 가른다.
            state.loadError = (error as? RepositoryError) ?? .unknown
            logger?.error("NovelDetail 실패(novelLoad): \(String(describing: error))")
        }
    }

    /// 피드 목록 로드. `after == nil`이면 첫 페이지(커서 0 — 서버 규약).
    ///
    /// 취소된 로드의 defer는 **아무것도 정리하지 않는다**(#256 불변식, `SosoFeedViewModel.loadFeeds`와 동일) —
    /// 정리하면 자기를 취소하고 곧바로 재대입한 새 로드(`reloadFeedsForCreatedFeed`)의 슬롯·로딩 표시를 지운다.
    /// 재대입 없이 취소만 하는 호출자(`deleteFeed`)는 취소 직후 슬롯·로딩 표시를 스스로 되돌린다.
    func loadFeeds(after lastFeedID: FeedID?) async {
        defer {
            if !Task.isCancelled {
                feedsTask = nil
                if !isClosing { state.isLoadingFeeds = false }
            }
        }
        do {
            let page = try await loadNovelFeedsUseCase.execute(
                novelID: novelID,
                lastFeedID: lastFeedID ?? FeedID(0),
                size: nil
            )
            guard !isClosing, !Task.isCancelled else { return }
            state.feeds.append(contentsOf: page.items)
            state.hasNextFeeds = page.hasNext
            state.feedsLoadFailed = nil
            if lastFeedID == nil { hasLoadedFirstFeeds = true }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다(loadNovel/loadDraft와 대칭).
            if routeToLoginIfAuthenticationRequired(error) { return }

            // 첫 페이지든 더보기든 **탭 자리를 실패 뷰(재시도 버튼)로 대체**한다 — 사용자에겐 둘 다
            // "피드를 못 불러왔다"는 같은 사건이고, 토스트는 사라지면 다시 부를 방법이 없다.
            // (규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약")
            state.feedsLoadFailed = (error as? RepositoryError) ?? .unknown
            logger?.error("피드 로드 실패(\(lastFeedID == nil ? "첫 페이지" : "더보기")): \(String(describing: error))")
        }
    }

    /// 목록에서 다녀온 피드(셀 탭 → 피드 상세, "수정하기" → 수정)만 상세 API로 맞춘다(#256 —
    /// 예전 조용한 전체 재조회(refreshFeeds)의 대체, `SosoFeedViewModel.syncVisitedFeeds`와 동일 패턴).
    /// 로딩·토스트 없이 그 셀만 교체하고, 상세가 `.notFound`/`.forbidden`(삭제·숨김·차단)이면 셀을 제거한다.
    /// 그 외 실패는 셀을 그대로 둔다(잘못 지우는 것보다 낫다 — 단 인증 만료는 로그인 라우팅에 합류).
    /// 이전 동기화가 도는 동안 새로 쌓인 pending은 그 동기화가 끝나는 즉시 이어서 소비한다(아래 drain) —
    /// 다음 복귀까지 미루면 사용자가 이 화면에 머무는 동안 그 셀이 영영 안 맞는 창이 생긴다.
    func syncVisitedFeeds() {
        guard cellSyncTask == nil, !pendingSyncFeedIDs.isEmpty, !isClosing else { return }
        let feedIDs = pendingSyncFeedIDs
        pendingSyncFeedIDs = []
        cellSyncTask = Task {
            for feedID in feedIDs {
                await syncCell(feedID)
                // 취소된 태스크는 아무것도 정리하지 않는다 — 취소한 쪽이 슬롯·대기열을 정리하거나(reload 계열)
                // isClosing 가드가 이후 진입을 막는다(close).
                if Task.isCancelled { return }
            }
            // drain: 도는 동안 새로 다녀온 셀이 쌓였으면 즉시 이어서 동기화한다. 슬롯을 먼저 비워야
            // 재귀 호출의 `cellSyncTask == nil` 가드를 통과한다(defer로 두면 새로 대입된 다음 태스크를
            // defer가 도로 지우는 순서 함정이 있어 명시로 정리).
            cellSyncTask = nil
            syncVisitedFeeds()
        }
    }

    func syncCell(_ feedID: FeedID) async {
        do {
            let detail = try await loadFeedDetailUseCase.execute(feedID: feedID)
            guard !isClosing, !Task.isCancelled else { return }
            if let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) {
                let local = state.feeds[index]
                let updated = local.updated(from: detail)
                // 좋아요 서버 동기화가 아직 도는 셀은 상세 응답이 토글 이전 스냅샷일 수 있다 —
                // **좋아요 두 필드만** 로컬 우선(`preservingLikeState`). 최종 정합은 syncFeedLike가 마무리.
                state.feeds[index] = syncingLikeFeedIDs.contains(feedID)
                    ? updated.preservingLikeState(of: local)
                    : updated
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if routeToLoginIfAuthenticationRequired(error) { return }
            if error == .notFound || error == .forbidden {
                state.feeds.removeAll { $0.feedId == feedID }
            } else {
                logger?.error("피드 셀 동기화 실패(\(feedID.value)): \(String(describing: error))")
            }
        }
    }

    /// 평가 삭제 후 상세 재로드 — 평가만 지우면 끝이 아니라 키워드·읽기 상태 집계 등
    /// 독자 평가 데이터가 함께 바뀌므로 서버 데이터로 다시 동기화한다.
    /// 기존 화면은 유지한 채 새 데이터가 오면 갈아끼운다(전면 로딩 없음).
    func deleteReview() async {
        defer { deleteReviewTask = nil }
        do {
            try await deleteNovelReviewUseCase.execute(novelID: novelID)
            guard !isClosing, !Task.isCancelled else { return }
            state.presentedToast = .reviewDeleted
            // 재로드가 실패해도 재진입 시 다시 시도되도록 가드를 미리 되돌린다(성공 시 loadNovel이 재소진).
            hasLoaded = false
            await loadNovel()
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: .deleteReviewFailed)
        }
    }

    /// 좋아요 서버 동기화. 실패하면 낙관 반영을 롤백한다.
    /// 롤백 시점엔 페이지네이션 append로 인덱스가 변했을 수 있어 피드를 다시 찾는다.
    func syncFeedLike(to isLiked: Bool, feedID: FeedID, rollbackTo before: TotalFeed) async {
        defer { syncingLikeFeedIDs.remove(feedID) }
        do {
            if isLiked {
                try await feedLikeUseCase.like(feedID: feedID)
            } else {
                try await feedLikeUseCase.unlike(feedID: feedID)
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) {
                // 좋아요 두 필드만 이전 값으로 되돌린다 — 셀 전체를 되돌리면 그 사이 재조회가
                // 가져온 최신 본문·댓글수까지 이전 스냅샷으로 물러난다(병합과 대칭, #236 리뷰).
                state.feeds[index] = state.feeds[index].preservingLikeState(of: before)
            }
            presentError(error, as: .likeFailed)
        }
    }

    /// 피드 삭제. 성공하면 목록에서 즉시 제거하고, 헤더의 피드 수 등 집계가 바뀌므로 상세를 재동기화한다.
    func deleteFeed(_ feedID: FeedID) async {
        defer { feedActionTask = nil }
        do {
            try await deleteFeedUseCase.execute(feedID: feedID)
            guard !isClosing, !Task.isCancelled else { return }
            // 진행 중인 피드 더보기가 있으면 무효화한다 — 삭제 전 스냅샷을 든 응답이 늦게 도착해 방금 지운
            // 피드를 목록에 되살리는 창을 닫는다(#236 리뷰 — 더보기는 조용히 드롭되고 스크롤 재실현으로 복구).
            // 취소된 loadFeeds의 defer는 아무것도 정리하지 않으므로(#256 불변식) 슬롯·로딩 표시를 직접 되돌린다.
            feedsTask?.cancel()
            feedsTask = nil
            state.isLoadingFeeds = false
            // 다녀온 셀 대기열에서도 빼 지운 셀을 상세로 되살리려 들지 않게 한다(상세는 어차피 .notFound지만 요청 낭비).
            pendingSyncFeedIDs.remove(feedID)
            state.feeds.removeAll { $0.feedId == feedID }
            // 평가 삭제와 같은 이유의 재로드 — 실패해도 재진입 시 다시 시도되도록 가드를 미리 되돌린다.
            hasLoaded = false
            await loadNovel()
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: .deleteFeedFailed)
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
            guard !isClosing, !Task.isCancelled else { return }
            state.presentedFeedAlert = spoiler ? .reportSpoilerCompleted : .reportImproperCompleted
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: error == .alreadyReported ? .reportFeedAlreadyReported : .reportFeedFailed)
        }
    }

    /// 관심 상태 서버 동기화. 실패하면 낙관 반영을 롤백한다.
    func syncInterest(to isInterested: Bool, rollbackTo before: Novel) async {
        defer { isSyncingInterest = false }
        do {
            if isInterested {
                try await novelInterestUseCase.add(id: novelID)
            } else {
                try await novelInterestUseCase.remove(id: novelID)
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            state.novel = before
            presentError(error, as: .interestFailed)
        }
    }
}

// MARK: - Error Mapping

private extension NovelDetailViewModel {

    /// Repository 에러를 발생 맥락의 의미 토스트로 변환한다. 원인은 로그로 남긴다.
    /// (`handle(_:)`과 이름이 겹치지 않게 분리)
    func presentError(_ error: Error, as presented: DetailToast) {
        // 인증 만료면 개별 실패 토스트 대신 로그인 유도로 일원화한다(피드/좋아요/삭제/신고/관심 공통 경로).
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("NovelDetail 실패(\(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 개별 실패 토스트 대신 로그인 유도로 일원화한다.
    /// (`RepositoryError`는 `Equatable` — 여기서 쓰는 건 import된 `BaseDomain.RepositoryError`다.)
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
