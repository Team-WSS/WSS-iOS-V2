//
//  UserPageView.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import BaseDomain
import ProfileDomain
import NovelDomain
import FeedDomain
import SocialDomain
import CollectionDomain
import Logger

struct UserPageView: View {

    /// 피드 셀 threedots 드롭다운 표시 컨텍스트 — 대상 피드(신고 항목 확정용)와 앵커(threedots 하단의 화면 y).
    struct FeedMenuContext {
        let feed: TotalFeed
        let anchorY: CGFloat
    }

    @State private var viewModel: UserPageViewModel
    @State private var isScrolledFromTop = false
    @State private var selectedTab: Tab = .statistic
    @Namespace private var tabIndicatorNamespace

    /// 툴바 threedots 드롭다운("차단하기") 표시 여부 — VM 판단이 필요 없는 순수 표시 상태.
    @State private var isMenuPresented = false
    /// 피드 셀 threedots 드롭다운(스포일러/부적절한 표현 신고) — nil이 아니면 해당 피드의 메뉴가 떠 있다.
    @State private var feedMenuContext: FeedMenuContext?
    /// 각 피드 셀 상단의 화면 y(스크롤 좌표공간 실측) — threedots 앵커 계산용(NovelDetailFeedTab과 동일 방식).
    @State private var feedCellTopYs: [FeedID: CGFloat] = [:]

    @Environment(\.dismiss) private var dismiss

    private let userID: UserID

    /// "서재" 블록(제목 옆 화살표 아이콘 + 통계 행) 탭 → 이 유저의 서재 진입 콜백. 실제 화면 전환
    /// (`LibraryFactory.makeUserLibraryView` 조립)은 호출자(App 조정 계층)가 수행한다.
    private let onLibraryTapped: () -> Void
    /// "활동기록 더보기" 탭 → 전체 피드 목록(`UserFeedListView`) 진입 콜백. 실제 화면 전환
    /// (`UserPageFeatureFactory.makeFeedListView` 조립)은 호출자(App)가 수행한다(#201) — 그 화면이
    /// 필요로 하는 `nickname`/`profileImage`는 이 화면이 이미 로드해둔 프로필 값을 그대로 실어 보낸다.
    private let onFeedListTapped: (UserID, String, URL?) -> Void
    /// 컬렉션 미리보기 항목 탭 → 그 컬렉션 상세로 이동. 실제 화면 전환(`CollectionFeature`의 상세 화면
    /// 조립)은 호출자(App)가 수행한다(#201) — 마이페이지 `onCollectionItemTapped`와 동일 계약.
    private let onCollectionItemTapped: (CollectionID) -> Void
    /// 컬렉션 섹션 헤더 탭(컬렉션이 있을 때) → 이 유저의 컬렉션 목록으로 이동. 실제 화면 전환
    /// (`CollectionFeature`의 목록 화면 조립, "내 컬렉션" 탭만 보이는 모드)은 호출자(App)가 수행한다.
    private let onCollectionListTapped: () -> Void

    init(
        viewModel: UserPageViewModel,
        userID: UserID,
        onLibraryTapped: @escaping () -> Void = {},
        onFeedListTapped: @escaping (UserID, String, URL?) -> Void = { _, _, _ in },
        onCollectionItemTapped: @escaping (CollectionID) -> Void = { _ in },
        onCollectionListTapped: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.userID = userID
        self.onLibraryTapped = onLibraryTapped
        self.onFeedListTapped = onFeedListTapped
        self.onCollectionItemTapped = onCollectionItemTapped
        self.onCollectionListTapped = onCollectionListTapped
    }

