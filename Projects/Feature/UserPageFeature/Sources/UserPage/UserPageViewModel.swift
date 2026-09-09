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
import CollectionDomain
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
        var collectionPreviews: [CollectionPreview] = []
        /// 컬렉션 섹션의 표시값 겸 타이틀 행 탭 동작 분기 기준 — 미리보기 배열 개수(최대 3)가 아니라
        /// 전체 개수(`CollectionDomain/CLAUDE.md`의 `collectionsCount`). 0이어도 타이틀 행은 항상
        /// 보여주고(미리보기만 비움), 그 행을 탭하면 "컬렉션을 등록하지 않은 유저에요" 토스트로 안내한다
        /// (사용자 확정, 2026-08-25 — 이전엔 섹션 전체를 숨겼다. `hasCollections`/`isNoCollectionsToastPresented` 참고).
        var collectionCount = 0
        /// 컬렉션 섹션 타이틀 행을 탭했는데 컬렉션이 0개일 때 뜨는 안내 토스트(`WSSToastType.noCollections`).
        var isNoCollectionsToastPresented = false
        var isLoading = false
        var hasLoadError: RepositoryError?
        /// 상대가 프로필을 비공개로 설정해 접근할 수 없는 경우(`RepositoryError.privateProfile`) —
        /// 일반 로드 실패(`hasLoadError`)와 분리해 전용 화면("비공개 프로필이에요")으로 표현한다.
        var isProfilePrivate = false
        /// 존재하지 않는/탈퇴한 유저(서버 `USER-018` → `RepositoryError.notFound`) — 일반 로드 실패와 분리해
        /// "없는 유저" 안내 화면으로 표현한다(재시도 무의미, V1 parity #222). 없으면 재시도만 반복되는 회귀.
        var isUserNotFound = false

        var feeds: [TotalFeed] = []
        var hasNextFeeds = true
        var isLoadingFeeds = false
        var feedsLoadFailed: RepositoryError?

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
        /// 이미 신고한 피드에 같은 종류의 신고를 다시 시도함(#255 QA) — `hasActionError`와 분리해
        /// "이미 신고한 피드/댓글이에요" 전용 토스트로 안내한다.
        var isAlreadyReportedToastPresented = false
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

    /// 컬렉션 데이터 존재 여부 — 미리보기 행 노출 여부, 그리고 타이틀 행을 탭했을 때 목록 이동(TODO)과
    /// "컬렉션을 등록하지 않은 유저에요" 토스트를 가르는 기준(사용자 확정, 2026-08-25 — 이전엔 섹션
    /// 전체 노출 여부였다).
    var hasCollections: Bool {
        state.collectionCount > 0
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
        case dismissAlreadyReportedToast
        case collectionSectionTapped
        case dismissNoCollectionsToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// 마이페이지 컬렉션 섹션과 동일 상한(디자인) — `MypageViewModel.collectionPreviewSize`와 동일.
    private static let collectionPreviewSize = 3

    @ObservationIgnored private var hasLoadedFirstFeeds = false
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    /// 마지막 피드 재조회 요청 이후 좋아요를 토글한 셀 — 재조회 응답 병합의 보호 대상 계산용
    /// (좋아요 POST가 목록 GET보다 먼저 끝나면 in-flight 집합만으론 놓친다 — `NovelDetailViewModel`과 동일, #236).
    @ObservationIgnored private var likeToggledDuringRefresh: Set<FeedID> = []
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

    // CollectionDomain
    private let loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase

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
        loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase,
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
        self.loadCollectionPreviewsUseCase = loadCollectionPreviewsUseCase
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
        case .dismissAlreadyReportedToast:
            state.isAlreadyReportedToastPresented = false
        case .collectionSectionTapped:
            tapCollectionSection()
        case .dismissNoCollectionsToast:
            state.isNoCollectionsToastPresented = false
        }
    }
}

// MARK: - Action Handling

