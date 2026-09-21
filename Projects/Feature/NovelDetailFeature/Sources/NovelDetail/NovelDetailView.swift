//
//  NovelDetailView.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NotificationDomain
import NovelDomain
import NovelReviewDomain
import SocialDomain
import Logger
import PushAuthorization
import Analytics
import DesignSystem
import WSSComponent

// 작품 상세 화면: 몰입형 헤더(블러 커버) + 유저 평가 + 탭(정보/피드).
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct NovelDetailView: View {

    /// threedots 드롭다운 표시 컨텍스트 — 대상 피드(항목 분기)와 앵커(threedots 하단의 화면 y).
    struct FeedMenuContext {
        let feed: TotalFeed
        let anchorY: CGFloat
    }

    @State private var viewModel: NovelDetailViewModel
    /// VM 판단이 필요 없는 순수 표시 상태 — View가 소유한다.
    @State private var isMenuPresented = false
    /// 시트가 열려있지 않아도 네비바 종 아이콘 상태(채움 여부)를 비추려면 로드된 설정값이 필요해서,
    /// 시트 열릴 때마다 새로 만들던 것과 달리 화면 진입 시 한 번 만들어 화면 수명 내내 들고 있는다
    /// (`.onAppear`가 로드, 시트는 이 인스턴스를 그대로 재사용) — 토글도 실시간으로 아이콘에 반영된다.
    @State private var notificationSettingViewModel: NovelNotificationSettingSheetViewModel
    @State private var isDescriptionExpanded = false
    /// 피드 셀 threedots 드롭다운 — nil이 아니면 해당 피드의 메뉴가 떠 있다.
    @State private var feedMenuContext: FeedMenuContext?
    /// 표지 탭 → 대형 표지 오버레이(dim + 원본 비율 확대 표지) 표시 여부.
    @State private var isLargeCoverPresented = false
    /// 대형 표지 원본 이미지 — 화면 로드 시 미리 받아 둔다(prefetch).
    /// 오버레이에서 AsyncImage를 쓰면 캐시 히트여도 새 인스턴스가 .empty phase부터 시작해
    /// placeholder가 한 프레임 이상 번쩍인다 → 열리는 순간 디코딩된 이미지를 동기로 그리기 위함.
    @State private var largeCoverUIImage: UIImage?
    /// 스크롤 반응형 네비 타이틀 — 스크롤 콘텐츠 최상단의 오프셋(rest≈0, 위로 스크롤 시 음수).
    /// 조금이라도 스크롤되면 네비 타이틀·흰 배경을 페이드인한다. (loadedContent의 GeometryReader+onChange가 갱신)
    @State private var scrollOffsetY: CGFloat = 0
    /// 스티키 탭바 — 스크롤 콘텐츠 안 "원본" 탭바의 상단 y(화면 좌상단 기준).
    /// 측정 전엔 스티키가 뜨지 않도록 무한대로 시작한다.
    @State private var tabBarMinY: CGFloat = .greatestFiniteMagnitude
    /// 스티키 탭바 — 네비바 하단 y(= 안전영역 top + 네비바 높이). 네비바 배경의 실측 높이로 얻는다.
    @State private var navigationBarBottomY: CGFloat = 0
    /// 탭 콘텐츠 최소 높이 계산용 — 탭바 높이와 스크롤 뷰포트 높이(둘 다 실측).
    @State private var tabBarHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    /// 평가 상태바(reviewBox)의 화면 좌표 프레임 — 첫 진입 온보딩 스포트라이트가 이 자리만 딤에서 뚫는다.
    /// height가 0이면 아직 미실측이라 오버레이를 띄우지 않는다(엉뚱한 위치에 구멍이 나지 않게).
    @State private var reviewBoxFrame: CGRect = .zero
    @Environment(\.dismiss) private var dismiss
    /// 오류 제보 링크(외부 브라우저) 열기용.
    @Environment(\.openURL) private var openURL
    /// 화면 전환 의도 콜백(#253) — 목적지·payload 계약은 `NovelDetailRoute`(Navigation/)가 정본.
    /// 실제 화면 조립·push는 호출자(App 조정 계층)가 수행한다.
    private let onRoute: (NovelDetailRoute) -> Void
    /// 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 어느 서버 호출에서 발생하든 공통.
    /// 화면 전환 "의도"가 아니라 세션 이벤트라 `onRoute`에 합치지 않는다.
    private let onAuthenticationRequired: () -> Void
    /// 이 화면에서 발화한 피드 작성(`.createFeed` 라우트)이 성공해 복귀했다는 신호(#256) — App 탭 Root
    /// 로컬 `@State`와 연결된 1회성 채널. 복귀 `onAppear`가 true를 소비(false로 되돌림)하고 피드 섹션을
    /// 초기 로드처럼 리셋한다(새 글이 맨 위). 작성 화면은 발화한 작품 상세 바로 위에 push되므로 pop 시
    /// 그 인스턴스의 onAppear가 먼저 소비한다(스택에 작품 상세가 여럿이어도 안전).
    @Binding private var needsFeedReloadForCreatedFeed: Bool

    private let novelID: NovelID
    private let logger: Logger?
    private let analyticsTracker: AnalyticsTracker?

    init(
        novelID: NovelID,
        viewModel: NovelDetailViewModel,
        // NotificationDomain — 알림 등록 시트(#189)·네비바 종 아이콘 채움 여부용. `notificationSettingViewModel`을
        // 조립하는 데만 쓰이고 그 뒤로는 안 읽혀 저장 프로퍼티로 남겨두지 않는다(리뷰에서 지적 — VM이
        // 화면 진입 시점에 한 번만 조립되는 지금 구조에선 저장할 이유가 없다, 예전엔 시트를 열 때마다
        // 새 VM을 만들어야 해서 계속 들고 있었다).
        loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase,
        updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        needsFeedReloadForCreatedFeed: Binding<Bool> = .constant(false),
        onRoute: @escaping (NovelDetailRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self.novelID = novelID
        self._viewModel = State(initialValue: viewModel)
        self._notificationSettingViewModel = State(initialValue: NovelNotificationSettingSheetViewModel(
            novelID: novelID,
            loadNotificationSettingUseCase: loadNotificationSettingUseCase,
            updateNotificationSettingUseCase: updateNotificationSettingUseCase,
            logger: logger,
            analyticsTracker: analyticsTracker
        ))
        self.logger = logger
        self.analyticsTracker = analyticsTracker
        self._needsFeedReloadForCreatedFeed = needsFeedReloadForCreatedFeed
        self.onRoute = onRoute
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 몰입형 헤더라 시스템 네비바를 숨기고 커스텀 오버레이를 쓴다.
    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            // 네비바를 숨기면 스와이프 뒤로가기까지 함께 꺼진다 → 제스처만 따로 되살린다.
            .enableSwipeBack()
            .onAppear {
                // 작성 성공 복귀면 피드 섹션 리셋을 먼저 — `.load`의 셀 동기화가 pending을 먼저 소비해
                // 곧 버려질 요청을 내지 않게 한다. `.load`(작품 정보 조용한 갱신)는 그대로 항상 부른다.
                if needsFeedReloadForCreatedFeed {
                    needsFeedReloadForCreatedFeed = false
                    viewModel.handle(.reloadFeedsForCreatedFeed)
                }
                viewModel.handle(.load)
                // 종 아이콘 채움 여부(알림 하나라도 켜짐)를 시트를 열기 전에도 비추려면 여기서 로드해야
                // 한다 — `NovelNotificationSettingSheetViewModel.load()`는 `hasLoaded` 가드가 있어
                // 재진입마다 다시 부르는 건 무해하다(첫 로드 후엔 no-op).
                notificationSettingViewModel.handle(.load)
            }
            // 표지 URL이 생기면(로드 완료) 대형 표지를 미리 받아 둔다 — 재시도 후 로드에도 id 갱신으로 재발화.
            .task(id: coverImageURL) { await loadLargeCoverIfNeeded() }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            // 평가 삭제 확인 — 알럿은 스스로 닫히지 않으므로 두 버튼 모두 handle 경유로 상태를 되돌린다.
            .showWSSAlert(
                isPresented: deleteReviewAlertBinding,
                type: .deleteNovelReview,
                buttonActions: [
                    { viewModel.handle(.dismissDeleteReviewAlert) },  // "취소"
                    { viewModel.handle(.confirmDeleteReview) }        // "삭제"
                ]
            )
            // 피드 셀 액션(삭제/신고)의 확인·접수 완료 알럿 — 의미값(FeedAlert) → 타입·버튼 매핑은 아래 Presentation.
            .showWSSAlert(
                isPresented: feedAlertBinding,
                type: feedAlertType,
                buttonActions: feedAlertActions
            )
            // 종 아이콘 탭인데 시스템 푸시 권한이 denied일 때(`notificationBellTapped()`) — 어느 버튼이든
            // 알럿을 닫기만 할 뿐 시트로 이동시키지 않는다(`SettingFeature`의 "알림 설정" 메뉴와 동일 판단).
            .showWSSAlert(
                isPresented: pushAuthorizationAlertBinding,
                type: .setAppNotification,
                buttonActions: [
                    { viewModel.handle(.dismissPushAuthorizationAlert) },  // "다음에 하기"
                    {
                        viewModel.handle(.dismissPushAuthorizationAlert)
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }  // "설정하러 가기"
                ]
            )
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    // `.onDisappear` 대신 이 명시적 신호에서만 부른다 — `NavigationPath`에 다른 화면을
                    // push할 때도(`onRoute` 7종) `.onDisappear`가 "화면이 진짜로 닫힐 때"와 똑같이
                    // 발화해, 그걸로 `screenClosed()`를 걸면 forward push마다 로드가 취소된다
                    // (`CollectionFeature/CLAUDE.md`에 이미 같은 함정이 실제 회귀로 기록돼 있다 — push
                    // 되는 화면에 `onDisappear` 기반 취소를 걸면 안 되고, 이 화면(`NovelDetailViewModel`)
                    // 처럼 명시적 액션으로 걸어야 한다는 그 정본). ⚠️ 대신 스와이프 뒤로가기는 이 신호를
                    // 안 거쳐(`.enableSwipeBack()`이 되살린 네이티브 pop이라) `notificationSettingViewModel`이
                    // 정리 안 된다 — `NovelDetailViewModel.close()` 자신도 스와이프에서 똑같이 안 불리는
                    // 이 화면의 기존 한계라 새로 생긴 문제는 아니다(아래 주의사항 참고).
                    notificationSettingViewModel.handle(.screenClosed)
                    dismiss()
                }
            }
            // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
            // notificationSettingViewModel은 시트가 안 떠 있어도(#189 아이콘 반영용) `.load()`가 돌 수
            // 있어, 그 인증 만료 신호를 시트 내부가 아니라 여기서 듣는다 — 시트가 안 떠 있으면
            // `NovelNotificationSettingSheet`의 `.onChange`는 애초에 mount조차 안 돼 신호를 놓친다.
            .onChange(of: notificationSettingViewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
            .sheet(isPresented: notificationSettingSheetBinding) {
                NovelNotificationSettingSheet(viewModel: notificationSettingViewModel)
            }
    }

    // 루트는 ZStack으로 고정 — 로딩/성공/실패가 분기돼도 루트 정체성이 유지돼
    // pop 애니메이션과 로드 완료가 겹칠 때의 전환 경합을 피한다(NovelReview 교훈).
    private var content: some View {
        ZStack(alignment: .top) {
            Color.wssWhite.ignoresSafeArea()

            if let information = viewModel.state.information {
                loadedContent(information)
            } else if viewModel.state.isLoading {
                LoadingView()
            } else {
                // 로드 실패 — 공용 실패 뷰 재사용. 재시도 버튼이 load를 다시 발화한다(실패는 가드를 소진하지 않음).
                // 잡은 에러 종류로 문구를 3분류(서버/일반/네트워크)로 가른다.
                NetworkErrorView(error: viewModel.state.loadError ?? .unknown) { viewModel.handle(.load) }
            }

            // 네비바와 스티키 탭바는 한 VStack으로 묶는다 — 탭바가 네비바 "바로 아래"에 붙는 게
            // 레이아웃으로 보장되므로 스티키 탭바의 y를 따로 계산할 필요가 없다.
            VStack(spacing: 0) {
                navigationBar
                if showStickyTabBar {
                    tabBar
                }
            }

            if isMenuPresented {
                menuOverlay
            }

            if let feedMenuContext {
                feedMenuOverlay(feedMenuContext)
            }

            // 네비바·스티키 탭바까지 덮어야 하므로 루트 ZStack의 최상단 자식으로 둔다.
            if isLargeCoverPresented {
                largeCoverOverlay
            }

            // 첫 진입 평가 온보딩 — 상태바 프레임이 실측된 뒤에만 띄운다(엉뚱한 위치에 구멍 방지).
            if viewModel.state.showReviewOnboarding, reviewBoxFrame.height > 0 {
                reviewOnboardingOverlay(reviewBoxFrame)
            }
        }
    }

    private func loadedContent(_ information: NovelInformation) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // 표지는 커스텀 네비바 바로 아래에서 시작한다 — 안전영역 높이가 기기마다 달라
                    // 디자인 고정값(99)을 쓸 수 없다. 네비바 배경 실측 높이를 그대로 인셋으로 넘긴다.
                    NovelDetailHeaderView(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel,
                        topInset: navigationBarBottomY,
                        scrollSpaceName: scrollSpaceName,
                        onCoverTapped: { isLargeCoverPresented = true },
                        onAuthorTapped: { onRoute(.authorSearch($0)) }
                    )
                    NovelDetailReviewSection(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel,
                        scrollSpaceName: scrollSpaceName,
                        onSelectStatus: { onRoute(.review(information, $0)) },
                        onToggleInterest: { viewModel.handle(.toggleInterest) },
                        onCreateFeedTapped: {
                            viewModel.track(.writeButtonTapped)
                            onRoute(.createFeed(connectedNovel(from: information.novel)))
                        },
                        onReviewBoxFrameChange: { reviewBoxFrame = $0 }
                    )
                    // 스크롤되는 "원본" 탭바 — 자리를 유지해 스티키 전환 시 콘텐츠가 점프하지 않는다.
                    // 네비바 하단에 닿는 순간부터는 상단 오버레이의 탭바가 이 자리를 그대로 덮는다.
                    tabBar
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: proxy.frame(in: .named(scrollSpaceName)).minY,
                                              initial: true) { _, newY in
                                        tabBarMinY = newY
                                    }
                                    .onChange(of: proxy.size.height, initial: true) { _, height in
                                        tabBarHeight = height
                                    }
                            }
                        )
                    // 탭 콘텐츠엔 최소 높이를 준다 — 탭 전환 시 스크롤이 튀지 않게 하는 핵심.
                    // 짧은 탭(피드 몇 개)으로 바뀌면 contentSize가 줄어 UIScrollView가 contentOffset을
                    // 스크롤 가능한 최대치로 되돌린다(클램프) → 화면이 위로 튄다.
                    // 최소 높이를 "탭바 아래 남는 화면 영역"만큼 확보하면 스티키 지점까지의 스크롤 여유가
                    // 항상 남아 클램프가 일어나지 않는다.
                    Group {
                        switch viewModel.state.selectedTab {
                        case .info:
                            NovelDetailInfoTab(
                                information: information,
                                isDescriptionExpanded: $isDescriptionExpanded,
                                onPlatformLinkTapped: { viewModel.track(.platformLinkTapped) }
                            )
                        case .feed:
                            NovelDetailFeedTab(
                                feeds: viewModel.state.feeds,
                                isLoading: viewModel.state.isLoadingFeeds,
                                loadError: viewModel.state.feedsLoadFailed,
                                scrollSpaceName: scrollSpaceName,
                                onReachEnd: { viewModel.handle(.loadMoreFeeds) },
                                onRetry: { viewModel.handle(.retryFeeds) },
                                onFeedTapped: { feedID in
                                    // 돌아왔을 때 이 셀만 상세로 다시 맞추기 위해 떠나기 전에 기억시킨다(#256).
                                    viewModel.handle(.feedVisited(feedID))
                                    onRoute(.feedDetail(feedID))
                                },
                                onUserProfileTapped: { onRoute(.userProfile($0)) },
                                onUnavailableUserProfileTapped: { viewModel.handle(.userProfileUnavailable) },
                                onNovelTapped: { onRoute(.novelDetail($0)) },
                                onThreeDotsTapped: { feed, anchorY in
                                    feedMenuContext = FeedMenuContext(feed: feed, anchorY: anchorY)
                                },
                                onToggleLike: { viewModel.handle(.toggleFeedLike($0)) }
                            )
                        }
                    }
                    .frame(minHeight: tabContentMinHeight, alignment: .top)
                }
                // 스크롤 오프셋 측정 → scrollOffsetY. rest≈0, 위로 스크롤 시 음수.
                // ⚠️ preference/onPreferenceChange를 안 쓴다 — ScrollView가 preference를 바깥으로
                // 안 올려보내고, 이 SDK에선 onPreferenceChange→@State 갱신도 안 먹는다.
                // GeometryReader 안에서 onChange로 @State를 직접 쓴다(스크롤마다 재평가).
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .named(scrollSpaceName)).minY,
                                      initial: true) { _, newY in
                                scrollOffsetY = newY
                            }
                    }
                )
            }
            .coordinateSpace(name: scrollSpaceName)
            .ignoresSafeArea(edges: .top)
            // 뷰포트 높이 — ⚠️ `GeometryReader`에도 `ignoresSafeArea(edges: .top)`을 걸어야 한다.
            // ScrollView는 이미 상태바까지 확장돼 있는데, background의 GeometryReader는 그대로 두면
            // 안전영역 **안쪽** 높이를 보고한다 → 최소 높이가 딱 안전영역 top만큼 모자라 스티키가 덜 붙는다.
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.height, initial: true) { _, height in
                            scrollViewHeight = height
                        }
                }
                .ignoresSafeArea(edges: .top)
            )

            if viewModel.state.selectedTab == .feed {
                floatingWriteButton
            }
        }
    }
}