    var body: some View {
        Group {
            if viewModel.state.hasLoadError {
                NetworkErrorView {
                    viewModel.handle(.load)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        profileSection
                            // 스크롤 반응형 네비 타이틀 — 프로필 섹션 상단이 화면 밖으로 올라가면(minY < 0)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onChange(of: proxy.frame(in: .named(scrollCoordinateSpace)).minY,
                                                  initial: true) { _, newY in
                                            isScrolledFromTop = newY < -1
                                        }
                                }
                            )

                        Section {
                            if viewModel.state.isProfilePrivate {
                                privateProfileView
                            } else {
                                switch selectedTab {
                                case .statistic:
                                    userPageLibrarySection

                                    divider

                                    // 타이틀 행은 컬렉션 개수와 무관하게 항상 노출한다(사용자 확정,
                                    // 2026-08-25) — 0개면 타이틀 행만 보이고, 탭하면 안내 토스트로
                                    // 응답한다(`userPageCollectionSection` 참고). 이전엔 장르 취향
                                    // 섹션처럼 데이터가 없으면 섹션째 숨겼다.
                                    userPageCollectionSection

                                    divider

                                    if !viewModel.hasNoGenrePreferenceData {
                                        userPageGenreSection

                                        divider
                                    }

                                    userPageKeywordSection
                                case .feed:
                                    userPageFeedSection
                                }
                            }
                        } header: {
                            stickyHeaderSection
                        }
                    }
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                // ScrollView 뷰포트 고정 배경(스크롤 콘텐츠와 무관) — 하단으로 당겨 바운싱해도
                // wssWhite가 비치도록. 상단은 profileSection의 오버슈트 배경이 그 위를 덮는다.
                .background(WSSColor.wssWhite.swiftUIColor)
                .overlay {
                    if viewModel.state.isLoading {
                        LoadingView()
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isMenuPresented {
                        profileMenuOverlay
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let feedMenuContext {
                        feedMenuOverlay(feedMenuContext)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        // 스크롤 전엔 프로필 섹션과 이어지는 primary20, 프로필 섹션이 화면 밖으로 스크롤되면(닉네임
        // 타이틀 전환과 동일 트리거인 isScrolledFromTop) 아래 콘텐츠와 이어지는 wssWhite로 전환한다.
        .toolbarBackground(
            (isScrolledFromTop ? WSSColor.wssWhite : WSSColor.wssPrimary20).swiftUIColor,
            for: .navigationBar
        )
        // 기본값은 스크롤 전엔 투명, 스크롤 후에만 배경이 보이는 자동 동작이라
        // 스크롤 여부와 무관하게 항상 배경이 보이도록 강제한다(색 자체는 위에서 스크롤에 따라 전환).
        .toolbarBackground(.visible, for: .navigationBar)
        // ⚠️ `.animation(value: isScrolledFromTop)`을 body 루트에 걸지 않는다 — `.toolbar { }`가 붙은
        // 서브트리를 감싸면 툴바 principal의 닉네임 `Text` opacity 갱신이 UIKit 브리지(titleView)로
        // 전달되지 않아 계속 숨어있는다(실측 확인, `CollectionFeature.CollectionDetailView`에서 먼저
        // 발견). opacity 대신 아래 `toolbarContent`가 `if`로 뷰 자체를 구조적으로 넣고 뺀다 —
        // 배경 색·닉네임 모두 애니메이션 없이 즉시 전환된다(페이드 아님).
        // 차단 확인 — 알럿은 스스로 닫히지 않으므로 두 버튼 모두 handle 경유로 상태를 되돌린다.
        .showWSSAlert(
            isPresented: blockAlertBinding,
            type: .blockUser,
            buttonActions: [
                { viewModel.handle(.dismissBlockAlert) },  // 취소
                { viewModel.handle(.confirmBlockUser) }    // 차단
            ]
        )
        // 피드 신고 확인·접수 완료 — 의미값(FeedAlert) → 타입·버튼 매핑은 아래 Presentation.
        .showWSSAlert(
            isPresented: feedAlertBinding,
            type: feedAlertType,
            buttonActions: feedAlertActions
        )
        .showWSSToast(isPresented: actionErrorToastBinding, type: .unknownError)
        .showWSSToast(isPresented: noCollectionsToastBinding, type: .noCollections)
        .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .onAppear {
            viewModel.handle(.load)
        }
    }

    private var divider: some View {
        Rectangle()
            .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
            .frame(height: 3)
    }

    /// 상대가 프로필을 비공개로 설정한 경우(`RepositoryError.privateProfile`) — 재시도 버튼 없음
    /// (상대가 설정을 바꾸기 전엔 다시 시도해도 동일하게 거부된다, `NetworkErrorView`와의 차이).
    private var privateProfileView: some View {
        VStack(spacing: 20) {
            WSSImage.imgEmptyCatLocked.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 160)

            Text("\(viewModel.state.profile?.nickname ?? "")님의 프로필은\n비공개 상태에요")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
        .background(WSSColor.wssWhite.swiftUIColor)
    }

    // MARK: - Profile
    
    private var profileSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            AsyncImage(url: viewModel.state.profile?.characterImage) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    WSSImage.imgEmptyCover.swiftUIImage
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(Circle())
            .frame(width: 94, height: 94)

            Spacer().frame(height: 20)

            Text(viewModel.state.profile?.nickname ?? "")
                .applyWSSFont(.headline1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            Text(viewModel.state.profile?.introduction ?? "")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 40)

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
        .background(WSSColor.wssPrimary20.swiftUIColor)
        // 상단으로 당겨서 바운싱할 때도 흰 배경이 비치지 않도록, 실제 레이아웃엔 영향 없이
        // 위쪽으로만 충분히 큰 사각형을 더 그린다(하단은 그대로 둬 하단 바운싱은 다음 섹션의 흰 배경과 자연히 이어진다).
        .background(alignment: .top) {
            WSSColor.wssPrimary20.swiftUIColor
                .frame(height: 1000)
                .offset(y: -1000)
        }
    }

    enum Tab: CaseIterable, Equatable {
        case statistic
        case feed

        var displayName: String {
            switch self {
            case .statistic:
                "통계"
            case .feed:
                "활동"
            }
        }
    }

    private var stickyHeaderSection: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                stickyHeaderItem(tab: tab)
            }
        }
    }

    private func stickyHeaderItem(tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            if tab == .feed {
                viewModel.handle(.loadFeeds)
            }
        } label: {
            VStack(spacing: 0) {
                Text(tab.displayName)
                    .applyWSSFont(.body2)
                    .foregroundStyle(selectedTab == tab ? WSSColor.wssBlack.swiftUIColor : WSSColor.wssGray100.swiftUIColor)
                    .frame(height: 46)

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(WSSColor.wssGray70.swiftUIColor)

                    if selectedTab == tab {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabIndicatorNamespace)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(WSSColor.wssWhite.swiftUIColor)
        }
        .buttonStyle(.plain)
    }
    
    private var userPageLibrarySection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)
            
            HStack(alignment: .center, spacing: 0) {
                Text("서재")
                    .applyWSSFont(.title1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer()
                
                Button(action: onLibraryTapped) {
                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 8)

            WSSLibrarySection(
                interest: viewModel.state.registeredNovelStats?.interest ?? 0,
                watching: viewModel.state.registeredNovelStats?.watching ?? 0,
                watched: viewModel.state.registeredNovelStats?.watched ?? 0,
                quit: viewModel.state.registeredNovelStats?.quit ?? 0,
                action: onLibraryTapped
            )
            
            Spacer().frame(height: 30)
        }
        .background(WSSColor.wssWhite.swiftUIColor)
    }

    /// 타이틀 행 텍스트 스타일은 "서재"/"장르취향"과 동일(플레인 텍스트 + 우측 화살표) — 마이페이지
    /// `CollectionSection`의 "컬렉션 N개" 카운트-인라인 헤더와는 다르다(Figma가 이 화면에서만 카운트를
    /// 안 보여줌). 컬렉션이 0개여도 타이틀 행은 그대로 보이고 미리보기 행만 비운다(사용자 확정,
    /// 2026-08-25) — 탭 시 안내 토스트로 응답하려면 행이 계속 눈에 보이고 눌러야 하기 때문. 탭 영역은
    /// 화살표(44×44)가 아니라 마이페이지 `CollectionSection.header`와 동일하게 행 전체로 넓혔다
    /// (`.contentShape(Rectangle())`, 좁은 화살표만으론 "행을 클릭하면" 요구와 안 맞는다). 미리보기
    /// 항목 자체는 `CollectionPreviewRow`로 공유.
    private var userPageCollectionSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            collectionSectionHeader
                .padding(.horizontal, 20)

            if viewModel.hasCollections {
                Spacer().frame(height: 8)

                CollectionPreviewRow(previews: viewModel.state.collectionPreviews, onItemTapped: onCollectionItemTapped)
            }

            Spacer().frame(height: viewModel.hasCollections ? 30 : 16)
        }
        .background(WSSColor.wssWhite.swiftUIColor)
    }

    /// 컬렉션이 있으면 목록으로 이동(`onCollectionListTapped`, App이 조립), 없으면 VM이 "컬렉션을
    /// 등록하지 않은 유저에요" 토스트를 띄운다 — "서재" 블록(`onLibraryTapped`)과 동일하게 순수
    /// 네비게이션은 View가 직접 콜백을 부르고, VM은 상태(토스트)만 관리한다.
    private var collectionSectionHeader: some View {
        Button {
            if viewModel.hasCollections {
                onCollectionListTapped()
            } else {
                viewModel.handle(.collectionSectionTapped)
            }
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text("컬렉션")
                    .applyWSSFont(.title1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                Spacer()

                WSSImage.icNavigateRight.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var userPageGenreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 29)
            
            Text("장르 취향")
                .applyWSSFont(.title1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .padding(.horizontal, 20)
            
            Spacer().frame(height: 21)
            
            GenreSection(genrePreferences: viewModel.state.genrePreferences,
                         showGenreBadgeText: false)
        }
        .background(WSSColor.wssWhite.swiftUIColor)
    }
    
    private var userPageKeywordSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 30)
            
            Text("작품 취향")
                .applyWSSFont(.title1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .padding(.horizontal, 20)
            
            Spacer().frame(height: 10)
            
            KeywordSection(
                hasNoData: viewModel.hasNoPreferenceData,
                attractivePointsText: attractivePointsText,
                keywordPreferences: viewModel.keywordPreferences
            )
        }
        .background(WSSColor.wssWhite.swiftUIColor)
    }

    // MARK: - 활동(피드)

    private var userPageFeedSection: some View {
        Group {
            if viewModel.state.feeds.isEmpty {
                if viewModel.state.isLoadingFeeds {
                    LoadingView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 90)
                } else if viewModel.state.feedsLoadFailed {
                    NetworkErrorView {
                        viewModel.handle(.loadFeeds)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 90)
                } else {
                    emptyFeedsView
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.visibleFeeds, id: \.feedId) { feed in
                        feedCell(feed)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onChange(of: proxy.frame(in: .named(scrollCoordinateSpace)).minY,
                                                  initial: true) { _, newY in
                                            feedCellTopYs[feed.feedId] = newY
                                        }
                                }
                            )
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
                    }

                    // 미리보기(최대 5개) 이후 더 있으면 전체 목록(무한스크롤) 화면으로.
                    if viewModel.hasMoreFeeds {
                        Spacer().frame(height: 20)
                        Button {
                            onFeedListTapped(
                                userID,
                                viewModel.state.profile?.nickname ?? "",
                                viewModel.state.profile?.characterImage
                            )
                        } label: {
                            Text("활동기록 더보기")
                                .applyWSSFont(.title2)
                                .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(WSSColor.wssPrimary100.swiftUIColor,
                                                lineWidth: 1)
                                }
                        }
                        .padding(.horizontal, 20)
                        Spacer().frame(height: 20)
                    }
                }
            }
        }
        .background(WSSColor.wssWhite.swiftUIColor)
    }

    /// "활동" 탭 미리보기가 0개(로드 성공, 실패 아님)일 때 — `privateProfileView`와 같은 톤(이미지+안내문).
    private var emptyFeedsView: some View {
        VStack(spacing: 20) {
            WSSImage.imgEmptyCatEyes.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 160)

            Text("작성한 글이 없어요")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    /// 도메인 `TotalFeed` → 공용 피드 셀 입력값 매핑(`NovelDetailFeedTab`과 동일 매핑).
    private func feedCell(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified
            ),
            profileImageTapped: {},
            threeDotsButtonTapped: {
                // 셀 상단 패딩(20) + 헤더 높이(32) = 52. NovelDetailFeedTab과 동일 계산.
                feedMenuContext = FeedMenuContext(feed: feed, anchorY: (feedCellTopYs[feed.feedId] ?? 0) + 52)
            },
            content: feed.content,
            feedImage: feed.thumbnailImageURL.map {
                WSSFeedImage(thumbnailImageURL: $0, imageCount: feed.imageCount)
            },
            linkNovel: feed.connectedNovel.flatMap { connected in
                connected.genre.map {
                    WSSLinkNovel(
                        genreType: $0,
                        novelTitle: connected.title,
                        novelRating: connected.rating ?? 0,
                        linkNovelTapped: {
                            //TODO: - 연결 작품 상세로 이동
                        }
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount
            ),
            isLiked: feed.isLiked,
            likeButtonTapped: {
                viewModel.handle(.toggleFeedLike(feed.feedId))
            },
            isSpoiler: feed.isSpoiler,
            isPrivate: !feed.isPublic
        )
    }
}