private extension UserPageViewModel {
    /// 진입/재진입 로드. onAppear는 재진입마다 불린다(#236, push 재진입 재조회 복원 — V1 parity).
    /// - **첫 로드**(`!hasLoaded`): 전면 로딩과 함께 로드. 실패는 가드를 소진하지 않아 재시도가 열려 있다.
    /// - **재진입**(`hasLoaded`): 로딩 없이 **조용히 재조회**해 프로필 묶음을 제자리 교체한다 — 이
    ///   화면 위에 push된 피드 상세 등에서 바뀐 것(좋아요·차단·프로필 변경)을 복귀 즉시 반영하기 위함.
    ///   활동 탭 미리보기도 이미 로드된 적 있으면 첫 페이지를 같이 재조회한다(V1은 피드까지 전부 재로드).
    ///   실패해도 기존 화면을 그대로 둔다(`NovelDetailViewModel.load` 정본).
    func load() {
        guard loadTask == nil else { return }
        if hasLoaded {
            loadTask = Task { await loadUserPage(isSilentRefresh: true) }
            if hasLoadedFirstFeeds, feedsTask == nil, !state.isProfilePrivate {
                feedsTask = Task { await loadFirstFeedsPage(isSilentRefresh: true) }
            }
        } else {
            state.isLoading = true
            state.hasLoadError = nil
            loadTask = Task { await loadUserPage() }
        }
    }

