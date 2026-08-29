//
//  CollectionDetailView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

/// 컬렉션 상세 화면 — 대표 작품 표지를 배경으로 한 히어로(소유자·이름·설명·좋아요/공유) + 작품 그리드.
/// `CollectionListView`의 카드 탭에서 진입한다(`CollectionFeatureFactory.makeCollectionDetailView`가
/// 유일한 진입점). 화면 동작 계약은 `CollectionFeature/CLAUDE.md` 참고.
struct CollectionDetailView: View {

    @State private var viewModel: CollectionDetailViewModel
    /// 히어로 섹션이 화면 밖으로 스크롤되면(닉네임/제목이 즉시 나타남, 페이드 아님) 네비바가 반응한다 —
    /// `UserPageFeature.UserPageView`와 동일 패턴(같은 SDK 제약으로 `GeometryReader`+`onChange` 사용).
    @State private var isScrolledFromTop = false
    /// 이 화면의 유일한 자식은 "컬렉션 수정"(App이 push)뿐이라, 두 번째 이후의 `onAppear`는 항상
    /// "수정 화면에서 복귀"를 뜻한다 — 그때만 무조건 재로드한다(`CollectionListView`의
    /// `hasAppearedOnce` 패턴과 동일 이유, App이 소유한 `NavigationPath`로 옮기며 로컬
    /// `isEditPresented`/`onChange` 대신 이 방식으로 바뀌었다).
    @State private var hasAppearedOnce = false
    /// 카카오 공유 카드 전송 실패 토스트 — 공유는 VM을 거치지 않는 순수 표현이라 View가 소유한다.
    @State private var isShareErrorToastPresented = false
    @Environment(\.dismiss) private var dismiss

    /// 인증 만료 시 로그인 화면 진입 콜백.
    private let onAuthenticationRequired: () -> Void
    /// 작품 그리드 셀 탭 → 작품 상세 진입 콜백. `NovelDetailFeature`로 가야 하지만 Feature 모듈끼리는
    /// 서로 import 못 해 이 화면이 직접 만들 수 없다 — `NovelDetailFeature.onAuthorTapped`와 동일하게
    /// VM을 거치지 않고 View가 탭 즉시 호출하고, 실제 화면 전환은 호출자(App)가 수행한다.
    private let onNovelTapped: (NovelID) -> Void
    /// 더보기 "컬렉션 수정" 탭 콜백. 실제 화면 전환(`CollectionFeatureFactory.makeCreateCollectionView`를
    /// 수정 모드로 조립)은 호출자(App 조정 계층)가 수행한다 — `CreateCollectionView`가 대상 컬렉션을
    /// `id`로 스스로 다시 불러오므로(자기 로드 방식) 이 화면은 `id`만 알면 된다.
    private let onEditTapped: () -> Void

    init(
        viewModel: CollectionDetailViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditTapped: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onNovelTapped = onNovelTapped
        self.onEditTapped = onEditTapped
    }

