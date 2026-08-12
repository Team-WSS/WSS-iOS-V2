//
//  GenderBirthYearView.swift
//  OnboardingFeature
//
//  Created by Guryss on 8/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import ProfileDomain
import DesignSystem
import WSSComponent

/// 온보딩 2단계(콘텐츠만) — 성별/출생년도 입력. 공통 헤더(뒤로가기)·진행바는 컨테이너
/// `OnboardingStepFlowView`가 소유·렌더링한다 — 이 화면은 입력 필드+하단 CTA만 담당한다.
/// 입력 필드 구성(성별 칩·출생년도 피커)은 `SettingFeature`의 성별/나이 변경 화면과 같은 내용을
/// 재사용했다(Figma 없이, 디자인 갭 체크 결과).
struct GenderBirthYearView: View {

    @State private var viewModel: GenderBirthYearViewModel
    @State private var showBirthYearPickerSheet = false

    /// "다음으로" 확정 시 발화 — 다음 온보딩 단계(장르 선택)로 진행할지는 호출자(컨테이너)가 결정한다.
    private let onConfirmed: (Gender, BirthYear) -> Void

    init(
        viewModel: GenderBirthYearViewModel,
        onConfirmed: @escaping (Gender, BirthYear) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onConfirmed = onConfirmed
    }

    var body: some View {
        content
            .sheet(isPresented: $showBirthYearPickerSheet) {
                birthYearPickerSheet
            }
            .onChange(of: viewModel.state.confirmedSelection) { _, selection in
                if let selection { onConfirmed(selection.gender, selection.birthYear) }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                Spacer().frame(height: 50)
                genderSection
                Spacer().frame(height: 40)
                birthYearSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }
}

// MARK: - Sections

private extension GenderBirthYearView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("성별, 출생연도를 선택하세요")
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 8)

            Text("해당 정보는 추천에 활용되며, 언제든 변경할 수 있어요")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
        }
    }

    var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("성별")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 10)

            HStack(spacing: 13) {
                RectangleSelectableKeywordChip(
                    keyword: "남성",
                    isSelected: viewModel.state.gender == .male,
                    action: { viewModel.handle(.selectGender(.male)) }
                )

                RectangleSelectableKeywordChip(
                    keyword: "여성",
                    isSelected: viewModel.state.gender == .female,
                    action: { viewModel.handle(.selectGender(.female)) }
                )
            }
        }
    }

    var birthYearSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("출생연도")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 6)

            Button {
                showBirthYearPickerSheet.toggle()
            } label: {
                HStack(spacing: 0) {
                    if let birthYear = viewModel.state.birthYear {
                        Text(String(birthYear.value))
                            .applyWSSFont(.body2)
                            .foregroundStyle(Color.wssBlack)
                    } else {
                        Text("태어난 해를 입력하세요")
                            .applyWSSFont(.body2)
                            .foregroundStyle(Color.wssGray200)
                    }

                    Spacer()

                    WSSImage.icNavigateDown.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.wssGray300)
                        .frame(width: 16, height: 16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.wssGray50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 43)
            }
            .buttonStyle(.plain)
        }
    }

    var ctaButton: some View {
        WSSCTAButton(
            title: "다음으로",
            isEnabled: viewModel.state.gender != nil && viewModel.state.birthYear != nil
        ) {
            viewModel.handle(.proceed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Presentation

private extension GenderBirthYearView {
    /// 시트 안에서만 스크롤로 바뀌고, "완료"를 눌러야 부모 `state.birthYear`에 반영되는 커밋-온-확인 패턴
    /// (`SettingChangeBirthYearPickerSheet`와 동일한 관례 — Feature 모듈 간 재사용은 안 되어 로컬로 다시 둠).
    /// 값이 아직 없으면(첫 진입) 피커는 **2000년을 시작 위치로만** 보여준다 — "완료"를 눌러야 비로소
    /// `state.birthYear`가 채워진다(시작 위치를 보여줬다고 곧바로 선택된 것으로 치지 않는다).
    var birthYearPickerSheet: some View {
        BirthYearPickerSheet(
            selectedYear: Binding(
                get: { viewModel.state.birthYear?.value ?? 2000 },
                set: { viewModel.handle(.selectBirthYear($0)) }
            )
        )
    }
}

// MARK: - 출생년도 피커 시트

private struct BirthYearPickerSheet: View {
    @Binding var selectedYear: Int
    @State private var draftYear: Int
    @Environment(\.dismiss) private var dismiss

    init(selectedYear: Binding<Int>) {
        self._selectedYear = selectedYear
        self._draftYear = State(initialValue: selectedYear.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("출생연도")
                    .applyWSSFont(.title1)
                    .foregroundStyle(Color.wssBlack)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    WSSImage.icCancelModal.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(Color.wssGray300)
                        .frame(width: 65, height: 65)
                }
            }
            .padding(.leading, 25)

            WSSBirthYearWheel(year: $draftYear, minYear: BirthYear.minYear, maxYear: BirthYear.maxYear)

            Spacer().frame(height: 20)

            WSSCTAButton(title: "완료") {
                selectedYear = draftYear
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .presentationDetents([.height(300)])
        .presentationBackground(Color.wssWhite)
        .interactiveDismissDisabled()
    }
}

// MARK: - Preview

#Preview {
    GenderBirthYearView(
        viewModel: GenderBirthYearViewModel(),
        onConfirmed: { gender, birthYear in
            print("성별/출생년도 확정: \(gender), \(birthYear.value)")
        }
    )
}
