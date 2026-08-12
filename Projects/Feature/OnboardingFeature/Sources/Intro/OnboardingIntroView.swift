//
//  OnboardingIntroView.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import AuthenticationServices
import SwiftUI

import KakaoSDKAuth
import KakaoSDKUser

import AuthDomain
import DesignSystem
import WSSComponent

/// 온보딩 플로우의 첫 화면 — 4장짜리 서비스 소개 배너(스와이프) + 소셜 로그인(Apple/Kakao).
/// 로그인 성공(`NeedOnboarding` 확정) 시점에 `onLoginSucceeded`를 발화하고 그 이후(가입약관 시트 등)는
/// 관여하지 않는다(후속 이슈 범위).
struct OnboardingIntroView: View {

    private static let bannerCount = 4
    /// 자동 전환 주기 — 사용자가 직접 스와이프하면 이 주기가 처음부터 다시 시작된다(`scheduleAutoAdvance`).
    private static let autoAdvanceInterval: TimeInterval = 2

    @State private var viewModel: OnboardingIntroViewModel
    /// TabView가 실제로 물고 있는 선택값 — 양 끝에 정본과 동일한 이미지를 복제해 붙인 "패딩된" 인덱스 공간
    /// (0=3번 복제, 1...4=진짜 0...3, 5=0번 복제)이라 스와이프가 0↔3 사이에서도 끊기지 않고 순환한다.
    @State private var selection = 1
    /// 다음 `.onChange(of: selection)` 호출 1회가 자동전환/복제-보정처럼 코드가 스스로 일으킨 변경임을 표시.
    /// 이게 false인 채로 selection이 바뀌면 "사용자가 직접 스와이프했다"는 뜻이라 자동전환 주기를 리셋한다.
    @State private var isProgrammaticSelectionChange = false
    @State private var autoAdvanceTask: Task<Void, Never>?
    /// 사용자가 보는 진짜 배너 인덱스(0...3) — 도트 인디케이터는 항상 이 값을 쓴다(패딩 인덱스 노출 금지).
    private var currentBanner: Int {
        switch selection {
        case 0: Self.bannerCount - 1
        case Self.bannerCount + 1: 0
        default: selection - 1
        }
    }
    /// SignInWithAppleButton 대신 커스텀 원형 버튼(Kakao와 동일한 형태)을 쓰기 위해 인증 흐름을 직접 구동한다.
    @State private var appleSignInHandler = AppleSignInHandler()

    private let onLoginSucceeded: (NeedOnboarding) -> Void

    init(
        viewModel: OnboardingIntroViewModel,
        onLoginSucceeded: @escaping (NeedOnboarding) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onLoginSucceeded = onLoginSucceeded
    }

    var body: some View {
        content
            .onAppear {
                appleSignInHandler.onCompletion = handleAppleLoginResult
                scheduleAutoAdvance()
            }
            .onDisappear {
                autoAdvanceTask?.cancel()
            }
            .onChange(of: selection) { _, newValue in
                if isProgrammaticSelectionChange {
                    isProgrammaticSelectionChange = false
                } else {
                    // 사용자가 직접 스와이프함 — 자동전환 주기를 처음부터 다시 센다.
                    scheduleAutoAdvance()
                }
                snapIfLandedOnClone(newValue)
            }
            .onChange(of: viewModel.state.needOnboarding) { _, needOnboarding in
                if let needOnboarding {
                    onLoginSucceeded(needOnboarding)
                }
            }
            .showWSSToast(isPresented: toastBinding, type: .unknownError)
    }

    private var content: some View {
        ZStack(alignment: .top) {
            WSSImage.imgLoginBackground.swiftUIImage
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                bannerCarousel

                bottomSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .disabled(viewModel.state.isLoggingIn)
    }
}

// MARK: - Sections

private extension OnboardingIntroView {
    /// 진짜 4장(0...3) 양 끝에 반대쪽 배너를 하나씩 복제해 붙인 순환 캐러셀(패딩 인덱스 0...5).
    /// 복제본은 원본과 픽셀 단위로 동일한 이미지라, 끝에 도달해 조용히 반대쪽 실제 페이지로
    /// 되감아도(`snapIfLandedOnClone`) 화면상 아무 변화가 없어 보인다 — 그래서 무한 스와이프처럼 느껴진다.
    var bannerCarousel: some View {
        TabView(selection: $selection) {
            WSSImage.imgLoginBanner4.swiftUIImage.resizable().scaledToFit().tag(0)
            WSSImage.imgLoginBanner1.swiftUIImage.resizable().scaledToFit().tag(1)
            WSSImage.imgLoginBanner2.swiftUIImage.resizable().scaledToFit().tag(2)
            WSSImage.imgLoginBanner3.swiftUIImage.resizable().scaledToFit().tag(3)
            WSSImage.imgLoginBanner4.swiftUIImage.resizable().scaledToFit().tag(4)
            WSSImage.imgLoginBanner1.swiftUIImage.resizable().scaledToFit().tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    var bottomSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 12)

            pageIndicator

            Spacer().frame(height: 30)

            socialLoginButtons
            
            Spacer().frame(height: 70)
        }
    }

