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
import KakaoSDKCommon
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
    /// 순환 캐러셀의 "패딩된" 페이지 목록 — 진짜 4장(인덱스 1...4) 양 끝에 반대쪽 배너를 복제해 붙였다
    /// (0=4번 클론, 5=1번 클론). 클론이 원본과 픽셀 단위로 동일해 끝에 도달했을 때 조용히 반대쪽 진짜
    /// 페이지로 되감아도(`snapIfLandedOnClone`) 화면상 변화가 없어 무한 스와이프처럼 느껴진다.
    private static let paddedBanners: [DesignSystemImages] = [
        WSSImage.imgLoginBanner4,
        WSSImage.imgLoginBanner1,
        WSSImage.imgLoginBanner2,
        WSSImage.imgLoginBanner3,
        WSSImage.imgLoginBanner4,
        WSSImage.imgLoginBanner1,
    ]

    @State private var viewModel: OnboardingIntroViewModel
    /// 캐러셀(`scrollPosition`)이 물고 있는 패딩 인덱스(0...5). 스크롤이 페이지에 정착할 때 갱신되며,
    /// 레이아웃 확정 전엔 nil일 수 있어 옵셔널이다(소비처는 `?? 1`로 방어).
    @State private var selection: Int? = 1
    /// 다음 `.onChange(of: selection)` 호출 1회가 자동전환/복제-보정처럼 코드가 스스로 일으킨 변경임을 표시.
    /// 이게 false인 채로 selection이 바뀌면 "사용자가 직접 스와이프했다"는 뜻이라 자동전환 주기를 리셋한다.
    @State private var isProgrammaticSelectionChange = false
    @State private var autoAdvanceTask: Task<Void, Never>?
    /// 사용자가 보는 진짜 배너 인덱스(0...3) — 도트 인디케이터는 항상 이 값을 쓴다(패딩 인덱스 노출 금지).
    private var currentBanner: Int {
        switch selection ?? 1 {
        case 0: Self.bannerCount - 1
        case Self.bannerCount + 1: 0
        default: (selection ?? 1) - 1
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
        // 에러 토스트를 **화면 세이프에어리어 바닥**에 고정한다(#257). 전경(배너·버튼)은 고정 배너(567)로
        // 작은 기기(SE)에서 화면 아래로 넘쳐, 공용 `.showWSSToast`(ZStack이 content 크기를 따라감)에 걸면
        // 토스트가 그 넘친 바닥에 붙어 화면 밖으로 잘렸다(실측). 그래서 GeometryReader로 세이프에어리어
        // 프레임을 잡아 ZStack을 그 크기로 클램프하고, 토스트 레이어를 그 프레임 바닥에 고정해 전경 넘침과
        // 분리한다. 배경 이미지는 자기만 `.ignoresSafeArea()`로 full-bleed(상태바·홈 인디케이터까지 덮음).
        // ⚠️ `.ignoresSafeArea()`는 화면 전체(GeometryReader)가 아니라 배경에만 건다 — 전체에 걸고
        // 전경을 인셋 수동 패딩으로 배치했다가 당시 TabView 기반 캐러셀이 깨지는 회귀가 있었다
        // (상세는 CLAUDE.md 주의사항). 전경을 정상 세이프에어리어에 두는 현 구조가 더 단순하기도 하다.
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                backgroundLayer

                foregroundContent

                if viewModel.state.hasLoginError {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        WSSToastView(type: .unknownError)
                    }
                    .padding(.bottom, 40)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    .transition(.opacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.hasLoginError)
        .onAppear {
            appleSignInHandler.onCompletion = handleAppleLoginResult
            scheduleAutoAdvance()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
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
        // 토스트 자동 닫힘 — 공용 `.showWSSToast`(WSSToastViewModifier)를 이 화면 전용 배치로 대체하면서
        // 그 타이머(기본 1.5초)도 여기로 옮겼다. `.task(id:)`가 hasLoginError 변화마다 이전 sleep을 취소·재시작해
        // 재발화에도 견고하다(WSSToastViewModifier의 `.task(id: isPresented)`와 동일 패턴).
        .task(id: viewModel.state.hasLoginError) {
            guard viewModel.state.hasLoginError else { return }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            viewModel.handle(.dismissError)
        }
    }

    /// full-bleed 배경 — 자기만 `.ignoresSafeArea()`로 확장해 상태바·홈 인디케이터 영역까지 덮는다.
    /// 전경은 정상 세이프에어리어 레이아웃에 남아 인셋 영역엔 배경만 비친다(흰 띠 없음).
    private var backgroundLayer: some View {
        WSSImage.imgLoginBackground.swiftUIImage
            .resizable()
            .background(WSSColor.wssWhite.swiftUIColor)
            .ignoresSafeArea()
    }

    /// 전경(배너·도트·소셜 버튼) — 배경은 위 `backgroundLayer`가 담당하므로 여기선 그리지 않는다.
    /// 투명 배경이라 배경 레이어가 비친다.
    private var foregroundContent: some View {
        VStack(spacing: 0) {
            bannerCarousel

            Spacer()

            bottomSection
                .padding(.horizontal, 16)

            Spacer().frame(height: 67)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .disabled(viewModel.state.isLoggingIn)
    }
}

// MARK: - Sections

private extension OnboardingIntroView {
    /// 순환 캐러셀(구성은 `paddedBanners` 참고) — iOS 17 순수 SwiftUI 페이저(`scrollTargetBehavior(.paging)`).
    /// ⚠️ `TabView(.page)`로 되돌리지 말 것: UIKit 페이징 브리지는 `withAnimation`을 통한 프로그램적
    /// `selection` 전환이 실기기에서 엉뚱한 이웃 페이지(선두 클론)로 애니메이션되고, 그 뒤로 내부 페이지와
    /// `selection`이 어긋나 인디케이터만 돌고 이미지는 안 넘어가는 결함이 있다(실기기 실측 — 시뮬레이터와
    /// 증상까지 달라, 레이아웃을 고쳐도 못 잡아 페이저 자체를 교체했다).
    var bannerCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Self.paddedBanners.indices, id: \.self) { index in
                        Self.paddedBanners[index].swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selection)
            .scrollIndicators(.hidden)
            .frame(height: 567)
            // ⚠️ `.scrollPosition(id:)`의 초기값(`selection = 1`)은 **첫 레이아웃 패스에서 적용되지 않는다**
            // (iOS 17 한계) — ScrollView가 맨 앞(패딩 인덱스 0 = banner4 복제본)에 주차되고, 바인딩이
            // 실제 위치를 되쓰지도 않아 인디케이터(selection=1 → 첫 도트)와 한 칸 어긋난다. 첫 프로그램적
            // selection 변경(auto-advance)이 일어나야 그제서야 재동기화됐다("한 바퀴 돌면 괜찮아짐"의 정체).
            // 그래서 레이아웃이 확정된 다음 런루프에 초기 위치를 명시적으로 강제한다(`scrollTo`는 첫
            // 레이아웃 이후엔 정상 동작). `DispatchQueue.main.async` 없이 onAppear에서 곧바로 부르면
            // 아직 레이아웃 전이라 같은 이유로 먹지 않는다.
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selection ?? 1, anchor: .leading)
                }
            }
        }
    }

    var bottomSection: some View {
        VStack(spacing: 0) {
            pageIndicator

            Spacer().frame(height: 60)

            socialLoginButtons
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
            // 명시적 duration — `snapIfLandedOnClone`의 0.35초 유예가 "전환이 끝났을 시간"을 전제하므로
            // 기본 스프링(감쇠 꼬리가 더 김) 대신 이보다 확실히 짧은 애니메이션을 쓴다.
            withAnimation(.easeInOut(duration: 0.3)) { selection = (selection ?? 1) + 1 }
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
        case .failure(let error):
            // 사용자 취소(#257)와 진짜 오류를 구분한다 — 취소는 에러 토스트를 띄우지 않는다.
            viewModel.handle(isUserCancellation(error) ? .loginCancelled : .loginFailed)
        }
    }

    func loginWithKakao() {
        // Kakao SDK 콜백 스레드는 문서상 보장되지 않는다 — @MainActor인 handle(_:) 호출 전에 명시적으로 메인으로 넘긴다.
        UserApi.shared.loginWithKakaoAccount { oauthToken, error in
            Task { @MainActor in
                guard error == nil, let accessToken = oauthToken?.accessToken else {
                    // 사용자 취소(#257)와 진짜 오류를 구분한다 — 취소는 에러 토스트를 띄우지 않는다.
                    viewModel.handle(isUserCancellation(error) ? .loginCancelled : .loginFailed)
                    return
                }
                viewModel.handle(.login(.kakao(accessToken: accessToken)))
            }
        }
    }

    /// 소셜 로그인 SDK가 돌려준 에러가 "사용자가 직접 취소"인지 판별한다(#257) — 진짜 오류와 구분해
    /// 취소일 땐 에러 토스트를 띄우지 않기 위함. Apple은 `ASAuthorizationError.canceled`,
    /// Kakao는 `SdkError`의 `ClientFailed(.Cancelled)`. `nil`(에러 없음)은 취소가 아니다.
    func isUserCancellation(_ error: Error?) -> Bool {
        guard let error else { return false }
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            return true
        }
        if let sdkError = error as? SdkError,
           sdkError.isClientFailed,
           sdkError.getClientError().reason == .Cancelled {
            return true
        }
        return false
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
