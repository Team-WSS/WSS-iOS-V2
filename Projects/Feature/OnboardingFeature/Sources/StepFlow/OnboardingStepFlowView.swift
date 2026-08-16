//
//  OnboardingStepFlowView.swift
//  OnboardingFeature
//
//  Created by Guryss on 8/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent
import Logger

/// 온보딩 나머지 3단계(닉네임→성별/출생년도→장르선택)를 **한 화면 안에서** 진행하는 컨테이너.
/// 진행바(+헤더 자리)를 여기서 한 번만 그려 단계 전환 내내 같은 인스턴스로 유지한다 — 그래야
/// `OnboardingStepProgressBar`가 `currentStep` 변화에 실제로 애니메이션 반응한다(각 단계가 별도
/// `NavigationStack` 목적지였던 이전 구조에서는 화면마다 진행바가 다시 생성돼 "이어서 채워지는" 느낌을
/// 흉내내야 했다 — 사용자 피드백으로 이 구조로 통합).
///
/// **뒤로가기는 `NavigationStack` pop이 아니라 `currentStep`을 되돌리는 것**이다. 그래서:
/// - 닉네임/성별·출생년도 ViewModel은 **컨테이너가 소유하고 재사용**한다(단계 전환 시 재생성 ❌) —
///   안 그러면 뒤로 갔다 오는 사이 입력값(닉네임 텍스트, 중복확인 상태 등)이 날아간다.
/// - 장르 선택 ViewModel만 예외 — `nickname`/`gender`/`birthYear`가 앞 두 단계 완료 전엔 존재하지 않아
///   미리 만들 수 없다. 성별/출생년도 확정 시점에 한 번 만들고, 그 이후 재확정(뒤로 갔다 다시 확정)마다
///   다시 만든다(그 시점의 선택값 반영이 우선이라 이전 장르 선택은 초기화됨 — 허용 가능한 트레이드오프).
/// - `.enableSwipeBack()`은 **의도적으로 걸지 않는다** — 이 화면 전체는 여전히 하나의 강제 시퀀스라
///   스와이프 제스처가 "한 단계 뒤로"가 아니라 "전체 이탈"이 되면 안 된다. 단계 내 뒤로가기는 반드시
///   화면 안의 뒤로가기 버튼으로만.
///
/// **뒤로가기/건너뛰기 행(`headerRow`)은 진행바보다 위, 화면 맨 위에 온다**(사용자 결정) — 그래서 이
/// 행도 각 단계 View가 아니라 컨테이너가 그린다(단, 장르 선택 화면만 있는 "건너뛰기"도 컨테이너가
/// `genreSelectionViewModel.handle(.skip)`으로 직접 호출). 각 단계 View(`NicknameView` 등)는
/// 이제 자기 헤더를 그리지 않는 순수 콘텐츠(입력 필드 + 하단 CTA)만 담당한다.
///
/// **콘텐츠 전환은 `switch`로 갈아치우지 않고 슬라이드 애니메이션으로 한다** — 세 단계를 `HStack`에
/// 나란히 두고 `offset`을 단계 수만큼 밀어 보여주는 방식(자세한 이유는 `slidingStepContent` 참고).
///
/// **장르 선택(3단계) 등록이 성공하면 진행바·헤더가 있는 위 구조 전체를 "계약 완료" 화면
/// (`OnboardingCompleteView`, #178)으로 교체한다** — 그 화면은 진행바·뒤로가기가 없는 완전히 다른
/// 레이아웃이라 슬라이드 단계에 4번째 슬롯으로 끼워 넣지 않고 `isRegistrationCompleted` 플래그로
/// `body` 최상위를 통째로 분기한다. 이 화면의 CTA를 눌러야 비로소 컨테이너의 진짜 `onCompleted`
/// (Home 진입은 App 책임)가 발화한다 — `GenreSelectionView`의 등록 성공은 더 이상 `onCompleted`를
/// 곧장 호출하지 않는다.
struct OnboardingStepFlowView: View {

