//
//  CollectionSearchNovelView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import SearchDomain
import NovelDomain
import DesignSystem
import WSSComponent
import Logger

// 컬렉션 "작품 추가" 화면 — 검색해서 다중선택한 결과를 확정하면 CreateCollectionView의 작품 리스트
// 전체를 교체한다. CreateCollectionView 내부에서만 push되는 로컬 화면(별도 Factory 진입점 없음).
struct CollectionSearchNovelView: View {

    @State private var viewModel: CollectionSearchNovelViewModel
    /// "서재에서 추가" 화면 push 여부 — `isAddNovelPresented`(CreateCollectionView)와 같은 위상으로
    /// 이 화면이 직접 소유한다. 확정 시 이 화면 자신을 dismiss해 CreateCollectionView까지 2단계
    /// pop한다(아래 `.navigationDestination`/`.onChange(of: isMyLibrarySelectPresented)` 참고).
    @State private var isMyLibrarySelectPresented = false
    /// "서재에서 추가"가 확정을 알려온 뒤, 자기 자신(`CollectionMyLibrarySelectView`)의 pop이 실제로
    /// 완료될 때까지(=`isMyLibrarySelectPresented`가 자연스레 false로 돌아올 때까지) 이 화면의
    /// `dismiss()`를 미뤄두는 플래그 — 실측 필요(아래 주석 참고).
    @State private var isPendingDismissAfterMyLibrarySelect = false
    @FocusState private var isSearchBarFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// "서재에서 추가" 화면이 서재 조회에 쓸 UseCase — `searchNovelUseCase`와 같은 위상으로 이 화면이
    /// 직접 받아 들고 있다가 자식 VM 생성에 쓴다.
    private let loadMyLibraryUseCase: LoadMyLibraryUseCase
    /// "서재에서 추가" 화면도 자기 VM에서 실패를 로깅해야 하므로, `CreateCollectionView`에게 받은 걸
    /// 그대로 들고 있다가 그 화면 생성 시 내려보낸다.
    private let logger: Logger?
    /// 확정 콜백 — 최종 선택 결과 전체를 상위(`CreateCollectionView`)로 발화한다. 콜백은 VM이 아니라
    /// View가 소유한다(프로젝트 관례). "서재에서 추가" 화면의 확정도 같은 콜백을 그대로 재사용한다.
    private let onConfirm: ([CollectionNovel]) -> Void
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: CollectionSearchNovelViewModel,
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        logger: Logger? = nil,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.loadMyLibraryUseCase = loadMyLibraryUseCase
        self.logger = logger
        self.onConfirm = onConfirm
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onAppear {
                isSearchBarFocused = true
            }
            .onChange(of: viewModel.state.isConfirmed) { _, confirmed in
                guard confirmed else { return }
                onConfirm(viewModel.state.selectedNovels)
                dismiss()
            }
            // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
            // "서재에서 추가" 확정 → CreateCollectionView가 넘긴 바로 그 onConfirm을 재사용해 최종
            // novels(검색+서재 병합본)를 전달한다. 이 화면 자신의 dismiss()는 여기서 곧바로 부르지
            // 않는다 — ⚠️ **실측 결과, 같은 프레임에서 자식(CollectionMyLibrarySelectView)의 자체
            // dismiss()와 이 화면의 dismiss()가 동시에 겹치면 이 화면은 pop되지 않고 자식만 pop된다**
            // (계층적 Bool이라 이론상 한 번의 dismiss()로 둘 다 사라져야 할 것 같지만 실제로는 아니었다
            // — 처음엔 그렇게 짰다가 시뮬레이터 실측에서 발견). 대신 자식이 **자기 자신의**
            // `.onChange(of: isConfirmed)`에서 스스로 dismiss()해 `isMyLibrarySelectPresented`가
            // 자연스럽게 false로 돌아오는 걸 아래 `.onChange`로 기다렸다가, 그 다음에야 이 화면도
            // dismiss()한다(계단식 2단계 pop). `CollectionFeature/CLAUDE.md` 참고.
            .navigationDestination(isPresented: $isMyLibrarySelectPresented) {
                CollectionMyLibrarySelectView(
                    viewModel: CollectionMyLibrarySelectViewModel(
                        initialSelection: viewModel.state.selectedNovels,
                        loadMyLibraryUseCase: loadMyLibraryUseCase,
                        logger: logger
                    ),
                    onConfirm: { novels in
                        onConfirm(novels)
                        isPendingDismissAfterMyLibrarySelect = true
                    },
                    onAuthenticationRequired: onAuthenticationRequired
                )
            }
            .onChange(of: isMyLibrarySelectPresented) { _, isPresented in
                guard !isPresented, isPendingDismissAfterMyLibrarySelect else { return }
                isPendingDismissAfterMyLibrarySelect = false
                dismiss()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)

            Spacer().frame(height: 16)

            selectionSummary
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            resultArea
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchBarFocused = false
        }
    }
}

// MARK: - Toolbar