    /// 활성 도트만 캡슐, 나머지는 원.
    var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<Self.bannerCount, id: \.self) { index in
                if index == currentBanner {
                    Capsule()
                        .fill(WSSColor.wssPrimary100.swiftUIColor)
                        .frame(width: 17, height: 7)
                } else {
                    Circle()
                        .fill(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 7, height: 7)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentBanner)
    }

    var socialLoginButtons: some View {
        HStack(spacing: 13) {
            Button {
                viewModel.handle(.loginStarted)
                loginWithKakao()
            } label: {
                WSSImage.imgLoginButtonKakao.swiftUIImage
                    .resizable()
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                viewModel.handle(.loginStarted)
                appleSignInHandler.start()
            } label: {
                WSSImage.imgLoginButtonApple.swiftUIImage
                    .resizable()
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 캐러셀 순환

private extension OnboardingIntroView {
    /// 복제 페이지(패딩 인덱스 0 또는 bannerCount+1)에 착지하면, 전환 애니메이션이 끝날 시간만 준 뒤
    /// 반대쪽 진짜 페이지로 조용히 되감는다 — 복제본이 원본과 동일한 이미지라 사용자는 이 점프를 못 느낀다.
    /// ⚠️ 0.35초 유예 동안 사용자가 다시 스와이프해 다른 페이지로 이동했을 수 있으므로, 발화 시점에
    /// `selection`이 여전히 이 클론 페이지인지 재확인한 뒤에만 덮어쓴다(스테일 상태 방지).
    func snapIfLandedOnClone(_ paddedIndex: Int) {
        guard paddedIndex == 0 || paddedIndex == Self.bannerCount + 1 else { return }
        let realPosition = paddedIndex == 0 ? Self.bannerCount : 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard selection == paddedIndex else { return }
            isProgrammaticSelectionChange = true
            selection = realPosition
        }
    }

    /// 자동전환 스케줄을 (재)시작한다 — 이미 대기 중이던 이전 스케줄은 취소하므로, 호출 시점부터
    /// `autoAdvanceInterval`이 다시 카운트된다. 사용자의 수동 스와이프가 이 함수를 다시 부른다.
    func scheduleAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.autoAdvanceInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            isProgrammaticSelectionChange = true
            withAnimation { selection += 1 }
            scheduleAutoAdvance()
        }
    }
}

// MARK: - SDK 연동 (Apple/Kakao 로그인 트리거 → 도메인 credential 변환)

private extension OnboardingIntroView {
    func handleAppleLoginResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let authorizationCodeData = credential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                viewModel.handle(.loginFailed)
                return
            }
            viewModel.handle(.login(.apple(authorizationCode: authorizationCode, idToken: idToken)))
        case .failure:
            // 사용자 취소를 포함한 모든 실패를 동일하게 취급한다(로그인 실패는 카피가 갈릴 이유가 없음).
            viewModel.handle(.loginFailed)
        }
    }

    func loginWithKakao() {
        // Kakao SDK 콜백 스레드는 문서상 보장되지 않는다 — @MainActor인 handle(_:) 호출 전에 명시적으로 메인으로 넘긴다.
        UserApi.shared.loginWithKakaoAccount { oauthToken, error in
            Task { @MainActor in
                guard error == nil, let accessToken = oauthToken?.accessToken else {
                    viewModel.handle(.loginFailed)
                    return
                }
                viewModel.handle(.login(.kakao(accessToken: accessToken)))
            }
        }
    }
}

// MARK: - Presentation

private extension OnboardingIntroView {
    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.hasLoginError },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }
}

// MARK: - Apple 로그인 구동기

/// SignInWithAppleButton은 시스템 고정 스타일(사각 버튼)만 지원해 Kakao와 동일한 원형 아이콘 버튼으로
/// 맞출 수 없다 — ASAuthorizationController를 직접 구동해 같은 결과(ASAuthorization)를 얻는다.
private final class AppleSignInHandler: NSObject {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?

    func start() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AppleSignInHandler: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
}

extension AppleSignInHandler: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Preview

#Preview {
    OnboardingIntroView(
        viewModel: OnboardingIntroViewModel(socialLoginUseCase: PreviewSocialLoginUseCase()),
        onLoginSucceeded: { _ in }
    )
}

private struct PreviewSocialLoginUseCase: SocialLoginUseCase {
    func execute(credential: SocialLoginCredential) async throws(AuthError) -> NeedOnboarding {
        NeedOnboarding(value: true)
    }
}
