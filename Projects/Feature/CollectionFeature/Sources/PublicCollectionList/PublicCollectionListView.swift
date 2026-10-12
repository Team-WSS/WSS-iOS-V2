//
//  PublicCollectionListView.swift
//  CollectionFeature
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

/// 전체 컬렉션뷰("컬렉션 모음.zip") — 모든 사용자의 공개 컬렉션. 홈 컬렉션 섹션 제목 탭에서 진입한다(#283).
/// 화면 동작 계약은 `CollectionFeature/CLAUDE.md` 참고.
struct PublicCollectionListView: View {

    @State private var viewModel: PublicCollectionListViewModel
    @Environment(\.dismiss) private var dismiss

    private let onAuthenticationRequired: () -> Void
    /// 화면 전환 의도 콜백 — 계약은 `PublicCollectionListRoute`(Navigation/)가 정본.
    private let onRoute: (PublicCollectionListRoute) -> Void

    private enum Metric {
        static let listPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let coverSlotCount = 5
    }

    init(
        viewModel: PublicCollectionListViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onRoute: @escaping (PublicCollectionListRoute) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onRoute = onRoute
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "컬렉션 모음.zip") { dismiss() }

            content
        }
        .background(Color.wssWhite)
        .wssCustomNavigationBar()
        // 카드 탭으로 상세에 다녀와도 다시 부르지 않는다 — 이 목록에 상세에서 바뀔 값(좋아요 수 등)이 없다.
        .onAppear { viewModel.handle(.load) }
        // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
        .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
            if needsAuth { onAuthenticationRequired() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.state.loadFailed {
            NetworkErrorView(error: error) { viewModel.handle(.retry) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.state.isLoading {
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            collectionList
        }
    }
}

// MARK: - Sections

private extension PublicCollectionListView {

    var collectionList: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(spacing: Metric.cardSpacing) {
                    ForEach(viewModel.state.items, id: \.id) { card in
                        collectionCard(card)
                            .onAppear {
                                if card.id == viewModel.state.items.last?.id {
                                    viewModel.handle(.loadMore)
                                }
                            }
                    }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 16)
                }
            }
            .padding(Metric.listPadding)
        }
        .refreshable {
            HapticManager.impact(.light)
            viewModel.handle(.refresh)
            // `handle`은 동기 반환이라 그대로 두면 인디케이터가 즉시 사라진다 — 진행 중 로드의 종료를 기다린다.
            await viewModel.awaitLoad()
        }
        .scrollIndicators(.hidden)
    }

    func collectionCard(_ card: PublicCollectionCard) -> some View {
        Button {
            onRoute(.collectionDetail(card.id))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                CollectionCardHeader(name: card.name, description: card.description, novelCount: card.novelCount)

                Spacer().frame(height: 16)

                WSSCollectionCoverStack(
                    coverURLs: card.recentNovels.map(\.thumbnailImage),
                    slotCount: Metric.coverSlotCount
                )

                Spacer().frame(height: 8)

                WSSCollectionOwnerLabel(nickname: card.owner.nickname, profileImage: card.owner.profileImage)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 16)
            .background(Color.wssPrimary20)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PublicCollectionListView(
            viewModel: PublicCollectionListViewModel(
                loadPublicCollectionsUseCase: PreviewLoadPublicCollectionsUseCase()
            ),
            onAuthenticationRequired: {},
            onRoute: { print("화면 전환 요청: \($0)") }
        )
    }
}

private struct PreviewLoadPublicCollectionsUseCase: LoadPublicCollectionsUseCase {
    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> CursorPaginated<PublicCollectionCard> {
        let cards = (0..<5).map { index in
            PublicCollectionCard(
                id: CollectionID(index),
                name: "일이삼사오육칠팔구십일이삼사오육칠팔구십",
                description: "존잼 수준이 정도를 넘음",
                novelCount: index + 1,
                recentNovels: [],
                owner: Author(userId: UserID(index), nickname: "코띠", profileImage: nil)
            )
        }
        return CursorPaginated(items: cards, hasNext: false, nextCursor: nil)
    }
}
