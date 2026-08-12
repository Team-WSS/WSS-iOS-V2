//
//  NicknameView.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent

/// 온보딩 3단계(콘텐츠만) — 닉네임 입력. 공통 헤더·진행바는 컨테이너 `OnboardingStepFlowView`가
/// 소유·렌더링한다(이 화면은 뒤로가기 자체가 없다 — 첫 단계라 컨테이너가 뒤로가기 버튼을 숨긴다).
/// 닉네임 필드 자체의 정책·UI(캡션·테두리·중복확인 버튼 상태)는 `MyPageEditView`의 닉네임 섹션(#147)과 동일하게 맞춘다 —
/// 같은 `NicknameDraft`를 쓰는 두 화면이 서로 다른 표현을 하지 않도록(캡션 문구 자체는 온보딩 톤으로 갈림).
struct NicknameView: View {

    @State private var viewModel: NicknameViewModel
    @FocusState private var isKeyboardFocused: Bool

    /// 인증 만료(중복확인 호출 중 세션 죽음) 시 로그인 화면 진입 콜백.
    private let onAuthenticationRequired: () -> Void
    /// "다음으로" 확정 시 발화 — 다음 온보딩 단계(성별/출생년도)로 진행할지는 호출자(App)가 결정한다.
    private let onConfirmed: (String) -> Void

    init(
        viewModel: NicknameViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onConfirmed: @escaping (String) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onConfirmed = onConfirmed
    }

    var body: some View {
        content
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.confirmedNickname) { _, nickname in
                if let nickname { onConfirmed(nickname) }
            }
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                Spacer().frame(height: 61)
                nicknameSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .contentShape(Rectangle())
        .onTapGesture { isKeyboardFocused = false }
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }
}

// MARK: - Sections

private extension NicknameView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("닉네임을 입력하세요")
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 8)

            Text("10자 이내의 닉네임을 입력해주세요")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
        }
    }

    /// `MyPageEditView.nicknameSection`과 동일한 구성(필드+중복확인 버튼, 캡션+글자수 카운터) — 섹션 타이틀만 없다.
    var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                nicknameTextField
                duplicateCheckButton
            }

            Spacer().frame(height: 12)

            HStack(spacing: 0) {
                if let caption = nicknameValidationCaption {
                    Text(caption.text)
                        .applyWSSFont(.body4)
                        .foregroundStyle(caption.color)
                }

                Spacer()
            }
            .applyWSSFont(.body4)
        }
    }

    var nicknameTextField: some View {
        HStack(spacing: 0) {
            TextField("닉네임", text: nicknameTextBinding)
                .padding(.vertical, 10.5)
                .padding(.leading, 12)
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssBlack)
                .tint(Color.wssBlack)
                .focused($isKeyboardFocused)

            if !viewModel.state.draft.text.isEmpty {
                Button {
                    viewModel.handle(.updateText(""))
                } label: {
                    WSSImage.icCancel.swiftUIImage
                        .frame(width: 44, height: 44)
                }
            }
        }
        .background(Color.wssGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(nicknameBorderColor ?? .clear, lineWidth: 1)
        )
    }

    /// 실제로 서버 확인이 필요한 상태(`needDuplicatedCheck`)에서만 primary로 활성화된다.
    var duplicateCheckButton: some View {
        Button {
            viewModel.handle(.checkDuplication)
        } label: {
            Group {
                if viewModel.state.isCheckingDuplication {
                    ProgressView()
                } else {
                    Text("중복확인")
                        .applyWSSFont(.body2)
                        .foregroundStyle(isDuplicationCheckEnabled ? Color.wssPrimary100 : Color.wssGray200)
                }
            }
            .frame(width: 88, height: 44)
            .background(isDuplicationCheckEnabled ? Color.wssPrimary50 : Color.wssGray70)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isDuplicationCheckEnabled)
    }

    var ctaButton: some View {
        WSSCTAButton(
            title: "다음으로",
            isEnabled: viewModel.state.draft.validationState == .available
        ) {
            viewModel.handle(.proceed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Presentation

private extension NicknameView {
    var isDuplicationCheckEnabled: Bool {
        viewModel.state.draft.validationState == .needDuplicatedCheck
    }

    var nicknameTextBinding: Binding<String> {
        Binding(
            get: { viewModel.state.draft.text },
            set: { viewModel.handle(.updateText($0)) }
        )
    }

    /// 닉네임 검증 상태(의미값) → 캡션 문구/색(표현). `notStarted`·`needDuplicatedCheck`·`notChanged`는
    /// 사용자가 아직 조치할 게 없거나 조치가 필요없는 상태라 캡션을 띄우지 않는다.
    var nicknameValidationCaption: (text: String, color: Color)? {
        switch viewModel.state.draft.validationState {
        case .notStarted, .needDuplicatedCheck, .notAvailable(.notChanged):
            return nil
        case .notAvailable(.whiteSpaceIncluded):
            return ("공백은 포함될 수 없어요", Color.wssSecondary100)
        case .notAvailable(.invalidCharacterOrLimitExceeded):
            return ("한글, 영문, 숫자 2~10자까지 입력 가능해요", Color.wssSecondary100)
        case .notAvailable(.duplicated):
            return ("이미 사용 중인 닉네임이에요", Color.wssSecondary100)
        case .available:
            return ("사용 가능한 닉네임이에요", Color.wssPrimary100)
        }
    }

    /// 형식 오류·공백·중복 등 사용자가 고쳐야 하는 상태만 에러로 취급한다("변경 없음"은 에러가 아니다).
    var isNicknameError: Bool {
        switch viewModel.state.draft.validationState {
        case .notAvailable(.whiteSpaceIncluded), .notAvailable(.invalidCharacterOrLimitExceeded), .notAvailable(.duplicated):
            return true
        default:
            return false
        }
    }

    /// 닉네임 필드 테두리 색 — 에러=secondary100, 사용 가능=primary100, 그 외(입력 전·미변경·확인 대기)엔 테두리 없음.
    var nicknameBorderColor: Color? {
        if isNicknameError { return Color.wssSecondary100 }
        if viewModel.state.draft.validationState == .available { return Color.wssPrimary100 }
        return nil
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
    NicknameView(
        viewModel: NicknameViewModel(validateNicknameUseCase: PreviewValidateNicknameUseCase()),
        onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
        onConfirmed: { print("닉네임 확정: \($0)") }
    )
}

private struct PreviewValidateNicknameUseCase: ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool {
        true
    }
}
