//
//  SettingChangeGenderOrAgeView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent

struct SettingChangeGenderOrAgeView: View {

    @State private var viewModel: SettingChangeGenderOrAgeViewModel
    @State private var showBirthYearPickerSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    private let onSaveSuccess: () -> Void

    init(
        viewModel: SettingChangeGenderOrAgeViewModel,
         onSaveSuccess: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
    }

    var body: some View {
        content
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.handle(.load)
            }
            .sheet(isPresented: $showBirthYearPickerSheet) {
                SettingChangeBirthYearPickerSheet(selectedYear: birthYearBinding)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                guard shouldDismiss else { return }
                onSaveSuccess()
                dismiss()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            genderSection

            Spacer().frame(height: 30)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)

            Spacer().frame(height: 15)

            ageSection

            Spacer()
        }
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("성별")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 10)

            HStack(spacing: 13) {
                RectangleSelectableKeywordChip(
                    keyword: "남성",
                    isSelected: viewModel.state.draft.gender == .male,
                    action: { viewModel.handle(.selectGender(.male)) }
                )

                RectangleSelectableKeywordChip(
                    keyword: "여성",
                    isSelected: viewModel.state.draft.gender == .female,
                    action: { viewModel.handle(.selectGender(.female)) }
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("출생연도")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 6)

            Button {
                showBirthYearPickerSheet.toggle()
            } label: {
                HStack(spacing: 0) {
                    Text(String(viewModel.state.draft.birth.value))
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                    Spacer()

                    WSSImage.icNavigateDown.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                        .frame(width: 16, height: 16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(WSSColor.wssGray50.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 43)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Toolbar

private extension SettingChangeGenderOrAgeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("성별/나이 변경")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.handle(.save)
            } label: {
                if viewModel.state.isSaving {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(
                            viewModel.hasChanges
                                ? WSSColor.wssPrimary100.swiftUIColor
                                : WSSColor.wssGray100.swiftUIColor
                        )
                }
            }
            .disabled(viewModel.state.isSaving || !viewModel.hasChanges)
        }
    }
}

// MARK: - Presentation

private extension SettingChangeGenderOrAgeView {
    var birthYearBinding: Binding<Int> {
        Binding(
            get: { viewModel.state.draft.birth.value },
            set: { viewModel.handle(.selectBirthYear($0)) }
        )
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .unknown, .none: .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingChangeGenderOrAgeView(
            viewModel: SettingChangeGenderOrAgeViewModel(
                loadLocalGenderAndBirthUseCase: PreviewLoadLocalGenderAndBirthUseCase(),
                saveAccountInfoDraftUseCase: PreviewSaveAccountInfoDraftUseCase()
            )
        )
    }
}

private struct PreviewLoadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(2001))
    }
}

private struct PreviewSaveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase {
    func execute(_ info: AccountInfoDraft) async throws(RepositoryError) {}
}