    var body: some View {
        Group {
            if viewModel.state.hasLoadError {
                NetworkErrorView {
                    viewModel.handle(.load)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        heroSection

                        if let detail = viewModel.state.detail {
                            contentSection(detail)
                        }
                    }
                }
               
                .coordinateSpace(name: scrollCoordinateSpace)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .background(Color.wssWhite)
                .overlay {
                    // 정렬 변경 재조회는 이미 detail이 있는 상태라 전면 로딩으로 덮지 않는다 —
                    // 덮으면 화면 전체가 깜빡이는 것처럼 보인다(사용자 리포트). 진짜 처음 로드일 때만
                    // (detail == nil) 보여준다 — `SosoFeedView`의 `isLoading && currentFeeds.isEmpty`와
                    // 동일 판단.
                    if viewModel.state.isLoading, viewModel.state.detail == nil {
                        LoadingView()
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if viewModel.state.isMenuPresented {
                        menuOverlay
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        // 스크롤 전엔 투명(히어로 이미지가 상태바까지 그대로 비침), 스크롤되면 흰 배경 + 컬렉션명
        // 타이틀로 전환된다(Figma 주석 "스크롤 됐을때 헤더가 컬렉션 명으로 변경").
        .toolbarBackground(
            (isScrolledFromTop ? Color.wssWhite : Color.clear),
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        // ⚠️ `.animation(value: isScrolledFromTop)`을 body 루트에 걸지 않는다 — `.toolbar { }`가 붙은
        // 서브트리를 감싸면 툴바 principal의 `Text` opacity 갱신이 UIKit 브리지(titleView)로 아예
        // 전달되지 않아 계속 숨어있는다(실측 확인 — 로컬/루트 어느 쪽에 걸든 동일 증상). 그래서
        // opacity 대신 아래 `toolbarContent`가 `if`로 뷰 자체를 구조적으로 넣고 뺀다 — 배경·아이콘
        // 색·타이틀 모두 애니메이션 없이 즉시 전환된다(페이드 아님, `UserPageFeature`도 동일).
        .showWSSAlert(
            isPresented: deleteAlertBinding,
            type: .deleteCollection,
            buttonActions: [
                { viewModel.handle(.dismissDeleteAlert) },
                { viewModel.handle(.confirmDelete) }
            ]
        )
        .showWSSToast(isPresented: actionErrorToastBinding, type: .unknownError)
        .showWSSToast(isPresented: $isShareErrorToastPresented, type: .unknownError)
        .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다
        // (`CollectionListView`와 동일 판단).
        .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
            if needsAuth { onAuthenticationRequired() }
        }
        .onAppear {
            // 이 화면의 유일한 자식(컬렉션 수정)에서 복귀한 뒤의 재진입만 무조건 재로드한다 —
            // `CreateCollectionView`가 성공 콜백 없는 자기완결 dismiss 계약이라 복귀했다는 사실만으로
            // 판단한다(`CollectionListView`와 동일 이유).
            if hasAppearedOnce {
                viewModel.handle(.reloadAfterEdit)
            } else {
                hasAppearedOnce = true
                viewModel.handle(.load)
            }
        }
    }
}

// MARK: - Toolbar

private extension CollectionDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                // 이 화면은 "컬렉션 수정"을 같은 스택에 로컬 push하므로 `.onDisappear`로 닫힘을
                // 감지하면 그 push에도 함께 발화해버린다(`CollectionFeature/CLAUDE.md` 참고) —
                // 그래서 진짜 뒤로가기인 여기서 명시적으로 알린다.
                viewModel.handle(.backTapped)
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(navIconColor)
                    .frame(width: 24, height: 24)
            }
        }
        
        // 더보기(수정/삭제)는 소유자에게만 노출된다.
        if viewModel.state.detail?.isMine == true {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.handle(.menuTapped)
                } label: {
                    WSSImage.icThreedots.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(navIconColor)
                        .frame(width: 18, height: 18)
                }
            }
        }
        
        // ⚠️ `opacity(isScrolledFromTop ? 1 : 0)` 모디파이어 값만으로는 이 Text가 UIKit 브리지
        // (titleView)에 갱신되지 않고 계속 숨어있는다(실측 확인 — 애니메이션 유무·위치와 무관).
        // 대신 `if`로 뷰 자체를 구조적으로 넣고 뺀다 — `ToolbarContentBuilder`가 진짜 다른 콘텐츠로
        // 인식해야 브리지가 갱신된다.
        if isScrolledFromTop {
            ToolbarItem(placement: .principal) {
                Text(viewModel.state.detail?.name ?? "")
                    .applyWSSFont(.title2)
                    .foregroundStyle(Color.wssBlack)
                    .lineLimit(1)
            }
        }
    }
    
    var navIconColor: Color {
        isScrolledFromTop ? Color.wssBlack : Color.wssWhite
    }
}

// MARK: - Hero

private extension CollectionDetailView {
    var heroImageURL: URL? {
        guard let detail = viewModel.state.detail else { return nil }
        return detail.novels.first { $0.id == detail.representativeNovelID }?.thumbnailImage
    }
    