// MARK: - Sections

private extension NovelDetailView {

    /// 뒤로가기 + 더보기(threedots). 몰입형 헤더 위에 떠 있는 고정 영역이라 시스템 툴바 대신 직접 그린다.
    var navigationBar: some View {
        HStack(spacing: 0) {
            // 에셋 원색(wssGray100)은 밝은 헤더 배경에서 안 보여 template으로 진한 색을 입힌다.
            // contentShape는 라벨 내부에 둬야 투명 여백까지 탭이 먹는다(레퍼런스 배치).
            Button {
                viewModel.handle(.requestClose)
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 아이콘 크기 그대로는 탭 타깃이 너무 작아 라벨 패딩으로 터치영역을 넓힌다(아이콘 시각
            // 위치는 그대로 — 아이콘 간 시각 간격 6+4+6=16, trailing 20 유지). threedots의 trailing 20도
            // 라벨 안에 두어 디바이스 우측 끝까지 탭이 먹는다. 높이 44는 네비바(뒤로가기 프레임)와 동일.
            HStack(spacing: 0) {
                Button {
                    viewModel.handle(.notificationBellTapped)
                } label: {
                    // 완결/휴재복귀 알림 둘 중 하나라도 켜져 있으면 채운 아이콘(icAnnouncementFill) +
                    // wssPrimary100으로 바꿔, 시트를 열지 않아도 알림이 걸려 있는 작품임을 알 수 있다.
                    // ⚠️ 애니메이션을 일부러 안 건다 — 서로 다른 리소스(icAnnouncement↔icAnnouncementFill)
                    // 전환인 데다 색도 foregroundStyle(tint)만으로 표현돼, `.animation`을 걸어도 보간되지
                    // 않고 즉시 스냅한다(WSSComponent CLAUDE.md의 같은 함정 — 두 벌을 opacity로 겹쳐
                    // 크로스페이드해야 하는데, LibraryFeature 필터 칩도 같은 이유로 결국 즉시 전환으로
                    // 확정됐다). 이 아이콘도 같은 판단으로 크로스페이드를 안 만들고 즉시 전환을 받아들인다.
                    (isAnyNotificationEnabled ? WSSImage.icAnnouncementFill : WSSImage.icAnnouncement).swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isAnyNotificationEnabled ? Color.wssPrimary100 : Color.wssBlack)
                        .padding(.leading, 20)
                        .padding(.trailing, 6)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer().frame(width: 4)

                Button {
                    isMenuPresented.toggle()
                } label: {
                    WSSImage.icThreedotsVertical.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.wssBlack)
                        .padding(.leading, 6)
                        .padding(.trailing, 20)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        // 스크롤 반응형 네비 타이틀 — 화면 정중앙에 오도록 좌우 여백을 대칭(100pt)으로 맞춘다.
        // 우측 클러스터(종 버튼 20+24+6=50pt + 간격 4 + threedots 버튼 6+20+20=46pt = 100pt, 터치영역
        // 포함)가 좌측(뒤로가기 44pt + 이 HStack에 걸린 leading 6pt = 화면 기준 실제 50pt)보다 넓어,
        // 좌측 여백도 100으로 맞춰야 대칭이 된다 — 코드상 94인 건 이 6pt를 상쇄하기 위해서(94+6=100).
        // 한쪽만 실측값을 쓰면 타이틀이 더 넓은 우측 쪽으로 밀려 정중앙에서 벗어난다.
        .overlay {
            Text(novelTitle)
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, 94)
                .padding(.trailing, 100)
                .opacity(showNavTitle ? 1 : 0)
        }
        .padding(.leading, 6)
        // 타이틀과 함께 페이드인하는 흰 배경 — 없으면 타이틀·버튼이 스크롤되는 본문과 겹쳐 안 읽힌다.
        // 네비바 자신은 ZStack 자식이라 이미 안전영역 상단에 붙는다(UIKit `safeAreaLayoutGuide`와 동일).
        // 상태바까지 뚫고 올라가야 하는 건 배경뿐이고, 그건 `ignoresSafeArea`가 알아서 한다 —
        // 안전영역 높이를 읽거나 네비바 높이를 더할 필요가 없다.
        // ⚠️ `padding` 뒤에 붙여야 좌우 끝까지 덮는다.
        // 스티키 탭바의 임계선(네비바 하단 y)도 여기서 얻는다 — 이 배경은 `ignoresSafeArea`로
        // 이미 상태바까지 확장돼 있어 그 **실측 높이**가 곧 "안전영역 top + 네비바 높이"다.
        // (안전영역을 직접 읽거나 네비바 높이 44를 더하지 않아도 된다 — 위 주석과 같은 이유.)
        .background(
            GeometryReader { proxy in
                Color.wssWhite
                    .opacity(showNavTitle ? 1 : 0)
                    // 투명일 땐(히어로 위) 바 영역에서 시작하는 드래그를 스크롤로 넘기고,
                    // 흰 배경이 콘텐츠를 덮는 동안엔 배경이 터치를 소비한다 — 안 그러면
                    // 바에 가려 안 보이는 셀·버튼이 바 위 탭에 반응한다(탭 관통).
                    // 감수한 손실: 솔리드 구간엔 바 영역(상단 44pt 밴드)에서 시작한 드래그로는
                    // 스크롤할 수 없다 — 탭 관통을 막는 대가로 의도한 트레이드오프이니
                    // "바 위에서 스크롤이 안 된다"는 이유로 false로 되돌리지 말 것(관통 재발).
                    .allowsHitTesting(showNavTitle)
                    .onChange(of: proxy.size.height, initial: true) { _, height in
                        navigationBarBottomY = height
                    }
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    /// threedots 드롭다운(오류 제보 / 평가 삭제).
    var menuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // 바깥 탭으로 닫기 위한 투명 레이어.
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { isMenuPresented = false }

            WSSDropdownMenu(items: [
                WSSDropdownItem(title: "오류 제보") {
                    isMenuPresented = false
                    viewModel.track(.errorReportTapped)
                    if let url = AppURL.errorReport { openURL(url) }
                },
                WSSDropdownItem(title: "평가 삭제") {
                    isMenuPresented = false
                    viewModel.track(.reviewDeleteTapped)
                    // 삭제할 평가가 없으면 VM이 무시한다(알럿 표시 여부 판단은 VM 소유).
                    viewModel.handle(.deleteReviewTapped)
                }
            ])
            .frame(width: 120)
            .padding(.top, 44)
            .padding(.trailing, 20)
        }
    }

    /// 피드 셀 threedots 드롭다운 — 탭한 셀의 threedots 바로 아래에 뜬다(앵커는 셀 실측 y).
    /// 내 글이면 수정/삭제, 남의 글이면 신고 2종(글자색 빨강) — Figma 6773-26280/26272.
    func feedMenuOverlay(_ context: FeedMenuContext) -> some View {
        // 화면 하단 셀에서는 앵커를 그대로 쓰면 메뉴가 화면 밖으로 잘린다 →
        // 전부 보이는 위치까지만 내려가게 클램프한다(threedots에서 떨어져도 전부 보이는 쪽 우선).
        // 메뉴 높이 107 = WSSDropdownMenu 항목 고정 높이 53 × 2 + 구분선.
        let anchorY = scrollViewHeight > 0
            ? min(context.anchorY, scrollViewHeight - 107 - 20)
            : context.anchorY
        return ZStack(alignment: .topTrailing) {
            // 바깥 탭으로 닫기 위한 투명 레이어 — 떠 있는 동안 스크롤도 막아 앵커가 어긋나지 않는다.
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { feedMenuContext = nil }

            WSSDropdownMenu(items: feedMenuItems(context.feed))
                .frame(width: 190)
                .padding(.top, anchorY)
                .padding(.trailing, 20)
        }
        // 앵커 y가 화면 최상단(상태바 포함) 기준(스크롤 좌표공간 실측)이라 좌표계를 맞춘다 —
        // 루트 ZStack은 안전영역 안쪽이므로 이걸 빼면 메뉴가 안전영역 높이만큼 내려간다.
        .ignoresSafeArea(edges: .top)
    }

    /// 표지 탭 시 뜨는 대형 표지 오버레이 — dim 배경 위에 표지를 원본 비율 그대로 최대 크기로 띄운다.
    /// X 버튼 또는 표지 바깥 탭으로 닫는다(표지 자체 탭은 무시 — dim의 제스처가 형제 뷰라 표지 위 탭엔 안 닿는다).
    var largeCoverOverlay: some View {
        ZStack {
            Color.wssBlack60
                .ignoresSafeArea()
                .onTapGesture { isLargeCoverPresented = false }

            // 미리 받아 둔 원본 이미지를 동기로 그린다 — AsyncImage는 열 때마다 .empty phase부터
            // 시작해 캐시 히트여도 placeholder가 번쩍인다(largeCoverUIImage 주석 참고).
            // scaledToFit이 가로(패딩 20)·세로(패딩 60) 제약 중 먼저 걸리는 쪽에 맞춰 비율을 유지한다
            // — V1(UIKit)에서 이미지 비율로 분기해 폭/높이를 계산하던 것과 같은 결과.
            // 세로 패딩 60 = X 버튼 높이 44 + 여유 — 세로로 아주 긴 표지가 버튼 영역을 침범하지 않는 하한.
            Group {
                if let uiImage = largeCoverUIImage {
                    largeCover(Image(uiImage: uiImage))
                } else {
                    largeCover(WSSImage.imgLoadingThumbnail.swiftUIImage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
        }
        // prefetch가 실패했던 경우의 재시도 — 열려 있는 동안 도착하면 그대로 교체된다.
        .task { await loadLargeCoverIfNeeded() }
        // ZStack은 안전영역 크기라 topTrailing = 안전영역 상단(디자인의 상태바 아래 위치와 동일).
        .overlay(alignment: .topTrailing) {
            Button {
                isLargeCoverPresented = false
            } label: {
                // 에셋 원색(wssGray300)은 dim 위에서 안 보여 template으로 흰색을 입힌다(네비바 버튼과 같은 이유).
                WSSImage.icCancelModal.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Color.wssWhite)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
    }

    /// 대형 표지 공통 스타일 — 클립·그림자는 핏된 이미지 자신에 건다(컨테이너에 걸면 제안 영역 전체에 적용될 수 있다).
    func largeCover(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.wssBlack.opacity(0.1), radius: 15, x: 0, y: 2)
    }

    /// 대형 표지 prefetch. `URLSession.shared`는 URLCache를 공유하므로
    /// 헤더 AsyncImage가 이미 받은 응답이면 재다운로드 없이 캐시에서 온다.
    func loadLargeCoverIfNeeded() async {
        guard largeCoverUIImage == nil, let url = coverImageURL else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        largeCoverUIImage = UIImage(data: data)
    }

    /// 첫 진입 평가 온보딩 오버레이(#221, V1 parity) — 화면을 딤 처리하되 **평가 상태바 자리만 뚫어**
    /// (스포트라이트) 그 아래의 실제 상태바가 밝게 비치게 하고, 바로 아래 말풍선으로 "평가해보세요" 힌트를 띄운다.
    /// 어디를 탭하든 닫히며(딤 구멍 위 탭이 실제 상태바로 새지 않게 최상단 투명 레이어가 먼저 받는다),
    /// 닫으면 `markSeen`으로 앱 전역에서 다시 뜨지 않는다.
    /// - `spotlight`: 상태바의 화면 좌표 프레임(scrollSpaceName 좌표 = ScrollView가 상태바까지 확장돼 화면 좌상단 기준).
    ///   ZStack에 `ignoresSafeArea`를 걸어 오버레이 좌표 원점도 화면 좌상단에 맞춰 이 프레임과 일치시킨다.
    func reviewOnboardingOverlay(_ spotlight: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            // 딤 — 상태바 사각형만 역마스크로 뚫어, 그 아래의 실제 상태바가 밝게 보인다.
            Color.wssBlack60
                .reverseMask {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: spotlight.width, height: spotlight.height)
                        .position(x: spotlight.midX, y: spotlight.midY)
                }
                .allowsHitTesting(false)

            // 말풍선 힌트 — 상태바 바로 아래 6pt, 화면 가로 중앙(= 상태바 midX, 상태바가 화면폭을 꽉 채워서다).
            // 꼬리가 위(상태바)를 가리킨다. V1 배치(reviewButton.bottom+6, centerX)와 동일.
            speechBalloonHint
                .position(x: spotlight.midX, y: spotlight.maxY + 6 + onboardingBalloonSize.height / 2)
                .allowsHitTesting(false)

            // 어디를 탭하든 닫힘 — 구멍(실제 상태바) 위 탭도 이 레이어가 먼저 받아 평가 화면으로 새지 않게 한다.
            Color.wssBlack.opacity(0.001)
                .onTapGesture { viewModel.handle(.dismissReviewOnboarding) }
        }
        .ignoresSafeArea()
    }

    /// 온보딩 말풍선 — 연보라 말풍선(위 꼬리) 위에 2줄 힌트 문구. 문구는 말풍선 하단에 붙인다(V1과 동일).
    var speechBalloonHint: some View {
        WSSImage.imgSpeechBalloon.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: onboardingBalloonSize.width, height: onboardingBalloonSize.height)
            .overlay(alignment: .bottom) {
                Text("읽기 상태를 체크하여\n작품을 평가해보세요!")
                    .applyWSSFont(.body3, color: .wssPrimary100)
                    .padding(.bottom, 8)
            }
    }

    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(NovelDetailViewModel.Tab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .background(Color.wssWhite)
    }

    func tabItem(_ tab: NovelDetailViewModel.Tab) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.handle(.selectTab(tab))
        } label: {
            VStack(spacing: 0) {
                Spacer().frame(height: 15)
                Text(tabTitle(tab))
                    .applyWSSFont(.title2)
                    .foregroundStyle(isSelected ? Color.wssBlack : Color.wssGray200)
                Spacer().frame(height: 15)
                // 밑줄 두께(선택 2/비선택 1)가 달라도 항목 높이가 같도록 2pt 슬롯에 bottom 정렬.
                Rectangle()
                    .fill(isSelected ? Color.wssBlack : Color.wssGray70)
                    .frame(height: isSelected ? 2 : 1)
                    .frame(height: 2, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 피드 탭 전용 플로팅 작성 버튼.
    var floatingWriteButton: some View {
        Button {
            guard let novel = viewModel.state.information?.novel else { return }
            viewModel.track(.writeFloatingButtonTapped)
            onRoute(.createFeed(connectedNovel(from: novel)))
        } label: {
            UnevenRoundedRectangle(
                topLeadingRadius: 54.75,
                bottomLeadingRadius: 54.75,
                bottomTrailingRadius: 9.125,
                topTrailingRadius: 54.75
            )
            .fill(Color.wssBlack)
            .frame(width: 65, height: 65)
            .overlay {
                WSSImage.icPencil.swiftUIImage
                    .resizable()
                    .frame(width: 26, height: 26)
            }
            .shadow(color: Color.wssBlack.opacity(0.1), radius: 5.3, x: 5, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 26)
        .padding(.bottom, 25)
    }
}

// MARK: - Presentation

private extension NovelDetailView {

    func tabTitle(_ tab: NovelDetailViewModel.Tab) -> String {
        switch tab {
        case .info: "정보"
        case .feed: "피드"
        }
    }

    /// 네비 타이틀에 쓸 작품 제목. 관심 토글이 반영되는 state.novel 우선(제목은 불변이라 어느 쪽이든 동일).
    var novelTitle: String {
        viewModel.state.novel?.title ?? viewModel.state.information?.novel.title ?? ""
    }

    /// 완결/휴재복귀 알림 둘 중 하나라도 켜져 있는지 — 네비바 종 아이콘을 채운 모양+wssPrimary100으로
    /// 바꾸는 조건. 로드 전(`isLoading`)엔 둘 다 기본값 false라 자연히 false(빈 종)로 시작한다.
    var isAnyNotificationEnabled: Bool {
        notificationSettingViewModel.state.isCompletionNotificationEnabled
            || notificationSettingViewModel.state.isHiatusReturnNotificationEnabled
    }

    /// 피드 작성 화면에 "연결 작품"으로 미리 채워 넘길 값 — `Novel.genres`는 배열이라 첫 번째만 쓴다
    /// (`CreateFeedViewModel.confirmSelectedNovel`의 검색 결과 연결과 같은 변환 규칙).
    func connectedNovel(from novel: Novel) -> ConnectedNovel {
        ConnectedNovel(id: novel.id, title: novel.title, genre: novel.genres.first, rating: novel.rating)
    }

    /// 대형 표지 오버레이에 쓸 표지 URL(표지는 불변이라 novel/information 어느 쪽이든 동일).
    var coverImageURL: URL? {
        viewModel.state.novel?.thumbnailImage ?? viewModel.state.information?.novel.thumbnailImage
    }

    /// 조금이라도 위로 스크롤됐는지 — 스크롤 반응형 네비 타이틀 표시 여부.
    /// -1 임계값은 rest 지점(≈0)의 부동소수 지터로 깜빡이지 않게 하는 여유.
    var showNavTitle: Bool {
        viewModel.state.information != nil && scrollOffsetY < -1
    }

    /// 탭 콘텐츠가 확보해야 할 최소 높이 = 스티키 상태에서 탭바 아래 남는 화면 영역.
    /// 이만큼 있으면 어떤 탭으로 바꿔도 스티키 지점까지 스크롤할 여유가 남아 offset 클램프(=화면 튐)가 없다.
    /// 아직 실측 전(0)이면 0 → 최소 높이 제약 없음.
    var tabContentMinHeight: CGFloat {
        max(0, scrollViewHeight - navigationBarBottomY - tabBarHeight)
    }

    /// 스크롤되는 원본 탭바가 네비바 하단까지 올라왔는지 — 상단 오버레이의 스티키 탭바 표시 여부.
    /// 두 좌표 모두 화면 좌상단(상태바 포함) 기준이라 그대로 비교한다.
    /// 임계선을 아직 못 쟀으면(0) 표시하지 않는다.
    var showStickyTabBar: Bool {
        viewModel.state.information != nil
            && navigationBarBottomY > 0
            && tabBarMinY <= navigationBarBottomY
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    /// 토스트 의미값 → 표현. 실패는 공통 문구를 쓴다 — 케이스별 전용 문구가 필요해지면
    /// WSSToastType에 케이스를 더한다(허락 후).
    var toastType: WSSToastType {
        switch viewModel.state.presentedToast {
        case .reviewDeleted: .novelReviewDeleted
        case .unavailableUser: .unknownUser
        case .reportFeedAlreadyReported: .alreadyReportedFeed
        default: .unknownError
        }
    }

    var deleteReviewAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isDeleteReviewAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissDeleteReviewAlert) } }
        )
    }

    /// 종 아이콘 탭 시 시스템 푸시 권한이 denied일 때(`notificationBellTapped()`)의 기기 설정 유도 알럿 —
    /// 열지 말지는 VM이 시스템 권한을 확인해 판단한다(`SettingFeature.notificationMenuTapped`와 동일 패턴).
    var pushAuthorizationAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isPushAuthorizationAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissPushAuthorizationAlert) } }
        )
    }

    /// 종 아이콘 탭 → 알림 설정 시트. 열어도 되는지(권한 확인)는 VM이 판단한다.
    var notificationSettingSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isNotificationSettingSheetPresented },
            set: { if !$0 { viewModel.handle(.dismissNotificationSettingSheet) } }
        )
    }

    /// 피드 소유 여부 → 드롭다운 항목. 내 글 = 수정/삭제, 남의 글 = 신고 2종(빨강).
    func feedMenuItems(_ feed: TotalFeed) -> [WSSDropdownItem] {
        if feed.isMyFeed {
            [
                WSSDropdownItem(title: "수정하기") {
                    feedMenuContext = nil
                    // 수정하고 돌아오면 이 셀만 상세로 다시 맞춘다(작성 성공 리셋은 작성에만 붙는다, #256).
                    viewModel.handle(.feedVisited(feed.feedId))
                    onRoute(.editFeed(feed.feedId))
                },
                WSSDropdownItem(title: "삭제하기") {
                    feedMenuContext = nil
                    viewModel.handle(.deleteFeedTapped(feed.feedId))
                }
            ]
        } else {
            [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportSpoilerFeedTapped(feed.feedId))
                    },
                    textColor: Color.wssSecondary100
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportImproperFeedTapped(feed.feedId))
                    },
                    textColor: Color.wssSecondary100
                )
            ]
        }
    }

    var feedAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedFeedAlert != nil },
            set: { if !$0 { viewModel.handle(.dismissFeedAlert) } }
        )
    }

    /// 피드 알럿 의미값 → 컴포넌트 알럿 타입. nil일 땐 어떤 타입이든 상관없다(알럿이 숨겨져 있음).
    var feedAlertType: WSSAlertType {
        switch viewModel.state.presentedFeedAlert {
        case .deleteFeed, nil: .deleteMyFeed
        case .reportSpoiler: .reportSpoilerContent
        case .reportImproper: .reportImproperContent
        case .reportSpoilerCompleted: .receivedReportSpoilerContent
        case .reportImproperCompleted: .receivedReportImproperContent
        }
    }

    /// 알럿 버튼 액션 — 인덱스가 버튼 순서와 일치해야 한다(확인 알럿 [취소, 실행] / 완료 알럿 [확인]).
    var feedAlertActions: [() -> Void] {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoilerCompleted, .reportImproperCompleted:
            [{ viewModel.handle(.dismissFeedAlert) }]
        default:
            [
                { viewModel.handle(.dismissFeedAlert) },
                { viewModel.handle(.confirmFeedAlert) }
            ]
        }
    }
}

