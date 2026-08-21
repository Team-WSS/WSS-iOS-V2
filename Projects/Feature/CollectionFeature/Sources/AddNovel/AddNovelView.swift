//
//  AddNovelView.swift
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
// 전체를 교체한다. CreateCollectionView 내부에서만 push되는 로컬 화면(별도 Factory 진입점 없음).
struct AddNovelView: View {

    @State private var viewModel: AddNovelViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchBarFocused: Bool

    /// 확정 콜백 — 최종 선택 결과 전체를 상위(`CreateCollectionView`)로 발화한다. 콜백은 VM이 아니라
    /// View가 소유한다(프로젝트 관례).
    private let onConfirm: ([CollectionNovel]) -> Void
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: AddNovelViewModel,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onConfirm = onConfirm
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .showWSSToast(isPresented: toastBinding, type: .unknownError)
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

private extension AddNovelView {

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

private extension AddNovelView {

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

            // TODO: 서재에서 작품을 골라 추가하는 흐름은 이번 범위 밖(#199 후속) — 문구만 배치.
            Button {
            } label: {
                Text("서재에서 추가")
                    .underline()
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssGray200)
            }
        }
    }

    @ViewBuilder
    var resultArea: some View {
        if viewModel.state.isSearching {
            LoadingView()
        } else if viewModel.state.searchedNovels.isEmpty {
            if !viewModel.state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                WSSEmptyView(type: .novel, action: {})
            } else {
                Spacer()
            }
        } else {
            resultList
        }
    }

    var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.state.searchedNovels, id: \.id) { novel in
                    novelRow(novel)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
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

            Text(isSelected ? "× 삭제" : "+ 추가")
                .applyWSSFont(.body5)
                .foregroundStyle(isSelected ? Color.wssSecondary100 : Color.wssWhite)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(isSelected ? Color.wssSecondary20 : Color.wssPrimary100)
                .clipShape(Capsule())
                // 미설정 시 기본 크로스페이드가 느리게 번진다(Feature/CLAUDE.md 공통 주의).
                .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.handle(.toggleNovel(novel))
        }
    }
}

// MARK: - Presentation

private extension AddNovelView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddNovelView(
            viewModel: AddNovelViewModel(
                initialSelection: [],
                searchNovelUseCase: PreviewSearchNovelUseCase()
            ),
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