    var heroSection: some View {
        ZStack(alignment: .bottom) {
            // 위치·크기는 GeometryReader가 정하고, 실제 콘텐츠(이미지+그라디언트)는
            // heroImageWithGradient로 분리 — 스트레치(아래 주석) 계산과 표시 책임을 나눠 읽기 쉽게 한다.
            // ⚠️ 그라디언트를 이 GeometryReader 밖(예: 형제 ZStack 레이어)에 따로 두면 이미지만
            // 늘어나고 그라디언트는 제자리(heroBackgroundHeight 고정)에 남아, 오버스크롤 중
            // 이미지 위쪽이 그라디언트 없이 그대로 드러나 보인다(실측 — "그라디언트가 잘려 보인다"는
            // 사용자 피드백으로 발견). 이미지와 같은 변환(프레임·스케일·offset)을 함께 받도록
            // 반드시 이 안에 넣을 것.
            GeometryReader { proxy in
                let minY = proxy.frame(in: .named(scrollCoordinateSpace)).minY
                // 당겨서 새로고침(오버스크롤)으로 콘텐츠가 아래로 밀리면 minY가 양수가 된다 —
                // hold 구간 없이 당기는 즉시 그 값에 비례해 확대된다(사용자 확정).
                let stretch = max(0, minY)
                let zoomScale = 1 + stretch / heroBackgroundHeight

                heroImageWithGradient
                    // ⚠️ 표지가 세로로 긴 작품 썸네일이라 `scaledToFill`이 정지 상태에서 이미 가로
                    // 폭 기준으로 세로 방향을 넉넉히 넘치게 스케일해둔 상태다 — 프레임 높이만
                    // 키우는 걸로는 확대되는 느낌이 안 나고(실측) 잘려나가 있던 여백만 드러난다.
                    // 그래서 정지 상태 크롭을 먼저 고정한 뒤 그 결과물 자체를 `scaleEffect`로 키운다.
                    .frame(width: proxy.size.width, height: heroBackgroundHeight, alignment: .top)
                    .clipped()
                    .scaleEffect(zoomScale, anchor: .top)
                    // 확대된 만큼(stretch) 위로 끌어올려야 아래쪽(정보 영역과 맞닿는 경계)이
                    // 밀리지 않고, 확대가 화면 위쪽으로만 번져 오버스크롤 빈틈을 메운다.
                    .offset(y: -stretch)
                    .onChange(of: minY, initial: true) { _, newY in
                        isScrolledFromTop = newY < -1
                    }
            }
            .frame(height: heroBackgroundHeight)

            VStack(spacing: 0) {
                if let detail = viewModel.state.detail {
                    heroInfo(detail)
                }

                Spacer().frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 오버스크롤 시 그라디언트가 이미지와 같이 늘어나도록 한 몸으로 묶어둔 레이어 — 위 heroSection
    /// 주석 참고.
    var heroImageWithGradient: some View {
        ZStack {
            heroImage

            LinearGradient(colors: [.black.opacity(0.6), .black],
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }

    var heroImage: some View {
        AsyncImage(url: heroImageURL) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                Color.wssGray50
            }
        }
    }

    /// 실측 아니라 고정값(336, Figma) — 안전영역이 다른 기기에서도 텍스트 위치는 콘텐츠 흐름을
    /// 따르므로(고정 상단 인셋에 의존하지 않음) 배경 높이만 넉넉히 잡아둔다.
    var heroBackgroundHeight: CGFloat { 320 }

    func heroInfo(_ detail: CollectionDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AsyncImage(url: detail.owner.profileImage) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        WSSImage.imgEmptyCover.swiftUIImage
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(detail.owner.nickname)
                    .applyWSSFont(.title4)
                    .foregroundStyle(Color.wssWhite)
            }

            Spacer().frame(height: 8)

            Text(detail.name)
                .applyWSSFont(.title1)
                .foregroundStyle(Color.wssWhite)
                .lineLimit(2)

            if let description = detail.description, !description.isEmpty {
                Spacer().frame(height: 8)
                
                Text(description)
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssWhite)
                    .lineLimit(2)
            }

            Spacer().frame(height: 16)

            heroButtons(detail)
        }
        .padding(.horizontal, 16)
    }

    func heroButtons(_ detail: CollectionDetail) -> some View {
        HStack(spacing: 8) {
            likeButton(detail)

            if detail.isPrivate {
                privateBadge
            } else {
                shareButton(detail)
            }
        }
    }