    @State private var viewModel = OnboardingStepFlowViewModel()
    @State private var nicknameViewModel: NicknameViewModel
    @State private var genderBirthYearViewModel = GenderBirthYearViewModel()
    @State private var genreSelectionViewModel: GenreSelectionViewModel?
    /// 장르 선택(마지막 단계)의 프로필 등록이 성공하면 세운다 — 진행바·뒤로가기가 없는 "계약 완료"
    /// 화면(`OnboardingCompleteView`, #178)으로 컨테이너 콘텐츠 전체를 교체하는 순수 표시 플래그.
    @State private var isRegistrationCompleted = false

    private let registerProfileUseCase: RegisterProfileUseCase
    private let logger: Logger?
    private let onAuthenticationRequired: () -> Void
    /// 프로필 등록 성공 시 발화 — 온보딩 종료 후 어디로 갈지(Home 등)는 호출자(App)가 결정한다.
    private let onCompleted: () -> Void

    init(
        validateNicknameUseCase: ValidateNicknameUseCase,
        registerProfileUseCase: RegisterProfileUseCase,
        logger: Logger?,
        onAuthenticationRequired: @escaping () -> Void,
        onCompleted: @escaping () -> Void
    ) {
        self._nicknameViewModel = State(
            initialValue: NicknameViewModel(validateNicknameUseCase: validateNicknameUseCase, logger: logger)
        )
        self.registerProfileUseCase = registerProfileUseCase
        self.logger = logger
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onCompleted = onCompleted
    }

    var body: some View {
        Group {
            if isRegistrationCompleted {
                OnboardingCompleteView(nickname: viewModel.state.nickname, onStart: onCompleted)
            } else {
                VStack(spacing: 0) {
                    headerRow
                    Spacer().frame(height: 5)
                    OnboardingStepProgressBar(currentStep: viewModel.state.currentStep.rawValue)

                    slidingStepContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header (뒤로가기 + 건너뛰기, 단계 공통 — 진행바보다 위)

private extension OnboardingStepFlowView {
    /// 뒤로가기는 1단계(닉네임)에서 숨긴다(첫 단계라 되돌아갈 곳이 없다). "건너뛰기"는 마지막 단계
    /// (장르 선택)에서만 뜨고, 그 단계의 VM(`genreSelectionViewModel`)을 컨테이너가 직접 들고 있으니
    /// `.skip` 액션을 곧장 호출한다 — 자식 화면에 별도 콜백을 안 뚫어도 된다.
    var headerRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 6)

            if viewModel.state.currentStep != .nickname {
                Button {
                    viewModel.handle(.goBack)
                } label: {
                    WSSImage.icNavigateLeft.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.wssBlack)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .padding(.leading, 6)
            }

            Spacer()

            if viewModel.state.currentStep == .genreSelection {
                Button {
                    genreSelectionViewModel?.handle(.skip)
                } label: {
                    Text("건너뛰기")
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssGray300)
                }
                .padding(10)

                Spacer().frame(width: 12)
            }
        }
        .frame(height: 44)
        .background(Color.wssWhite)
    }
}

// MARK: - Step Content (슬라이드 전환)

private extension OnboardingStepFlowView {
    /// 세 단계 화면을 전부 동시에 살려 가로로 나란히 두고(`HStack`), 현재 단계만큼 `offset`으로 밀어
    /// 보여준다 — 그래서 단계 전환이 `switch`로 콘텐츠를 갈아치우는 컷 전환이 아니라 실제 슬라이드
    /// 애니메이션이 된다. 부수 효과로 세 ViewModel이 전부 항상 살아있어(장르 선택도 값이 확정된
    /// 뒤로는 마찬가지) 앞뒤로 오가도 입력값이 그대로 보존된다.
    /// ⚠️ `.clipped()` 필수 — 없으면 화면 밖으로 밀려난 다른 단계의 콘텐츠가 레이아웃상 계속
    /// 존재해(그냥 안 보일 뿐) 스크린 리더·히트테스트에 영향을 줄 수 있다.
    var slidingStepContent: some View {
        GeometryReader { geometry in
            let size = geometry.size

            HStack(spacing: 0) {
                NicknameView(
                    viewModel: nicknameViewModel,
                    onAuthenticationRequired: onAuthenticationRequired,
                    onConfirmed: { viewModel.handle(.nicknameConfirmed($0)) }
                )
                .frame(width: size.width, height: size.height)

                GenderBirthYearView(
                    viewModel: genderBirthYearViewModel,
                    onConfirmed: handleGenderBirthYearConfirmed
                )
                .frame(width: size.width, height: size.height)

                genreSelectionSlot
                    .frame(width: size.width, height: size.height)
            }
            .frame(width: size.width * 3, height: size.height, alignment: .leading)
            .offset(x: -CGFloat(viewModel.state.currentStep.rawValue - 1) * size.width)
            .animation(.easeInOut, value: viewModel.state.currentStep)
        }
        .clipped()
    }