private extension CollectionSearchNovelView {

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
            Text("작품 리스트")
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                viewModel.handle(.confirm)
            } label: {
                Text("완료")
                    .applyWSSFont(.title2)
                    .foregroundStyle(Color.wssPrimary100)
            }
        }
    }
}

// MARK: - Sections

private extension CollectionSearchNovelView {

    var searchBar: some View {
        WSSSearchBar(
            text: Binding(
                get: { viewModel.state.searchText },
                set: { viewModel.handle(.updateSearchText($0)) }
            ),
            placeholder: "작품 제목, 작가를 검색하세요",
            isFocused: $isSearchBarFocused,
            onSearch: { viewModel.handle(.search(viewModel.state.searchText)) }
        )
    }

    var selectionSummary: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                Text("추가한 작품")
                    .foregroundStyle(Color.wssGray200)
                Text("\(viewModel.state.selectedNovels.count)개")
                    .foregroundStyle(Color.wssPrimary100)
            }
            .applyWSSFont(.body4)

            Spacer()

            Button {
                isMyLibrarySelectPresented = true
            } label: {
                Text("서재에서 추가")
                    .underline()
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssGray200)
            }
        }
    }

    /// `hasSearched`가 꺼져 있으면(=검색 실행 전, 또는 결과를 받은 뒤 다시 타이핑하는 도중) 무조건
    /// 빈 화면이다 — `searchedNovels`는 이전 검색 결과를 그대로 들고 있을 수 있어서, 그 배열 자체로
    /// 판단하면 타이핑 중에 직전 검색 결과(또는 "결과 없음" 뷰)가 잘못 남아있는다(실제 발생 — 사용자
    /// 리포트: 타이핑 도중엔 아무것도 없이 흰 배경이어야 함). `search()`가 실제로 응답을 받아야만
    /// `hasSearched`가 켜지고, 그제서야 결과 유무에 따라 리스트/결과없음을 가른다.
    @ViewBuilder
    var resultArea: some View {
        if viewModel.state.isSearching {
            LoadingView()
        } else if !viewModel.state.hasSearched {
            Spacer()
        } else if viewModel.state.searchedNovels.isEmpty {
            WSSEmptyView(type: .novel, action: {})
        } else {
            resultList
        }
    }

    var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.state.searchedNovels, id: \.id) { novel in
                    novelRow(novel)
                        // 무한스크롤 — 마지막 행이 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                        // `LazyVStack`이 아니면 이 onAppear가 전체 행에 한꺼번에 발동하니 반드시 짝지어 유지할 것
                        // (`SearchFeature/CLAUDE.md` 참고).
                        .onAppear {
                            if novel.id == viewModel.state.searchedNovels.last?.id {
                                viewModel.handle(.loadMore)
                            }
                        }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        // 배경 탭으로 키보드를 내리는 제스처(`content`)는 `ScrollView` 내부의 빈 공간까지는 안 먹는다 —
        // `ScrollView`가 그 터치를 자기 것으로 가져가버린다(`SearchFeature/CLAUDE.md`의 자동완성 항목과
        // 동일 함정). 그래서 이 스크롤뷰 자신에도 같은 제스처를 직접 건다 — 행 위를 탭하면 `novelRow`의
        // `onTapGesture`(토글)가 먼저 소비하므로 서로 충돌하지 않는다.
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchBarFocused = false
        }
    }

    /// 행 전체가 탭 영역이다(`WSSNovelSelectRow`와 같은 이유 — 이 행의 유일한 액션이라 서브 액션과
    /// 컨테이너를 나눌 필요가 없다). 필 배지(추가/삭제)는 순수 표시용.
    func novelRow(_ novel: Novel) -> some View {
        let isSelected = viewModel.selectedNovelIDs.contains(novel.id)

        return HStack(spacing: 16) {
            WSSNovelCoverImage(url: novel.thumbnailImage)
                .frame(width: 73, height: 98)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(novel.title)
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssBlack)
                    .lineLimit(1)

                Text(novel.authors.joined(separator: ", "))
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
                    .lineLimit(1)
            }

            Spacer()

            WSSPillBadge(style: isSelected ? .remove : .add)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.handle(.toggleNovel(novel))
        }
    }
}

// MARK: - Presentation

private extension CollectionSearchNovelView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// `presentedError`가 `nil`일 때의 값은 쓰이지 않는다(`toastBinding`이 그때 `isPresented: false`).
    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .selectionLimitReached:
            .selectionOverLimit(count: CollectionDraft.maxNovelCount)
        case .unknown, .none:
            .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionSearchNovelView(
            viewModel: CollectionSearchNovelViewModel(
                initialSelection: [],
                searchNovelUseCase: PreviewSearchNovelUseCase()
            ),
            loadMyLibraryUseCase: PreviewLoadMyLibraryUseCase(),
            onConfirm: { novels in print("확정: \(novels.count)개") },
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
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
    func execute(filter: MyLibraryFilter, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        (CursorPaginated(items: [], hasNext: false, nextCursor: nil), 0)
    }
}
