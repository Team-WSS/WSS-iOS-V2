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
import SearchDomain
import NovelDomain
import Logger
import DesignSystem
import WSSComponent

/// 컬렉션 목록 화면 — "내 컬렉션"/"좋아요한 컬렉션"을 세그먼트 탭으로 전환하며 본다. 마이페이지
/// "컬렉션 N개" 행에서 진입한다(`CollectionFeatureFactory.makeCollectionListView`가 유일한 진입점).
/// 화면 동작 계약은 `CollectionFeature/CLAUDE.md` 참고.
struct CollectionListView: View {

    @State private var viewModel: CollectionListViewModel
    /// "컬렉션 만들기" push 여부 — `CreateCollectionView`는 이 화면이 자기 내부에서만 push하는
    /// 로컬 화면이라(`CreateCollectionView`가 "작품 추가"를 push하는 것과 동일 위상) 이 화면이 직접 소유.
    @State private var isCreatePresented = false
    /// 탭한 카드의 컬렉션 ID — 진입 파라미터가 있는 push라 `isPresented:` + 별도 State 조합 대신
    /// `.navigationDestination(item:)`을 쓴다(`Feature/CLAUDE.md` 공통 함정 — 첫 진입에서만 파라미터가
    /// 무시되는 문제 예방).
    @State private var selectedCollectionID: CollectionID?
    @Environment(\.dismiss) private var dismiss

    /// "컬렉션 만들기" 화면이 필요로 하는 UseCase 3종 — `CreateCollectionView`로 그대로 관통시킨다.
    private let createCollectionUseCase: CreateCollectionUseCase
    private let searchNovelUseCase: SearchNovelUseCase
    private let loadMyLibraryUseCase: LoadMyLibraryUseCase
    /// 카드 탭 → `CollectionDetailView`(로컬 push)가 필요로 하는 UseCase 4종(수정 포함).
    private let loadCollectionDetailUseCase: LoadCollectionDetailUseCase
    private let collectionLikeUseCase: CollectionLikeUseCase
    private let deleteCollectionUseCase: DeleteCollectionUseCase
    private let updateCollectionUseCase: UpdateCollectionUseCase
    private let logger: Logger?
    private let onAuthenticationRequired: () -> Void
    /// `CollectionDetailView`의 작품 그리드 셀 탭 콜백 — 그대로 관통만 시킨다(`CollectionFeatureFactory`
    /// 참고, App이 아직 실제로 연결하지 않았다).
    private let onNovelTapped: (NovelID) -> Void

    init(
        viewModel: CollectionListViewModel,
        createCollectionUseCase: CreateCollectionUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        collectionLikeUseCase: CollectionLikeUseCase,
        deleteCollectionUseCase: DeleteCollectionUseCase,
        updateCollectionUseCase: UpdateCollectionUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void,
        onNovelTapped: @escaping (NovelID) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.createCollectionUseCase = createCollectionUseCase
        self.searchNovelUseCase = searchNovelUseCase
        self.loadMyLibraryUseCase = loadMyLibraryUseCase
        self.loadCollectionDetailUseCase = loadCollectionDetailUseCase
        self.collectionLikeUseCase = collectionLikeUseCase
        self.deleteCollectionUseCase = deleteCollectionUseCase
        self.updateCollectionUseCase = updateCollectionUseCase
        self.logger = logger
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onNovelTapped = onNovelTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            CollectionSegmentedTab(
                selectedTab: viewModel.state.selectedTab,
                onSelect: { viewModel.handle(.selectTab($0)) }
            )
            content
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear { viewModel.handle(.load) }
        .showWSSToast(isPresented: toastBinding, type: .unknownError)
        .navigationDestination(isPresented: $isCreatePresented) {
            CollectionFeatureFactory.makeCreateCollectionView(
                createCollectionUseCase: createCollectionUseCase,
                searchNovelUseCase: searchNovelUseCase,
                loadMyLibraryUseCase: loadMyLibraryUseCase,
                logger: logger,
                onAuthenticationRequired: onAuthenticationRequired
            )
        }
        .onChange(of: isCreatePresented) { wasPresented, isPresented in
            // 성공 콜백이 없는 CreateCollectionView 계약이라, 복귀했다는 사실만으로 무조건 재로드한다
            // (취소해도 한 번 더 불리는 낭비는 있지만 최소 diff — `CollectionFeature/CLAUDE.md` 참고).
            guard wasPresented, !isPresented else { return }
            viewModel.handle(.reloadMineAfterCreate)
        }
        .navigationDestination(item: $selectedCollectionID) { id in
            CollectionFeatureFactory.makeCollectionDetailView(
                id: id,
                loadCollectionDetailUseCase: loadCollectionDetailUseCase,
                collectionLikeUseCase: collectionLikeUseCase,
                deleteCollectionUseCase: deleteCollectionUseCase,
                updateCollectionUseCase: updateCollectionUseCase,
                searchNovelUseCase: searchNovelUseCase,
                loadMyLibraryUseCase: loadMyLibraryUseCase,
                logger: logger,
                onAuthenticationRequired: onAuthenticationRequired,
                onNovelTapped: onNovelTapped
            )
        }
        .onChange(of: selectedCollectionID) { oldValue, newValue in
            // 상세 화면에서 좋아요·삭제로 카드가 바뀌었을 수 있어, 복귀했다는 사실만으로 그 탭을
            // 무조건 다시 로드한다(`isCreatePresented`와 동일 판단).
            guard oldValue != nil, newValue == nil else { return }
            viewModel.handle(.reloadAfterDetail(viewModel.state.selectedTab))
        }
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
                if tab == .mine {
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
            isCreatePresented = true
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
            selectedCollectionID = card.id
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
            ZStack {
                WSSEmptyView(type: .collectionMine)
                
                VStack(spacing: 0) {
                    createCollectionButton
                        .padding(16)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            createCollectionUseCase: PreviewCreateCollectionUseCase(),
            searchNovelUseCase: PreviewSearchNovelUseCase(),
            loadMyLibraryUseCase: PreviewLoadMyLibraryUseCase(),
            loadCollectionDetailUseCase: PreviewLoadCollectionDetailUseCase(),
            collectionLikeUseCase: PreviewCollectionLikeUseCase(),
            deleteCollectionUseCase: PreviewDeleteCollectionUseCase(),
            updateCollectionUseCase: PreviewUpdateCollectionUseCase(),
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
            onNovelTapped: { print("작품 상세 진입: \($0)") }
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

private struct PreviewCreateCollectionUseCase: CreateCollectionUseCase {
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID { CollectionID(1) }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }

    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
}

private struct PreviewLoadMyLibraryUseCase: LoadMyLibraryUseCase {
    func execute(filter: MyLibraryFilter, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        (CursorPaginated(items: [], hasNext: false, nextCursor: nil), size)
    }
}

private struct PreviewLoadCollectionDetailUseCase: LoadCollectionDetailUseCase {
    func execute(id: CollectionID, sortType: SortType) async throws(RepositoryError) -> CollectionDetail {
        CollectionDetail(
            id: id,
            name: "미리보기 컬렉션",
            description: nil,
            owner: Author(nickname: "판소덕", profileImage: nil),
            isMine: true,
            isPrivate: false,
            representativeNovelID: NovelID(1),
            novels: [CollectionNovel(id: NovelID(1), title: "작품 1", author: "작가", thumbnailImage: nil)],
            likeCount: 0,
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

private struct PreviewUpdateCollectionUseCase: UpdateCollectionUseCase {
    func execute(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError) {}
}