// MARK: - Toolbar

extension UserPageView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isMenuPresented.toggle()
            } label: {
                WSSImage.icThreedots.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 18, height: 18)
            }
        }

        // ⚠️ `opacity(isScrolledFromTop ? 1 : 0)` 모디파이어 값만으로는 이 Text가 UIKit 브리지
        // (titleView)에 갱신되지 않고 계속 숨어있는다(실측 확인 — 애니메이션 유무·위치와 무관,
        // `CollectionFeature.CollectionDetailView`에서 먼저 발견). 대신 `if`로 뷰 자체를 구조적으로
        // 넣고 뺀다 — `ToolbarContentBuilder`가 진짜 다른 콘텐츠로 인식해야 브리지가 갱신된다.
        if isScrolledFromTop {
            ToolbarItem(placement: .principal) {
                Text(viewModel.state.profile?.nickname ?? "웹소소")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Menu

private extension UserPageView {
    /// 툴바 threedots 드롭다운 — 화면 우상단 고정.
    var profileMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // 바깥 탭으로 닫기 위한 투명 레이어.
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { isMenuPresented = false }

            WSSDropdownMenu(items: [
                WSSDropdownItem(title: "차단하기") {
                    isMenuPresented = false
                    viewModel.handle(.blockUserTapped)
                }
            ])
            .frame(width: 120)
            .padding(.trailing, 20)
        }
    }

    /// 피드 셀 threedots 드롭다운(스포일러/부적절한 표현 신고) — 탭한 셀의 threedots 바로 아래에 뜬다
    /// (앵커는 셀 실측 y). `NovelDetailFeature` 피드 셀 드롭다운과 동일 항목·색(빨강).
    func feedMenuOverlay(_ context: FeedMenuContext) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { feedMenuContext = nil }

            WSSDropdownMenu(items: [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportSpoilerFeedTapped(context.feed.feedId))
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportImproperFeedTapped(context.feed.feedId))
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ])
            .frame(width: 190)
            .padding(.top, context.anchorY)
            .padding(.trailing, 20)
        }
    }
}

