//
//  NovelNotificationSettingSheet.swift
//  NovelDetailFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import DesignSystem
import WSSComponent

/// 작품 상세 종 모양 아이콘 시트 — 완결/휴재 복귀 알림을 각각 켜고 끈다. UseCase 없는 순수 입력 화면들과
/// 달리 서버 호출이 있어 로드+낙관 토글 패턴을 쓰지만, 화면이 작아 전체화면 실패 뷰 대신 토스트로만
/// 실패를 알린다(닫고 다시 열면 재시도).
struct NovelNotificationSettingSheet: View {

    @State private var viewModel: NovelNotificationSettingSheetViewModel

    init(viewModel: NovelNotificationSettingSheetViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .onAppear {
                viewModel.handle(.load)
            }
            .presentationDetents([.height(178)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(WSSColor.wssWhite.swiftUIColor)
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            LoadingView()
                .frame(height: 178)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                toggleRow(
                    title: "완결 알림",
                    description: "작품이 완결 나면 알림을 드려요",
                    isOn: completionBinding
                )
                toggleRow(
                    title: "휴재 복귀 알림",
                    description: "새로운 회차가 생기면 알림을 드려요",
                    isOn: hiatusReturnBinding
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private func toggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssBlack)

                Text(description)
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
            }

            Spacer()

            WSSToggleButton(isOn: isOn)
        }
        .frame(height: 59)
    }
}

// MARK: - Presentation

private extension NovelNotificationSettingSheet {
    var completionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isCompletionNotificationEnabled },
            set: { viewModel.handle(.toggleCompletionNotification($0)) }
        )
    }

    var hiatusReturnBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isHiatusReturnNotificationEnabled },
            set: { viewModel.handle(.toggleHiatusReturnNotification($0)) }
        )
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
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NovelNotificationSettingSheet(
                viewModel: NovelNotificationSettingSheetViewModel(
                    novelID: NovelID(1),
                    loadNotificationSettingUseCase: PreviewLoadNovelNotificationSettingUseCase(),
                    updateNotificationSettingUseCase: PreviewUpdateNovelNotificationSettingUseCase()
                )
            )
        }
}

private struct PreviewLoadNovelNotificationSettingUseCase: LoadNovelNotificationSettingUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        NovelNotificationSetting(isCompletionNotificationEnabled: true, isHiatusReturnNotificationEnabled: false)
    }
}

private struct PreviewUpdateNovelNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase {
    func execute(novelID: NovelID, setting: NovelNotificationSetting) async throws(RepositoryError) {}
}
