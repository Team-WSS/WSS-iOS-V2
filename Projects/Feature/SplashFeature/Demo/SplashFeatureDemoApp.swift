//
//  SplashFeatureDemoApp.swift
//  SplashFeature
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SplashFeature
import SplashDomain
import SplashDomainTesting
import DesignSystem

// Mock 시나리오 방식 Demo — 실서버 조립(도메인 6종 Repository 전부) 대신
// MockBootstrapAppUseCase로 각 BootstrapOutcome 분기·지연을 재현한다.
@main
struct SplashFeatureDemoApp: App {

    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ScenarioListView()
        }
    }
}

// 시나리오 선택 → 스플래시 표시 → onFinish 결과를 목록 상단에 표기.
private struct ScenarioListView: View {

    @State private var presentedScenario: Scenario?
    @State private var lastOutcomeDescription: String?

    var body: some View {
        NavigationStack {
            List {
                if let lastOutcomeDescription {
                    Section("마지막 onFinish 결과") {
                        Text(lastOutcomeDescription)
                    }
                }
                Section("시나리오") {
                    ForEach(Scenario.allCases) { scenario in
                        Button(scenario.title) {
                            presentedScenario = scenario
                        }
                    }
                }
            }
            .navigationTitle("SplashFeature Demo")
        }
        .fullScreenCover(item: $presentedScenario) { scenario in
            SplashFeatureFactory.makeView(bootstrapAppUseCase: scenario.makeUseCase()) { outcome in
                lastOutcomeDescription = String(describing: outcome)
                presentedScenario = nil
            }
        }
    }
}

private enum Scenario: String, CaseIterable, Identifiable {
    case mainFast
    case mainSlow
    case mainNeedsTerms
    case intro
    case forceUpdate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mainFast:       "메인 진입 (빠른 부트스트랩 — 최소 1초 노출 확인)"
        case .mainSlow:       "메인 진입 (느린 부트스트랩 3초 — 완료까지 대기 확인)"
        case .mainNeedsTerms: "메인 진입 + 약관 동의 필요"
        case .intro:          "세션 없음 → 인트로"
        case .forceUpdate:    "강제 업데이트"
        }
    }

    func makeUseCase() -> BootstrapAppUseCase {
        let mock = MockBootstrapAppUseCase()
        switch self {
        case .mainFast:
            mock.executeResult = .main(needsTermsAgreement: false)
        case .mainSlow:
            mock.executeResult = .main(needsTermsAgreement: false)
            mock.executeDelay = .seconds(3)
        case .mainNeedsTerms:
            mock.executeResult = .main(needsTermsAgreement: true)
        case .intro:
            mock.executeResult = .intro
        case .forceUpdate:
            mock.executeResult = .forceUpdate
        }
        return mock
    }
}