// MARK: - Scroll Offset

private let scrollCoordinateSpace = "UserPageScroll"

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    // 계산 프로퍼티로 두면 저장(공유 가변 상태)이 없어 concurrency-safe하다. PreferenceKey 요구사항 충족.
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Presentation

private extension UserPageView {
    var attractivePointsText: String {
        let points = viewModel.state.novelPreference?.attractivePoints ?? []
        return points.map(\.displayName).joined(separator: ", ")
    }

    var blockAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isBlockAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissBlockAlert) } }
        )
    }

    var actionErrorToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.hasActionError },
            set: { if !$0 { viewModel.handle(.dismissActionErrorToast) } }
        )
    }

    var noCollectionsToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isNoCollectionsToastPresented },
            set: { if !$0 { viewModel.handle(.dismissNoCollectionsToast) } }
        )
    }

    var feedAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedFeedAlert != nil },
            set: { if !$0 { viewModel.handle(.dismissFeedAlert) } }
        )
    }

    /// 피드 신고 알럿 의미값 → 컴포넌트 알럿 타입. nil일 땐 어떤 타입이든 상관없다(알럿이 숨겨져 있음).
    var feedAlertType: WSSAlertType {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoiler, nil: .reportSpoilerContent
        case .reportImproper: .reportImproperContent
        case .reportSpoilerCompleted: .receivedReportSpoilerContent
        case .reportImproperCompleted: .receivedReportImproperContent
        }
    }

    var feedAlertActions: [() -> Void] {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoiler, .reportImproper, nil:
            [
                { viewModel.handle(.dismissFeedAlert) },
                { viewModel.handle(.confirmFeedAlert) }
            ]
        case .reportSpoilerCompleted, .reportImproperCompleted:
            [
                { viewModel.handle(.dismissFeedAlert) }
            ]
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserPageView(
            viewModel: UserPageViewModel(
                userID: UserID(1),
                loadProfileUseCase: PreviewLoadProfileUseCase(),
                loadGenrePreferencesUseCase: PreviewLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: PreviewLoadNovelPreferencesUseCase(),
                loadUserRegisteredNovelStatsUseCase: PreviewLoadUserRegisteredNovelStatsUseCase(),
                loadCollectionPreviewsUseCase: PreviewLoadCollectionPreviewsUseCase(),
                loadUserFeedsUseCase: PreviewLoadUserFeedsUseCase(),
                feedLikeUseCase: PreviewFeedLikeUseCase(),
                blockUserUseCase: PreviewBlockUserUseCase(),
                reportSpoilerFeedUseCase: PreviewReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: PreviewReportImproperFeedUseCase()
            ),
            userID: UserID(1)
        )
    }
}