    func likeButton(_ detail: CollectionDetail) -> some View {
        Button {
            viewModel.handle(.toggleLike)
        } label: {
            HStack(spacing: 9) {
                (detail.isLiked ? WSSImage.icThumbUpFill : WSSImage.icThumbUp).swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.wssPrimary100)

                Text("좋아요 (\(detail.likeCount))")
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssPrimary100)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(detail.isLiked ? Color.wssPrimary50 : Color.wssWhite)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.wssPrimary100)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            // 아이콘 교체·배경색 전환의 기본 크로스페이드를 짧게 고정(미설정 시 느리게 번진다 —
            // NovelDetailReviewSection.interestButton과 동일 처방, Feature/CLAUDE.md 공통 규칙).
            .animation(.easeInOut(duration: 0.1), value: detail.isLiked)
        }
        .buttonStyle(.plain)
    }

    /// 공유는 **카카오 공유 카드**(`CollectionKakaoShare`, 사용자 확정 2026-08-29, #228) 하나다 — 카카오톡이 있으면
    /// 카카오톡, 없으면 카카오 웹 공유(Safari). 받는 사람이 카드의 "앱에서 보기"로 이 화면에 들어온다(앱이 없으면
    /// 카카오가 App Store로). 시스템 공유 시트는 쓰지 않는다(모듈 CLAUDE.md의 폐기 이력). 순수 표현이라 VM을
    /// 거치지 않는다(`onNovelTapped`와 같은 위상) — 카카오를 여는 것까지가 성공이고, 템플릿 검증·열기 실패는
    /// 사용자 액션 실패라 토스트로 알린다.
    func shareButton(_ detail: CollectionDetail) -> some View {
        Button {
            Task {
                do {
                    try await CollectionKakaoShare.share(detail, coverImageURL: heroImageURL)
                } catch {
                    isShareErrorToastPresented = true
                }
            }
        } label: {
            shareButtonLabel
        }
        .buttonStyle(.plain)
    }

    var shareButtonLabel: some View {
        HStack(spacing: 10) {
            WSSImage.icShare.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.wssWhite)
                .frame(width: 24, height: 24)

            Text("공유하기")
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssWhite)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(Color.wssPrimary100)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    /// 나만 보는 컬렉션은 소유자만 볼 수 있어 항상 소유자 시점에서만 그려진다(사용자 확정 근거:
    /// `CollectionDomain/CLAUDE.md` — 목록 API가 본인 목록에만 비공개 컬렉션을 내려준다).
    var privateBadge: some View {
        HStack(spacing: 9) {
            WSSImage.icLock.swiftUIImage
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.wssGray200)
                .frame(width: 20, height: 20)

            Text("나만 보는 컬렉션")
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssGray200)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(Color.wssGray80)
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.wssGray200)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

// MARK: - Content

private extension CollectionDetailView {
    func contentSection(_ detail: CollectionDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 10)

            HStack(spacing: 0) {
                Text("\(detail.novelCount)개")
                    .applyWSSFont(.body3)
                    .foregroundStyle(Color.wssGray200)

                Spacer()

                WSSSortButton(sortType: viewModel.state.sortType) {
                    viewModel.handle(.changeSortType(viewModel.state.sortType == .recent ? .old : .recent))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 33)

            Spacer().frame(height: 8)

            novelGrid(detail.novels)
                .padding(.horizontal, 16)
            
            Spacer().frame(height: 60)
        }
    }

    func novelGrid(_ novels: [CollectionNovel]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
            spacing: 16
        ) {
            ForEach(novels, id: \.id) { novel in
                novelCell(novel)
            }
        }
    }

    /// 표지(독립 크기) + 정보 영역(제목 최대 2줄 + 작가, 고정 높이).
    func novelCell(_ novel: CollectionNovel) -> some View {
        Button {
            onNovelTapped(novel.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                WSSNovelCoverImage(url: novel.thumbnailImage, aspectRatio: novelCoverAspectRatio)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer().frame(height: 6)

                novelCellInfo(novel)
            }
        }
        .buttonStyle(.plain)
    }

    /// "제목(최대 2줄)+간격(2)+작가" 정보 영역 — 이 스택에만 고정 높이(`novelInfoHeight`)를 줘서
    /// 그리드 행 전체 높이(≈216)를 통일한다. `WSSComponent.WSSNovelGridCell.Metric.infoHeight`와
    /// 같은 원리로, **표지는 이 프레임 밖에 있어 영향을 받지 않는다** — 표지까지 같은
    /// `.frame(height:)`로 묶으면 제목이 2줄일 때 표지 렌더 폭이 열 너비보다 좁아지는 버그가
    /// 재현된다(`CollectionFeature/CLAUDE.md` 참고, 과거 실측으로 확인·폐기된 패턴).
    /// 제목-작가 간격은 `Spacer(2)`로 고정이라 제목 줄 수와 무관하게 항상 2pt다(2026-08-25 확정
    /// 사항 보존). 제목이 1줄이라 남는 공간은 `alignment: .top` + 끝의 `Spacer(minLength: 0)` 덕에
    /// 항상 작가 아래(카드 하단)로 흐른다.
    func novelCellInfo(_ novel: CollectionNovel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(novel.title)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 2)

            Text(novel.author)
                .applyWSSFont(.label2)
                .foregroundStyle(Color.wssGray200)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(height: novelInfoHeight, alignment: .top)
    }

    /// Figma 그리드 커버 비율(108×160에 근접) — `CreateCollectionView`의 새 셀들과 일부러 다른 비율을
    /// 쓰지 않고 같은 108/156을 재사용해 두 화면의 커버 형태가 어긋나지 않게 한다.
    var novelCoverAspectRatio: CGFloat { 108.0 / 156.0 }

    /// 정보 영역(제목 2줄+간격 2+작가 1줄) 고정 높이 — 표지(aspectRatio 독립)와 별개로 이 값만
    /// 고정해 카드 전체 높이를 셀마다 통일한다(Figma 기준 카드 전체 ≈216에 맞춘 값, 표지+간격(6)을
    /// 뺀 나머지). 실측치가 Figma와 어긋나면 이 상수만 조정하면 된다.
    var novelInfoHeight: CGFloat { 54 }
}

