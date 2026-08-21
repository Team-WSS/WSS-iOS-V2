//
//  CollectionMyLibrarySelectView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import NovelDomain
import DesignSystem
import WSSComponent

/// "서재에서 추가" 화면 — 내 서재를 3열 그리드로 조회하며 다중 선택 후 "추가"로 확정한다.
/// `CollectionSearchNovelView`의 "서재에서 추가" 버튼으로 진입하는 로컬 push 화면(별도 Factory
/// 진입점 없음). 확정 시 `CollectionSearchNovelView`가 받은 그 콜백을 재사용해 `CreateCollectionView`
/// 까지 2단계 pop한다 — 배선은 `CollectionSearchNovelView.swift` 참고.
struct CollectionMyLibrarySelectView: View {

    @State private var viewModel: CollectionMyLibrarySelectViewModel
    @Environment(\.dismiss) private var dismiss

    private let onConfirm: ([CollectionNovel]) -> Void
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: CollectionMyLibrarySelectViewModel,
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
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: .unknownError)
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

    @ViewBuilder
    private var content: some View {
        if viewModel.state.loadFailed {
            NetworkErrorView { viewModel.handle(.retry) }
        } else if viewModel.state.isLoading {
            LoadingView()
        } else if viewModel.state.novels.isEmpty {
            WSSEmptyView(type: .novel, action: {})
        } else {
            novelGrid
        }
    }
}

// MARK: - Toolbar

private extension CollectionMyLibrarySelectView {

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
            Text("서재")
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                viewModel.handle(.confirm)
            } label: {
                Text("추가")
                    .applyWSSFont(.title2)
                    .foregroundStyle(viewModel.state.selectedNovels.isEmpty ? Color.wssGray100 : Color.wssPrimary100)
            }
            .disabled(viewModel.state.selectedNovels.isEmpty)
        }
    }
}

// MARK: - Sections

private extension CollectionMyLibrarySelectView {

    var novelGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                spacing: 18
            ) {
                ForEach(viewModel.state.novels, id: \.id) { novel in
                    let isSelected = viewModel.selectedNovelIDs.contains(novel.id)

                    WSSLibraryGridCell(
                        thumbnailImage: novel.thumbnailImage,
                        title: novel.title,
                        readingStatus: novel.userReview?.readingStatus,
                        myRating: novel.userReview?.rating?.value,
                        dateText: novel.userReview?.period?.displayText,
                        isInterested: novel.isInterested,
                        isSelected: isSelected
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.handle(.toggleNovel(novel))
                    }
                    // 이미지+onTapGesture 조합은 접근성 트리에 안 잡힌다(VoiceOver·UI 자동화 모두) —
                    // `WSSComponent/CLAUDE.md` 공통 주의. 탭 대상임을 명시.
                    .accessibilityLabel(novel.title)
                    .accessibilityAddTraits(.isButton)
                    // 무한스크롤 — 마지막 셀이 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                    .onAppear {
                        if novel.id == viewModel.state.novels.last?.id {
                            viewModel.handle(.loadMore)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            if viewModel.state.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 16)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Presentation

private extension CollectionMyLibrarySelectView {

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
        CollectionMyLibrarySelectView(
            viewModel: CollectionMyLibrarySelectViewModel(
                initialSelection: [],
                loadMyLibraryUseCase: PreviewLoadMyLibraryUseCase()
            ),
            onConfirm: { novels in print("서재 선택 확정: \(novels.count)개") },
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

private struct PreviewLoadMyLibraryUseCase: LoadMyLibraryUseCase {
    func execute(filter: MyLibraryFilter, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        let novels = (1...9).map { index in
            LibraryNovel(
                id: NovelID(index),
                title: "미리보기 작품 \(index)",
                thumbnailImage: nil,
                rating: 4.0,
                isInterested: index.isMultiple(of: 3),
                userReview: nil,
                writtenFeeds: []
            )
        }
        return (CursorPaginated(items: novels, hasNext: false, nextCursor: nil), novels.count)
    }
}