// MARK: - Scroll-reactive nav title

/// 스크롤 오프셋 측정용 ScrollView 좌표공간 이름.
private let scrollSpaceName = "novelDetailScroll"

/// 온보딩 말풍선 크기(V1 `imgSpeechBalloon` 147×64 그대로). 말풍선 위치 계산에도 이 값을 쓴다.
private let onboardingBalloonSize = CGSize(width: 147, height: 64)

// MARK: - Reverse mask (spotlight)

private extension View {
    /// 지정한 모양만큼 자신을 **뚫는** 역마스크 — 딤에 구멍을 내 스포트라이트를 만드는 데 쓴다.
    /// `Rectangle`(불투명)에서 모양을 `destinationOut`으로 빼 그 자리의 알파를 0으로 만든 걸 마스크로 쓴다.
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelDetailView(
            novelID: NovelID(1),
            viewModel: NovelDetailViewModel(
                novelID: NovelID(1),
                loadNovelUseCase: PreviewLoadNovelUseCase(),
                novelInterestUseCase: PreviewNovelInterestUseCase(),
                loadNovelFeedsUseCase: PreviewLoadNovelFeedsUseCase(),
                loadFeedDetailUseCase: PreviewLoadFeedDetailUseCase(),
                feedLikeUseCase: PreviewFeedLikeUseCase(),
                deleteFeedUseCase: PreviewDeleteFeedUseCase(),
                deleteNovelReviewUseCase: PreviewDeleteNovelReviewUseCase(),
                reportSpoilerFeedUseCase: PreviewReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: PreviewReportImproperFeedUseCase(),
                onboardingHintUseCase: PreviewOnboardingHintUseCase(),
                pushAuthorizationChecker: PreviewPushAuthorizationChecker()
            ),
            loadNotificationSettingUseCase: PreviewLoadNovelNotificationSettingUseCase(),
            updateNotificationSettingUseCase: PreviewUpdateNovelNotificationSettingUseCase(),
            onRoute: { print("화면 전환 요청: \($0)") },
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

private struct PreviewLoadNovelUseCase: LoadNovelUseCase {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        NovelInformation(
            novel: Novel(
                id: id,
                thumbnailImage: nil,
                title: "당신의 이해를 돕기 위하여",
                authors: ["이보라"],
                genres: [.romanceFantasy],
                interestCount: 128,
                rating: 4.4,
                ratingCount: 52,
                isInterested: false
            ),
            feedCount: 3,
            publicationStatus: .completed,
            userReview: nil,
            description: "왕실에는 막대한 빚이 있었고, 그들은 빚을 갚기 위해 왕녀인 바이올렛을 막대한 돈을 지녔지만 공작의 사생아인 윈터에게 시집보낸다.",
            platforms: [],
            attractivePoints: [.character, .relationship, .writingSkill],
            keywords: [],
            readingStatusCount: [.watching: 130, .watched: 10, .quit: 100]
        )
    }
}

private struct PreviewNovelInterestUseCase: NovelInterestUseCase {
    func add(id: NovelID) async throws(RepositoryError) {}
    func remove(id: NovelID) async throws(RepositoryError) {}
}

private struct PreviewLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {
    func execute(novelID: NovelID,
                 lastFeedID: FeedID,
                 size: Int?) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}

private struct PreviewDeleteNovelReviewUseCase: DeleteNovelReviewUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) {}
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) {}
    func unlike(feedID: FeedID) async throws(RepositoryError) {}
}

private struct PreviewLoadFeedDetailUseCase: LoadFeedDetailUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> FeedDetail {
        throw .notFound
    }
}

private struct PreviewDeleteFeedUseCase: DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) {}
}

private struct PreviewLoadNovelNotificationSettingUseCase: LoadNovelNotificationSettingUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        NovelNotificationSetting(isCompletionNotificationEnabled: false, isHiatusReturnNotificationEnabled: false)
    }
}

private struct PreviewUpdateNovelNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase {
    func execute(novelID: NovelID, setting: NovelNotificationSetting) async throws(RepositoryError) {}
}

private struct PreviewPushAuthorizationChecker: PushAuthorizationChecker {
    func authorizationStatus() async -> PushAuthorizationStatus { .authorized }
    func requestAuthorization() async -> Bool { true }
}

private struct PreviewReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}

private struct PreviewReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}

/// Preview는 온보딩을 항상 "봤음"으로 둬 오버레이가 뜨지 않게 한다(레이아웃 확인이 목적).
private struct PreviewOnboardingHintUseCase: OnboardingHintUseCase {
    func hasSeen(_ hint: OnboardingHint) -> Bool { true }
    func markSeen(_ hint: OnboardingHint) {}
}
