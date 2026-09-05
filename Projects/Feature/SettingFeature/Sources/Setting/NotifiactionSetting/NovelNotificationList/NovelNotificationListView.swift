//
//  NovelNotificationListView.swift
//  SettingFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import DesignSystem
import WSSComponent

/// 완결 알림/휴재 복귀 알림 목록 화면 — 화면 구조가 완전히 같아(#188, 사용자 확정) 제목만 바꿔 재사용한다.
struct NovelNotificationListView: View {

    @State private var viewModel: NovelNotificationListViewModel
    @Environment(\.dismiss) private var dismiss

    private let title: String
    /// 목록이 비었을 때 "작품 둘러보기" CTA — 어디로 보낼지(검색 화면 등)는 다른 Feature 모듈이라
    /// 이 화면이 알지 못한다. 호출자(App)가 결정한다.
    private let onBrowseNovels: () -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 로드·다음 페이지·삭제가 401로 막히면 발화(Feature 공통 계약).
    private let onAuthenticationRequired: () -> Void

    init(
        title: String,
        viewModel: NovelNotificationListViewModel,
        onBrowseNovels: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) {
        self.title = title
        self._viewModel = State(initialValue: viewModel)
        self.onBrowseNovels = onBrowseNovels
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        // 로딩/실패/빈 상태를 if/else 트리 교체가 아니라 overlay로 둔다. 상태 전환 시에도 루트(content)
        // 정체성이 유지돼야, 로드 완료 순간과 뒤로가기(dismiss)가 겹쳐도 진행 중인 pop이 취소되지 않는다
        // (NovelReviewView와 동일한 이유).
        VStack(spacing: 0) {
            WSSNavigationBar(title: title) {
                viewModel.handle(.requestClose)
            } trailing: {
                if !viewModel.state.subscriptions.isEmpty {
                    Button {
                        if viewModel.state.isEditing {
                            viewModel.handle(.presentDeleteConfirmation)
                        } else {
                            viewModel.handle(.beginEditing)
                        }
                    } label: {
                        if viewModel.state.isDeleting {
                            ProgressView()
                        } else {
                            Text(viewModel.state.isEditing ? "삭제" : "수정")
                                .applyWSSFont(.title2)
                                .foregroundStyle(trailingButtonColor)
                        }
                    }
                    .disabled(viewModel.state.isDeleting || (viewModel.state.isEditing && viewModel.state.selectedNovelIDs.isEmpty))
                }
            }

            content
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                } else if let error = viewModel.state.loadError {
                    NetworkErrorView(error: error) {
                        viewModel.handle(.load)
                    }
                } else if viewModel.state.subscriptions.isEmpty {
                    if viewModel.state.hasNextPage {
                        // 현재 페이지를 통째로 삭제해 일시적으로 빈 상태 — VM이 다음 페이지를 자동 로드 중이다.
                        LoadingView()
                    } else {
                        WSSEmptyView(type: .novelNotification, action: onBrowseNovels)
                    }
                }
            }
            }
            .wssCustomNavigationBar()
            .onAppear {
                viewModel.handle(.load)
            }
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss { dismiss() }
            }
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
            }
            .showWSSAlert(
                isPresented: deleteConfirmationBinding,
                type: .deleteNovelNotificationSubscriptions(summary: deleteSummaryText),
                buttonActions: [
                    { viewModel.handle(.dismissDeleteConfirmation) },
                    { viewModel.handle(.confirmDelete) }
                ]
            )
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    /// 항상 마운트된 상태로 두고(구독이 비어도 `ForEach`는 그냥 아무것도 안 그린다) 로딩/실패/빈 상태는
    /// `body`의 overlay가 위에서 가린다 — 루트 정체성을 유지하기 위함(위 body 주석 참고).
    private var content: some View {
        listSection
    }
}

// MARK: - Sections

private extension NovelNotificationListView {
    var listSection: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(viewModel.state.subscriptions, id: \.id) { subscription in
                    NovelNotificationRow(
                        subscription: subscription,
                        isEditing: viewModel.state.isEditing,
                        isSelected: viewModel.state.selectedNovelIDs.contains(subscription.novelID),
                        onToggleSelection: { viewModel.handle(.toggleSelection(subscription.novelID)) }
                    )
                    // 무한스크롤 — 마지막 행이 화면에 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                    .onAppear {
                        if subscription.id == viewModel.state.subscriptions.last?.id {
                            viewModel.handle(.loadMore)
                        }
                    }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Presentation

private extension NovelNotificationListView {
    /// "수정"(비편집)은 gray300, "삭제"(편집 중)는 선택 여부로 gray200(비활성)/primary100(활성) — 사용자 확정 색상.
    var trailingButtonColor: Color {
        guard viewModel.state.isEditing else { return WSSColor.wssGray300.swiftUIColor }
        return viewModel.state.selectedNovelIDs.isEmpty
            ? WSSColor.wssGray200.swiftUIColor
            : WSSColor.wssPrimary100.swiftUIColor
    }

    var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedDeleteConfirmation },
            set: { if !$0 { viewModel.handle(.dismissDeleteConfirmation) } }
        )
    }

    /// "{첫 선택 작품 제목} 외 N작품" — 목록에 보이는 순서 기준으로 첫 선택 항목을 고른다.
    var deleteSummaryText: String {
        let selected = viewModel.state.subscriptions.filter { viewModel.state.selectedNovelIDs.contains($0.novelID) }
        guard let first = selected.first else { return "" }
        return selected.count == 1 ? first.novelTitle : "\(first.novelTitle) 외 \(selected.count - 1)작품"
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.toastError != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.toastError {
        case .unknown, .none: .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelNotificationListView(
            title: "완결 알림",
            viewModel: NovelNotificationListViewModel(
                type: .completion,
                loadSubscriptionsUseCase: PreviewLoadNovelNotificationSubscriptionsUseCase(),
                deleteSubscriptionsUseCase: PreviewDeleteNovelNotificationSubscriptionsUseCase()
            ),
            onBrowseNovels: { print("작품 둘러보기") }
        )
    }
}

private struct PreviewLoadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase {
    func execute(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        let subscriptions = (1...5).map { index in
            NovelNotificationSubscription(
                id: SubscriptionID(index),
                novelID: NovelID(index),
                novelTitle: "미리보기 작품 \(index)",
                novelThumbnailImage: nil,
                novelAuthor: "프리뷰 작가",
                registeredDateText: "2026.08.\(10 + index)"
            )
        }
        return PagedNovelNotificationSubscriptions(subscriptions: subscriptions, isLoadable: false, nextSubscriptionID: nil)
    }
}

private struct PreviewDeleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase {
    func execute(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError) {}
}
