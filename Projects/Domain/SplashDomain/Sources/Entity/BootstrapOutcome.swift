//
//  BootstrapOutcome.swift
//  SplashDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 런치 부트스트랩의 최종 판정.
///
/// SplashFeature가 이 값을 콜백으로 App에 넘기고, 화면 전환(라우팅)은 App이 수행한다.
public enum BootstrapOutcome: Sendable, Equatable {
    /// 앱 최소 버전 미달 — 진입 차단, 닫기 불가 업데이트 알럿.
    case forceUpdate
    /// 유효한 세션 없음 — 인트로(온보딩)로.
    case intro
    /// 홈 진입. 필수 약관 미동의 유저면 약관 시트를 함께 띄운다.
    case main(needsTermsAgreement: Bool)
}