// MARK: - Menu

private extension CollectionDetailView {
    var menuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { viewModel.handle(.dismissMenu) }

            WSSDropdownMenu(items: [
                WSSDropdownItem(title: "컬렉션 수정") {
                    viewModel.handle(.editTapped)
                    onEditTapped()
                },
                WSSDropdownItem(title: "컬렉션 삭제") { viewModel.handle(.deleteTapped) }
            ])
            .frame(width: 122)
            .padding(.top, 120)
            .padding(.trailing, 25)
        }
    }
}

// MARK: - Scroll Offset

private let scrollCoordinateSpace = "CollectionDetailScroll"

// MARK: - Presentation

private extension CollectionDetailView {
    var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isDeleteAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissDeleteAlert) } }
        )
    }

    var actionErrorToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.hasActionError },
            set: { if !$0 { viewModel.handle(.dismissActionErrorToast) } }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionDetailView(
            viewModel: CollectionDetailViewModel(
                id: CollectionID(1),
                loadCollectionDetailUseCase: PreviewLoadCollectionDetailUseCase(),
                collectionLikeUseCase: PreviewCollectionLikeUseCase(),
                deleteCollectionUseCase: PreviewDeleteCollectionUseCase()
            ),
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
            onNovelTapped: { print("작품 상세 진입: \($0)") },
            onEditTapped: { print("컬렉션 수정 진입") }
        )
    }
}

private struct PreviewLoadCollectionDetailUseCase: LoadCollectionDetailUseCase {
    func execute(id: CollectionID, sortType: SortType) async throws(RepositoryError) -> CollectionDetail {
        CollectionDetail(
            id: id,
            name: "당신의 이해를 돕기 위하여 모음",
            description: "글을 한줄만 썼을 때는 요런 식.",
            owner: Author(nickname: "판소덕", profileImage: nil),
            isMine: true,
            isPrivate: false,
            representativeNovelID: NovelID(1),
            novels: (1...9).map { index in
                CollectionNovel(id: NovelID(index), title: "작품작품작품작품작작품작품작품작품작작품작품작품작품작 \(index)", author: "작가", thumbnailImage: URL(string: "https://i.pinimg.com/736x/be/10/85/be1085de2de865a00f5a9e74f4139439.jpg"))
            },
            likeCount: 100,
            isLiked: false
        )
    }
}

private struct PreviewCollectionLikeUseCase: CollectionLikeUseCase {
    func like(id: CollectionID) async throws(RepositoryError) {}
    func unlike(id: CollectionID) async throws(RepositoryError) {}
}

private struct PreviewDeleteCollectionUseCase: DeleteCollectionUseCase {
    func execute(id: CollectionID) async throws(RepositoryError) {}
}