    /// 성별/출생년도가 아직 확정 전이면(장르 선택 슬롯에 아직 못 들어가 있는 동안) 빈 자리만 차지한다 —
    /// 어차피 `offset`상 그 자리까지 밀려야 보이는데, 그 시점엔 이미 `genreSelectionViewModel`이
    /// 존재한다(`handleGenderBirthYearConfirmed`가 단계 전환과 같은 탭 핸들러에서 함께 만들기 때문).
    ///
    /// 등록 성공(`onCompleted` 원래 콜백) 시 곧장 호출자에게 넘기지 않고 `isRegistrationCompleted`부터
    /// 세운다 — "계약 완료" 화면(`OnboardingCompleteView`)을 먼저 보여주고, 그 화면의 "웹소소 시작하기"
    /// 버튼이 눌렸을 때 비로소 진짜 `onCompleted`(Home 진입은 App 책임)를 발화한다.
    @ViewBuilder
    var genreSelectionSlot: some View {
        if let genreSelectionViewModel {
            GenreSelectionView(
                viewModel: genreSelectionViewModel,
                onAuthenticationRequired: onAuthenticationRequired,
                onCompleted: { isRegistrationCompleted = true }
            )
        } else {
            Color.clear
        }
    }

    /// 성별/출생년도 확정 시점에만 `GenreSelectionViewModel`을 만들 수 있다(그 전엔 값이 없다) —
    /// 단계 전환(`viewModel.handle`)과 같은 탭 핸들러 안에서 함께 처리해, 다음 렌더 패스에 두 상태가
    /// 항상 같이 반영되도록 한다(`currentStep == .genreSelection`인데 `genreSelectionViewModel`이
    /// 아직 nil인 프레임이 생기지 않게).
    func handleGenderBirthYearConfirmed(_ gender: Gender, _ birthYear: BirthYear) {
        viewModel.handle(.genderBirthYearConfirmed(gender, birthYear))
        genreSelectionViewModel = GenreSelectionViewModel(
            nickname: viewModel.state.nickname,
            gender: gender,
            birthYear: birthYear,
            registerProfileUseCase: registerProfileUseCase,
            logger: logger
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingStepFlowView(
        validateNicknameUseCase: PreviewValidateNicknameUseCase(),
        registerProfileUseCase: PreviewRegisterProfileUseCase(),
        logger: nil,
        onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
        onCompleted: { print("온보딩 완료 → Home") }
    )
}

private struct PreviewValidateNicknameUseCase: ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool { true }
}

private struct PreviewRegisterProfileUseCase: RegisterProfileUseCase {
    func execute(_ profile: ProfileRegistration) async throws(RepositoryError) {}
}