private struct PreviewLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(
            nickname: "구리구리스구리구 리스구리구리스구리 구리스",
            introduction: "만나서 반가워요!만나서 반가워요!만나서 반가워요!만나서 반가워요!만나서 반가워요!",
            characterImage: nil,
            isPublic: true,
            genrePreferences: []
        )
    }
}

private struct PreviewLoadGenrePreferencesUseCase: LoadGenrePreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        [
            GenrePreference(genre: .BL, count: 1003),
            GenrePreference(genre: .fantasy, count: 30),
            GenrePreference(genre: .romance, count: 2),
            GenrePreference(genre: .lightNovel, count: 3),
            GenrePreference(genre: .wuxia, count: 123)
        ]
    }
}

private struct PreviewLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        NovelPreference(
            attractivePoints: [.character, .relationship, .material],
            keywords: [
                KeywordPreference(keyword: Keyword(id: KeywordID(1), name: "안녕"), count: 2),
                KeywordPreference(keyword: Keyword(id: KeywordID(2), name: "궁중암투"), count: 5)
            ]
        )
    }
}

private struct PreviewLoadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase {
    func execute(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}

private struct PreviewLoadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase {
    func execute(userID: UserID, size: Int) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        let previews = (1...size).map { index in
            CollectionPreview(
                id: CollectionID(index),
                name: "미리보기 컬렉션 \(index)",
                representativeNovel: CollectionNovel(id: NovelID(index), title: "작품 \(index)", author: "작가 \(index)", thumbnailImage: nil)
            )
        }
        return (previews, previews.count)
    }
}

