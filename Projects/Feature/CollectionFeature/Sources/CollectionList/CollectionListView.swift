//
//  CollectionListView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

/// 컬렉션 목록 화면 — "내 컬렉션"/"좋아요한 컬렉션"을 세그먼트 탭으로 전환하며 본다. 마이페이지
/// "컬렉션 N개" 행에서 진입한다(`CollectionFeatureFactory.makeCollectionListView`가 유일한 진입점).
/// 화면 동작 계약은 `CollectionFeature/CLAUDE.md` 참고.
struct CollectionListView: View {

    @State private var viewModel: CollectionListViewModel
    /// 이 화면의 자식은 "컬렉션 만들기"·`CollectionDetailView`(둘 다 App이 push)뿐이라, 두 번째
    /// 이후의 `onAppear`는 항상 "그중 하나에서 복귀"를 뜻한다 — 그때만 무조건 재로드한다
    /// (`CollectionDetailView`의 `hasAppearedOnce`와 동일 이유, App이 소유한 `NavigationPath`로
    /// 옮기며 로컬 `isCreatePresented`/`selectedCollectionID`·`onChange` 대신 이 방식으로 바뀌었다).
    @State private var hasAppearedOnce = false
    @Environment(\.dismiss) private var dismiss

    private let onAuthenticationRequired: () -> Void
    /// "컬렉션 만들기" 버튼 탭 콜백. 실제 화면 전환(`CollectionFeatureFactory.makeCreateCollectionView`
    /// 조립)은 호출자(App 조정 계층)가 수행한다. `isOwnCollections == false`면 버튼 자체가 안 뜨므로
    /// 호출될 일이 없다.
    private let onCreateTapped: () -> Void
    /// 카드 탭 → 컬렉션 상세 진입 콜백. 실제 화면 전환(`CollectionFeatureFactory.makeCollectionDetailView`
    /// 조립)은 호출자(App 조정 계층)가 수행한다.
    private let onCollectionSelected: (CollectionID) -> Void
    /// `false`면 남의 컬렉션을 보는 자리다(타유저 프로필의 "컬렉션" 헤더 탭, #201 후속) — 세그먼트
    /// 탭("좋아요한 컬렉션"이 세션 토큰=로그인 사용자 자신 기준이라 재사용 불가, `CollectionFeature/CLAUDE.md`
    /// 참고)과 "컬렉션 만들기"를 숨기고 "내 컬렉션" 탭 콘텐츠만 보여준다. `viewModel.state.selectedTab`은
    /// 세그먼트 탭이 없으면 전환할 방법이 없어 기본값 `.mine`에 항상 머문다 — ViewModel 쪽 변경 불필요.
    private let isOwnCollections: Bool

    init(
        viewModel: CollectionListViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onCreateTapped: @escaping () -> Void,
        onCollectionSelected: @escaping (CollectionID) -> Void,
        isOwnCollections: Bool = true
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onCreateTapped = onCreateTapped
        self.onCollectionSelected = onCollectionSelected
        self.isOwnCollections = isOwnCollections
    }

    var body: some View {
        VStack(spacing: 0) {
            if isOwnCollections {
                CollectionSegmentedTab(
                    selectedTab: viewModel.state.selectedTab,
                    onSelect: { viewModel.handle(.selectTab($0)) }
                )
            }
            content
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            // 이 화면의 자식(컬렉션 만들기/상세) 중 하나에서 복귀한 뒤의 재진입만 무조건 재로드한다 —
            // 성공/취소를 구분하지 않는다(취소해도 한 번 더 불리는 낭비는 있지만 최소 diff,
            // `CollectionFeature/CLAUDE.md` 참고).
            if hasAppearedOnce {
                viewModel.handle(.reloadAfterReturn(viewModel.state.selectedTab))
            } else {
                hasAppearedOnce = true
                viewModel.handle(.load)
            }
        }
        .showWSSToast(isPresented: toastBinding, type: .unknownError)
        // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
        .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
            if needsAuth { onAuthenticationRequired() }
        }
    }

    // ⚠️ 두 탭을 각각의 스크롤 뷰로 **동시에 마운트해두고, 보이는 쪽만 opacity로 바꾼다** — 하나의
    // 스크롤 뷰 안에서 탭에 따라 콘텐츠만 갈아끼우면 SwiftUI가 그 스크롤 뷰의 정체성을 유지해
    // contentOffset이 두 탭에 공유된다(실측: 좋아요한 컬렉션에서 스크롤해 두고 내 컬렉션으로 돌아오면
    // 이미 스크롤된 채로 보임). `LibraryFeature`의 그리드↔리스트 토글과 동일 함정·동일 해법.
    @ViewBuilder
    private var content: some View {
        ZStack {
            ForEach(CollectionListTab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .opacity(tab == viewModel.state.selectedTab ? 1 : 0)
                    .allowsHitTesting(tab == viewModel.state.selectedTab)
                    .accessibilityHidden(tab != viewModel.state.selectedTab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: CollectionListTab) -> some View {
        let tabState = state(for: tab)
        if tabState.loadFailed {
            NetworkErrorView { viewModel.handle(.retry(tab)) }
        } else if tabState.isLoading {
            LoadingView()
        } else if tabState.items.isEmpty {
            emptySection(for: tab)
        } else {
            collectionList(tab, tabState)
        }
    }

    private func state(for tab: CollectionListTab) -> CollectionListViewModel.TabContent {
        switch tab {
        case .mine: viewModel.state.mine
        case .liked: viewModel.state.liked
        }
    }
}

// MARK: - Toolbar

private extension CollectionListView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssBlack)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("컬렉션")
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
        }
    }
}

// MARK: - Sections

