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
import DesignSystem
import WSSComponent

// 컬렉션 "작품 추가" 화면 — 검색해서 다중선택한 결과를 확정하면 CreateCollectionView의 작품 리스트
// 전체를 교체한다. `CollectionFeatureFactory.makeSearchNovelView`로 App이 조립·push한다.
struct CollectionSearchNovelView: View {

    @State private var viewModel: CollectionSearchNovelViewModel
    @FocusState private var isSearchBarFocused: Bool
    /// "서재에서 추가"를 거쳐 돌아오면 `onAppear`가 재발화한다 — 화면 진입 트래킹은 최초 1회만
    /// (`CreateCollectionView.hasTrackedWriteViewed`와 동일 이유).
    @State private var hasTrackedAddNovelViewed = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    /// 확정 콜백 — 최종 선택 결과 전체를 발화한다(호출자가 `CreateCollectionView`까지 pop하며
    /// 반영한다). 콜백은 VM이 아니라 View가 소유한다(프로젝트 관례).
    private let onConfirm: ([CollectionNovel]) -> Void
    /// 화면 전환 의도 콜백(#253) — 계약은 `CollectionSearchNovelRoute`(Navigation/)가 정본.
    /// `.myLibrarySelect`는 현재까지 선택된 목록을 실어 올리고, 실제 화면 전환
    /// (`CollectionFeatureFactory.makeMyLibrarySelectView` 조립)은 호출자(App 조정 계층)가 수행한다.
    private let onRoute: (CollectionSearchNovelRoute) -> Void
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: CollectionSearchNovelViewModel,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onRoute: @escaping (CollectionSearchNovelRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onConfirm = onConfirm
        self.onRoute = onRoute
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "작품 리스트") {
                dismiss()
            } trailing: {
                Button {
                    viewModel.handle(.confirm)
                } label: {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(Color.wssPrimary100)
                }
            }

            content
        }
        .wssCustomNavigationBar()
        .showWSSToast(isPresented: toastBinding, type: toastType)
            .onAppear {
                isSearchBarFocused = true
                if !hasTrackedAddNovelViewed {
                    hasTrackedAddNovelViewed = true
                    viewModel.track(.addNovelViewed)
                }
            }
            .onChange(of: viewModel.state.isConfirmed) { _, confirmed in
                guard confirmed else { return }
                // 이 화면 자신은 dismiss()하지 않는다 — 호출자(App)가 `onConfirm`을 받아 이 화면까지
                // pop한다.
                onConfirm(viewModel.state.selectedNovels)
            }
            // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // 네비게이션 바와 검색바 사이 간격
            Spacer().frame(height: 8)

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
                onRoute(.myLibrarySelect(viewModel.state.selectedNovels))
            } label: {
                Text("서재에서 추가")
                    .underline()
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssGray200)
            }
        }
    }

    /// `hasSearched`가 꺼져 있으면(=검색 실행 전, 또는 결과를 받은 뒤 다시 타이핑하는 도중) 검색 결과
    /// 대신 지금까지 고른 작품(`selectedNovels`) 리스트를 보여준다 — 초기 진입·검색어를 지운 상태에서
    /// 이미 추가한 작품을 확인·삭제할 수 있게(사용자 요청). 아무것도 안 골랐으면 빈 화면이다.
    /// `searchedNovels`(이전 검색 결과)로 판단하지 않는 이유는 아래 `selectedNovelList` 주석 참고 —
    /// 타이핑 도중 직전 결과가 잘못 남는 걸 막으려고 `hasSearched`가 켜져야만 검색 리스트/결과없음을 가른다.
    @ViewBuilder
    var resultArea: some View {
        if viewModel.state.isSearching {
            LoadingView()
        } else if !viewModel.state.hasSearched {
            if viewModel.state.selectedNovels.isEmpty {
                Spacer()
            } else {
                selectedNovelList
            }
        } else if viewModel.state.searchedNovels.isEmpty {
            WSSEmptyView(type: .novel, action: {
                if let url = AppURL.inquiryAddNovel { openURL(url) }
            })
        } else {
            resultList
        }
    }

    /// 검색 전 화면의 "추가한 작품" 리스트. 이미 고른 작품(`CollectionNovel`)만 담겨 전부 삭제(`.remove`)
    /// 배지이고, 탭하면 선택에서 빠진다 — 검색 결과와 달리 무한스크롤이 없다(최대 100개, `maxNovelCount`).
    var selectedNovelList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.state.selectedNovels, id: \.id) { novel in
                    selectedNovelRow(novel)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        // `resultList`와 동일 — ScrollView가 빈 공간 터치를 가져가므로 키보드 내리기 제스처를 직접 건다.
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchBarFocused = false
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

    /// 추가/삭제는 필 배지 자신만 탭 영역이다(#255 QA — 행 전체를 누르면 실수로 토글되기 쉽다는
    /// 지적으로, 행 전체 탭에서 배지 단독 탭으로 좁혔다). 표지·제목·작가 영역은 더 이상 탭을 받지
    /// 않는다.
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

            WSSPillBadge(style: isSelected ? .remove : .add) {
                viewModel.handle(.toggleNovel(novel))
            }
        }
    }

    /// "추가한 작품" 리스트 행. `selectedNovels`는 `[CollectionNovel]`이라 `novelRow(Novel)`을 못 써
    /// 별도 행을 둔다(작가는 단일 `author` 문자열). 배지는 항상 `.remove`(삭제) — 탭하면 선택 해제.
    func selectedNovelRow(_ novel: CollectionNovel) -> some View {
        HStack(spacing: 16) {
            WSSNovelCoverImage(url: novel.thumbnailImage)
                .frame(width: 73, height: 98)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(novel.title)
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssBlack)
                    .lineLimit(1)

                // 서재에서 추가한 작품은 `author`가 빈 문자열이다(`LibraryNovel`에 작가 필드가 없어
                // `CollectionMyLibrarySelectViewModel`이 ""로 채움) — 그 경우 작가 줄을 통째로 생략한다.
                // 검색·서버(수정 모드 로드)로 담은 작품은 작가가 있어 정상 표시된다.
                if !novel.author.isEmpty {
                    Text(novel.author)
                        .applyWSSFont(.body5)
                        .foregroundStyle(Color.wssGray200)
                        .lineLimit(1)
                }
            }

            Spacer()

            WSSPillBadge(style: .remove) {
                viewModel.handle(.removeSelectedNovel(novel))
            }
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
            onConfirm: { novels in print("확정: \(novels.count)개") },
            onRoute: { print("화면 전환 요청: \($0)") },
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(
        _ query: String,
        page: Int,
        recordRecentSearch: Bool
    ) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
}