private struct PreviewLoadUserFeedsUseCase: LoadUserFeedsUseCase {
    func execute(userID: UserID, nickname: String, profileImage: URL?, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(
            items: [
                TotalFeed(
                    feedId: FeedID(1),
                    createdDate: "2026년 7월 25일",
                    content: "이 작품은 너무 재밌어요",
                    author: Author(userId: userID, nickname: nickname, profileImage: profileImage),
                    likeCount: 13,
                    isLiked: false,
                    commentCount: 3,
                    isSpoiler: false,
                    isModified: false,
                    isPublic: true,
                    isMyFeed: false,
                    imageCount: 0
                ),
                TotalFeed(
                    feedId: FeedID(1),
                    createdDate: "2026년 7월 25일",
                    content: "이 작품은 너무 재밌어요",
                    author: Author(userId: userID, nickname: nickname, profileImage: profileImage),
                    likeCount: 13,
                    isLiked: false,
                    commentCount: 3,
                    isSpoiler: false,
                    isModified: false,
                    isPublic: true,
                    isMyFeed: false,
                    imageCount: 0
                )
            ],
            hasNext: false
        )
    }
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) {}
    func unlike(feedID: FeedID) async throws(RepositoryError) {}
}

private struct PreviewBlockUserUseCase: BlockUserUseCase {
    func execute(id: UserID) async throws(RepositoryError) {}
}

private struct PreviewReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}

private struct PreviewReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}