private extension CollectionListView {

    func collectionList(_ tab: CollectionListTab, _ tabContent: CollectionListViewModel.TabContent) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if tab == .mine, isOwnCollections {
                    createCollectionButton
                    Spacer().frame(height: 16)
                }

                LazyVStack(spacing: 16) {
                    ForEach(tabContent.items, id: \.id) { card in
                        collectionCard(card)
                            .onAppear {
                                if card.id == tabContent.items.last?.id {
                                    viewModel.handle(.loadMore(tab))
                                }
                            }
                    }
                }

                if tabContent.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 16)
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    var createCollectionButton: some View {
        Button {
            onCreateTapped()
        } label: {
            HStack(spacing: 10) {
                Text("컬렉션 만들기")
                    .applyWSSFont(.body4, color: .wssPrimary100)
                WSSImage.icPlusMyPage.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.wssGray20)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.wssPrimary50)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        // `.buttonStyle(.plain)`을 걸지 않는다 — 아이콘+텍스트만 있는 버튼에 걸면 기본 눌림
        // 피드백까지 사라진다(색이 이미 명시적이라 accent 틴트 우려가 없음, 같은 모듈
        // `CreateCollectionView.swift`의 동일 판단 참고).
    }

    func collectionCard(_ card: CollectionCard) -> some View {
        Button {
            onCollectionSelected(card.id)
        } label: {
            collectionCardContent(card)
        }
        .buttonStyle(.plain)
    }

    func collectionCardContent(_ card: CollectionCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(card.name)
                        .applyWSSFont(.title2, color: .wssGray300)
                        .lineLimit(1)

                    Spacer()

                    WSSImage.icNavigateRight.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssGray300)
                        .frame(width: 24, height: 24)
                }

                cardSubtitle(card)
            }

            CollectionCoverStackView(recentNovels: card.recentNovels)

            if card.isPrivate {
                privateTag
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 16)
        .background(Color.wssPrimary20)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
    }

    func cardSubtitle(_ card: CollectionCard) -> some View {
        HStack(spacing: 0) {
            if let description = card.description {
                Text(description)
                    .applyWSSFont(.label2, color: .wssGray300)
                    .lineLimit(1)
                
                Spacer().frame(width: 4)
                
                Circle()
                    .fill(Color.wssGray300)
                    .frame(width: 2, height: 2)
                
                Spacer().frame(width: 4)
            }

            HStack(spacing: 0) {
                Text("작품 ")
                    .applyWSSFont(.label2, color: .wssGray300)
                Text("\(card.novelCount)")
                    .applyWSSFont(.label2, color: .wssPrimary100)
            }
            
            Spacer().frame(width: 80)
        }
    }

    var privateTag: some View {
        HStack(spacing: 6) {
            WSSImage.icLock.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

            Text("나만 보는 컬렉션")
                .applyWSSFont(.label2, color: .wssGray200)
        }
    }

    // "내 컬렉션"/"좋아요한 컬렉션"의 빈 상태는 확정 정도가 달라 분기 자체가 다르다 — 아래 각 케이스
    // 주석 참고. 나중에 두 탭이 같은 모양으로 확정되어도 이 분기를 성급히 합치지 말 것(사용자 확정,
    // 2026-08-25).
    @ViewBuilder
    func emptySection(for tab: CollectionListTab) -> some View {
        switch tab {
        case .mine:
            if isOwnCollections {
                ZStack {
                    WSSEmptyView(type: .collectionMine)

                    VStack(spacing: 0) {
                        createCollectionButton
                            .padding(16)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                // 타유저의 컬렉션이 0개인 채로 이 화면에 온 경우(정상 경로는 헤더 탭에서 미리 걸러진다,
                // `UserPageFeature`의 노 컬렉션 토스트 참고) — "컬렉션 만들기"는 로그인 사용자 자신의
                // 컬렉션에만 의미가 있어 남의 페이지에서는 보여주지 않는다.
                WSSEmptyView(type: .collectionMine)
            }
        case .liked:
            WSSEmptyView(type: .collectionLike)
        }
    }
}

// MARK: - Presentation

private extension CollectionListView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionListView(
            viewModel: CollectionListViewModel(
                userID: UserID(10041),
                loadCollectionsUseCase: PreviewLoadCollectionsUseCase(),
                loadLikedCollectionsUseCase: PreviewLoadLikedCollectionsUseCase()
            ),
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
            onCreateTapped: { print("컬렉션 만들기 진입") },
            onCollectionSelected: { print("컬렉션 상세 진입: \($0)") }
        )
    }
}

private func previewCards(namePrefix: String) -> [CollectionCard] {
    (1...3).map { index in
        CollectionCard(
            id: CollectionID(index),
            name: "\(namePrefix) \(index)",
            description: "존잼 수준이 정도를 넘음",
            novelCount: index * 2,
            isPrivate: index.isMultiple(of: 2),
            recentNovels: (1...index).map { novelIndex in
                CollectionNovel(id: NovelID(index * 10 + novelIndex), title: "작품 \(novelIndex)", author: "작가", thumbnailImage: nil)
            }
        )
    }
}

private struct PreviewLoadCollectionsUseCase: LoadCollectionsUseCase {
    func execute(userID: UserID, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        let cards = previewCards(namePrefix: "내 컬렉션")
        return (CursorPaginated(items: cards, hasNext: false, nextCursor: nil), cards.count)
    }
}

private struct PreviewLoadLikedCollectionsUseCase: LoadLikedCollectionsUseCase {
    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        let cards = previewCards(namePrefix: "좋아요한 컬렉션")
        return (CursorPaginated(items: cards, hasNext: false, nextCursor: nil), cards.count)
    }
}

