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
/// 닉네임 필드 UI는 `WSSComponent`의 `WSSNicknameField` 공용 컴포넌트를 쓴다 — `MyPageEditView`의 닉네임
/// 섹션(#147)과 필드 정책이 같아야 해서(#178에서 승격), 캡션 문구(한글 카피)만 온보딩 톤으로 갈린다.
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
                if let nickname {
                    onConfirmed(nickname)
                    viewModel.handle(.consumeConfirmation)
                }
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

    /// `MyPageEditView.nicknameSection`과 같은 `WSSNicknameField` 공용 컴포넌트를 쓴다(#178에서 승격) —
    /// 섹션 타이틀·글자수 카운터만 온보딩엔 없다.
    var nicknameSection: some View {
        WSSNicknameField(
            text: nicknameTextBinding,
            isFocused: $isKeyboardFocused,
            maxLength: NicknameDraft.maxLength,
            isError: isNicknameError,
            isSuccess: viewModel.state.draft.validationState == .available,
            caption: nicknameValidationCaption.map { WSSNicknameField.Caption(text: $0.text, color: $0.color) },
            isDuplicationCheckEnabled: isDuplicationCheckEnabled,
            isCheckingDuplication: viewModel.state.isCheckingDuplication,
            onCheckDuplication: { viewModel.handle(.checkDuplication) }
        )
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
    /// 서버 중복확인 결과뿐 아니라 **입력 중 실시간 형식 검증(공백·패턴)도 포함** — `NicknameDraft.validationState`가
    /// 순수 계산 프로퍼티라 타이핑마다 즉시 갱신되고, 그 값을 그대로 반영해 `WSSNicknameField`의 실패 아이콘도
    /// 같은 프레임에 바뀐다(중복확인 버튼을 누르지 않아도 됨).
    var isNicknameError: Bool {
        switch viewModel.state.draft.validationState {
        case .notAvailable(.whiteSpaceIncluded), .notAvailable(.invalidCharacterOrLimitExceeded), .notAvailable(.duplicated):
            return true
        default:
            return false
        }
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