    /// "활동" 탭 첫 진입 시 지연 로드(`NovelDetailFeature` 피드 탭과 동일 패턴). 미리보기라 첫 페이지만
    /// 가져온다 — 5개 넘게 있으면 전체 목록은 `UserFeedListView`(무한스크롤)로 넘어간다.
    func loadFeeds() {
        // 이미 비공개로 판정된 프로필이면 탭을 눌러도 다시 요청하지 않는다 — 어차피 같은 결과.
        guard !state.isProfilePrivate, !hasLoadedFirstFeeds, feedsTask == nil else { return }
        state.isLoadingFeeds = true
        state.feedsLoadFailed = nil
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
        likeToggledDuringRefresh.insert(feedID)
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

    /// 컬렉션 섹션 타이틀 행 탭(컬렉션 없음) — "컬렉션을 등록하지 않은 유저에요" 토스트로 안내한다
    /// (사용자 확정, 2026-08-25). 컬렉션이 있을 때의 목록 이동은 순수 네비게이션이라 View가
    /// `hasCollections`를 직접 보고 이 액션을 거치지 않은 채 `onRoute(.collectionList)`를 바로 부른다
    /// ("서재" 블록과 동일 원칙 — `UserPageFeature/CLAUDE.md` 참고).
    func tapCollectionSection() {
        state.isNoCollectionsToastPresented = true
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
    /// 프로필/장르 뱃지/작품 취향/서재 통계/컬렉션 미리보기를 로드한다. **성패 단위별로 완전히 독립된
    /// 갈래로 나뉜다**(#255 QA — 서버가 비공개 유저도 상단 프로필(닉네임·소개·프로필 이미지)은 성공
    /// 응답을 주도록 바뀌어, 그 정보를 비공개 시 실패할 수 있는 나머지 호출들과 한 성패로 묶으면 안 되게
    /// 됐다):
    /// - **프로필**(`loadProfileSection`): 닉네임·소개·프로필 이미지 — 비공개 여부와 무관하게 항상 성공
    ///   응답을 준다. 유일하게 실패를 전면 에러로 취급하고(`presentError`), 성공하면 `hasLoaded`를 세운다.
    /// - **서재 통계**(`loadRegisteredNovelStatsSection`)·**컬렉션 미리보기**(`loadCollectionPreviewsSection`):
    ///   각각 독립 격리 — 둘 다 비공개 유저에게 `RepositoryError.privateProfile`이 아니라 **일반** 에러(403
    ///   `USER-015`가 공용 `NetworkingError.toRepositoryError()`로만 매핑돼 `.forbidden`이 됨)로 실패할 수
    ///   있다(실측, 2026-09-08 — 처음엔 컬렉션 미리보기만 이 문제인 줄 알았는데 서재 통계도 동일하게
    ///   재현됐다). 프로필과 같은 do-block에 있으면 그 실패가 이미 받아온 프로필까지 함께 버리므로, 각각
    ///   완전히 독립된 `async let`으로 실패를 **조용히 흡수**한다(빈 값처럼 보임, 재시도 없음).
    /// - **취향 묶음**(`loadPreferenceBundle`): 장르 뱃지·작품 취향 — 비공개면 `RepositoryError.privateProfile`로
    ///   실패해 `state.isProfilePrivate`만 세우고 상단 정보엔 영향을 주지 않는다.
    /// 취향 묶음 내부는 여전히 "로컬 변수로 모두 수급 후 일괄 반영"(부분 갱신 방지) 원칙을 유지한다.
    /// `isSilentRefresh`는 재진입의 조용한 재조회(#236) — 전면 로딩을 세우지 않고, 실패해도 기존
    /// 화면을 그대로 둔다(탈퇴 같은 의미 상태 변화는 다음 fresh 진입에서 반영 — 비공개 전환은 아래
    /// `loadPreferenceBundle`이 두 모드 모두에서 반영한다).
    func loadUserPage(isSilentRefresh: Bool = false) async {
        defer { loadTask = nil }
        if !isSilentRefresh { state.isLoading = true }
        defer { if !isSilentRefresh { state.isLoading = false } }

        async let profileSection: Void = loadProfileSection(isSilentRefresh: isSilentRefresh)
        async let statsSection: Void = loadRegisteredNovelStatsSection()
        async let collectionPreviews: Void = loadCollectionPreviewsSection()
        async let preferenceBundle: Void = loadPreferenceBundle(isSilentRefresh: isSilentRefresh)
        _ = await (profileSection, statsSection, collectionPreviews, preferenceBundle)
    }

    /// 상단 프로필(닉네임·소개·프로필 이미지) — 비공개 여부와 무관하게 항상 성공 응답을 준다.
    func loadProfileSection(isSilentRefresh: Bool) async {
        do {
            let loadedProfile = try await loadProfileUseCase.execute(target: .user(userID))
            state.profile = loadedProfile
            hasLoaded = true
        } catch {
            if isSilentRefresh {
                logger?.error("UserPage 프로필 재조회 실패(기존 화면 유지): \(String(describing: error))")
            } else {
                presentError(error)
            }
        }
    }

    /// 서재 통계 — 실패(비공개 등)는 조용히 흡수한다. 프로필과 독립이라 이 실패가 상단 정보를 가리지 않는다
    /// (위 함수 doc 참고).
    func loadRegisteredNovelStatsSection() async {
        do {
            state.registeredNovelStats = try await loadUserRegisteredNovelStatsUseCase.execute(id: userID)
        } catch {
            logger?.error("UserPage 서재 통계 로드 실패(무시): \(String(describing: error))")
        }
    }

    /// 컬렉션 미리보기 — 컬렉션 목록 API는 대상 사용자를 명시로 받는 계약이라(`CollectionDomain/CLAUDE.md`)
    /// 이 화면이 직접 userID를 넘긴다. 실패(비공개 등)는 조용히 흡수한다 — 프로필과 독립이라 이 실패가
    /// 상단 정보를 가리지 않는다(위 함수 doc 참고).
    func loadCollectionPreviewsSection() async {
        do {
            let (loadedCollectionPreviews, loadedCollectionCount) = try await loadCollectionPreviewsUseCase.execute(
                userID: userID,
                size: Self.collectionPreviewSize
            )
            state.collectionPreviews = loadedCollectionPreviews
            state.collectionCount = loadedCollectionCount
        } catch {
            logger?.error("UserPage 컬렉션 미리보기 로드 실패(무시): \(String(describing: error))")
        }
    }

    /// 장르 뱃지·작품 취향 — 비공개 프로필이면 `USER-015`로 막힌다(상단 프로필과 달리 여전히 비공개 대상).
    /// ⚠️ 일반 에러(네트워크 순간 오류 등)도 `presentError`로 넘기지 않는다 — `presentError`는
    /// `state.hasLoadError`를 세워 `UserPageView`가 body 전체를 `NetworkErrorView`로 덮는데, 그러면
    /// 이 함수와 독립적으로 병렬 실행되는 `loadProfileSection`이 이미 성공시킨 프로필(닉네임·소개·이미지)
    /// 까지 함께 가려진다 — 이 함수를 프로필과 완전히 격리한 목적 자체가 무의미해진다(#255 QA 리뷰에서
    /// 발견). 서재 통계·컬렉션 미리보기와 동일하게 실패를 조용히 흡수한다(장르/취향 섹션만 비게 됨).
    func loadPreferenceBundle(isSilentRefresh: Bool) async {
        do {
            async let genrePreferences = loadGenrePreferencesUseCase.execute(.user(userID))
            async let novelPreference = loadNovelPreferencesUseCase.execute(.user(userID))

            let loadedGenrePreferences = try await genrePreferences
            let loadedNovelPreference = try await novelPreference
            state.genrePreferences = loadedGenrePreferences
            state.novelPreference = loadedNovelPreference
        } catch RepositoryError.privateProfile {
            state.isProfilePrivate = true
        } catch {
            logger?.error("UserPage 취향 로드 실패(무시): \(String(describing: error))")
        }
    }

    /// `isSilentRefresh`는 재진입의 조용한 재조회(#236) — 실패해도 기존 미리보기를 실패 뷰로 덮지 않는다.
    /// 비공개 전환(`privateProfile`)만은 두 모드 모두 반영한다 — 서버가 접근 자체를 막은 의미 상태라서.
    func loadFirstFeedsPage(isSilentRefresh: Bool = false) async {
        defer {
            feedsTask = nil
            state.isLoadingFeeds = false
        }
        // 보호 대상 좋아요(요청 시작 시 in-flight + 요청 중 토글, #236) — 전체 목록 재조회 병합의 정본은
        // 이 화면 계열이다(원조였던 NovelDetail refreshFeeds는 #256에서 셀 동기화로 교체돼 삭제).
        var likeProtectedIDs = syncingLikeFeedIDs
        likeToggledDuringRefresh = []

        do {
            // 유저 피드 조회는 이 화면(유저 페이지)에서만 일어나므로, 이미 로드된 프로필의
            // 닉네임·프로필 이미지를 그대로 재사용한다(응답에 author 정보가 없어 호출 측이 채워야 함).
            let page = try await loadUserFeedsUseCase.execute(
                userID: userID,
                nickname: state.profile?.nickname ?? "",
                profileImage: state.profile?.characterImage,
                lastFeedID: FeedID(0)
            )
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
            state.hasNextFeeds = page.hasNext
            hasLoadedFirstFeeds = true
        } catch RepositoryError.privateProfile {
            state.isProfilePrivate = true
        } catch {
            if isSilentRefresh {
                logger?.error("UserPage 피드 재조회 실패(기존 목록 유지): \(String(describing: error))")
            } else {
                state.feedsLoadFailed = (error as? RepositoryError) ?? .unknown
                logger?.error("UserPage 피드 로드 실패: \(String(describing: error))")
            }
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
        // 존재하지 않는/탈퇴한 유저(USER-018 → .notFound)는 "없는 유저" 안내로 — 재시도해도 소용없어
        // NetworkErrorView(재시도)로 떨어뜨리지 않는다(V1 parity #222).
        guard (error as? RepositoryError) != .notFound else {
            state.isUserNotFound = true
            return
        }
        logger?.error("UserPage 로드 실패: \(String(describing: error))")
        state.hasLoadError = (error as? RepositoryError) ?? .unknown
    }

    func presentActionError(_ error: Error, context: String) {
        logger?.error("UserPage \(context) 실패: \(String(describing: error))")
        guard (error as? RepositoryError) != .alreadyReported else {
            state.isAlreadyReportedToastPresented = true
            return
        }
        state.hasActionError = true
    }
}
