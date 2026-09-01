import SwiftUI

import BaseDomain
import OnboardingFeature
import SettingDomain
import SplashDomain
import SplashFeature
import WSSComponent

/// 앱 루트 — 스플래시(부트스트랩) → 온보딩(로그인~가입) ↔ 홈, 세 플로우를 전환한다.
/// `AppDependencies`는 플로우들이 같은 토큰(로그인 직후 저장된 것)으로 인증 API를 불러야 하므로
/// 여기 한 번만 만들어 아래로 내려준다. 단 **세션이 끝나는 경로(`resetToOnboarding`)에서는 통째로
/// 재조립한다** — 이전 세션에서 채워졌을 수 있는 `HomePrefetchStore` 슬롯을 인스턴스째 버리기 위함.
public struct ContentView: View {
    private enum Route {
        case splash
        case onboarding
        case main
    }

    @State private var dependencies = AppDependencies()
    @State private var route: Route = .splash
    /// 강제 업데이트 게이트(`BootstrapOutcome.forceUpdate`) — 스플래시 위에 닫기 불가 알럿으로 덮는다.
    @State private var isForceUpdateAlertPresented = false
    /// 필수 약관 미동의(`BootstrapOutcome.main(needsTermsAgreement: true)`) — 홈 위 알럿 → 동의 시트 순서(V1 파리티).
    @State private var isTermsAgreementAlertPresented = false
    @State private var isTermsAgreementSheetPresented = false
    /// 앱 밖에서 들어온 딥링크(`WSSIOSV2App.onOpenURL`) — `MainTabView`가 소비한다. 스플래시·온보딩 중엔
    /// 그대로 들고 있다가 `.main`으로 전환되는 순간 이어서 처리된다(공개 컬렉션은 서버가 비로그인 조회를
    /// 허용하지만, 앱 게이트가 메인 탭을 온보딩으로 되돌리므로 로그인 뒤 연결이 현실적이다). "보던 중
    /// 만료" 401 바운스 시점엔 `MainTabView`가 소비한 링크를 `deliveredDeepLink`로 되살려 놓는다.
    @Binding private var pendingDeepLink: DeepLink?
    @Environment(\.openURL) private var openURL

    public init(pendingDeepLink: Binding<DeepLink?> = .constant(nil)) {
        self._pendingDeepLink = pendingDeepLink
    }

    public var body: some View {
        Group {
            switch route {
            case .splash:
                splashView
            case .onboarding:
                OnboardingRootView(dependencies: dependencies, onFinished: { route = .main })
            case .main:
                MainTabView(
                    dependencies: dependencies,
                    pendingDeepLink: $pendingDeepLink,
                    onAuthenticationRequired: resetToOnboarding
                )
            }
        }
        // 강제 업데이트 — 버튼은 앱스토어로 보낼 뿐 표시 상태를 되돌리지 않는다(닫기 불가 게이트).
        // WSSAlert는 버튼 탭이 알럿을 자동으로 닫지 않는 계약이라 이 "안 닫힘"이 그대로 성립한다.
        .showWSSAlert(
            isPresented: $isForceUpdateAlertPresented,
            type: .needVersionUpdate,
            buttonActions: [openAppStore]
        )
        .showWSSAlert(
            isPresented: $isTermsAgreementAlertPresented,
            type: .needTermsAgreement,
            buttonActions: [
                {
                    isTermsAgreementAlertPresented = false
                    isTermsAgreementSheetPresented = true
                }
            ]
        )
        .sheet(isPresented: $isTermsAgreementSheetPresented) {
            termsAgreementSheet
        }
        // DesignSystem 색상이 전부 고정값(다크 배리언트 없음, WSSColor.wssWhite 등)이라 시스템이
        // 다크모드면 배경만 시스템 기본(검정)으로 바뀌어 보인다 — 화면마다 .background(wssWhite)를
        // 개별로 다는 대신 앱 전체를 라이트모드로 고정해 한 번에 막는다(사용자 확정).
        .preferredColorScheme(.light)
    }
}

// MARK: - 스플래시(런치 부트스트랩)

private extension ContentView {
    /// 완료 신호가 `onChange(of: state.outcome)` 기반이라 **`onFinish`가 불릴 때까지 이 뷰를 계층에서
    /// 빼면 안 된다**(`SplashFeature/CLAUDE.md`). 초기 route라 자연히 상시 마운트되고, `.forceUpdate`
    /// 낙착 시에도 route를 바꾸지 않고 이 화면 위에 알럿만 덮는다.
    var splashView: some View {
        SplashFeatureFactory.makeView(
            bootstrapAppUseCase: DefaultBootstrapAppUseCase(
                gateRepository: dependencies.launchGateRepository,
                taskRepository: dependencies.launchTaskRepository
            ),
            onFinish: handleBootstrapOutcome
        )
    }

    func handleBootstrapOutcome(_ outcome: BootstrapOutcome) {
        switch outcome {
        case .forceUpdate:
            isForceUpdateAlertPresented = true
        case .intro:
            resetToOnboarding()
        case .main(let needsTermsAgreement):
            route = .main
            isTermsAgreementAlertPresented = needsTermsAgreement
        }
    }

    func openAppStore() {
        guard let url = AppURL.appStore else { return }
        openURL(url)
    }
}

// MARK: - 약관 동의 시트 (업데이트된 필수 약관 재동의)

private extension ContentView {
    /// 온보딩 2단계와 같은 화면(`makeTermsAgreementView`)을 재사용한다 — 시트 닫기 방지
    /// (`interactiveDismissDisabled`)는 그 화면이 자체 보유한다.
    var termsAgreementSheet: some View {
        OnboardingFeatureFactory.makeTermsAgreementView(
            loadUseCase: DefaultLoadTermsAgreementDraftUseCase(repository: dependencies.termsAgreementRepository),
            saveUseCase: DefaultSaveTermsAgreementDraftUseCase(repository: dependencies.termsAgreementRepository),
            logger: dependencies.logger,
            onAgreed: { isTermsAgreementSheetPresented = false },
            onAuthenticationRequired: resetToOnboarding
        )
    }
}

// MARK: - 세션 종료 수렴점

private extension ContentView {
    /// 세션이 끝나는 모든 경로(부트스트랩 `.intro` 낙착·401 만료·로그아웃/탈퇴)의 단일 수렴점.
    /// 온보딩으로 되돌리면서 `AppDependencies`를 **새로 조립**한다 — 런치 프리페치가 유효 토큰으로
    /// 채운 `HomePrefetchStore` 슬롯이 소비 전에 세션이 바뀌면 다음 사용자에게 새는 좁은 레이스를
    /// (`docs/TODO.md` 11절) 인스턴스 교체로 닫는다. 여러 탭이 시간차로 불러도(401 idempotent 계약)
    /// 재조립은 1회만 한다. 토큰 삭제는 하지 않는다 — 401은 이미 서버가 세션을 무효화한 상태고,
    /// 로그아웃/탈퇴는 `DefaultAuthRepository`가 성공 시 스스로 지운다.
    func resetToOnboarding() {
        guard route != .onboarding else { return }
        dependencies = AppDependencies()
        isTermsAgreementAlertPresented = false
        isTermsAgreementSheetPresented = false
        route = .onboarding
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
