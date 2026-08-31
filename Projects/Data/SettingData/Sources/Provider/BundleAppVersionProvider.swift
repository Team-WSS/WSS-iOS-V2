//
//  BundleAppVersionProvider.swift
//  SettingData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SettingDomain

/// `AppVersionProviding` 실구현 — 번들의 `CFBundleShortVersionString`(MARKETING_VERSION)을 파싱한다 (#225).
///
/// TODO 2절이 지적한 "실구현체 없음" 함정의 해소.
/// 조립은 `SettingDataFactory.makeAppVersionProvider(bundle:)`로만 — Data 모듈은 팩토리만 public이다(ArchLint `factory-exclusivity`).
struct BundleAppVersionProvider: AppVersionProviding {

    let currentVersion: AppVersion

    init(bundle: Bundle = .main) {
        self.init(versionString: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }

    init(versionString: String?) {
        if let versionString, let parsed = try? AppVersion(versionString) {
            self.currentVersion = parsed
        } else {
            // 파싱 실패는 사실상 불가(우리가 관리하는 MARKETING_VERSION)지만, 만에 하나 깨져도
            // `.zero` 폴백이면 최소 버전 비교에서 무조건 지므로 **앱이 강제 업데이트 알럿에 잠긴다**.
            // "정책 조회/판정 실패는 통과" 철학에 맞춰 절대 강제되지 않는 방향으로 폴백한다.
            self.currentVersion = AppVersion(major: .max, minor: 0, patch: 0)
        }
    }
}
