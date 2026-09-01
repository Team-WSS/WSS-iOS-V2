//
//  OnboardingHint.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱 전역에서 **1회성**으로 보여주는 온보딩 힌트의 종류. 화면이 늘어나면 케이스만 더한다
/// (힌트마다 저장소/UseCase를 새로 만들지 않는다 — 하나의 `OnboardingHintUseCase`가 케이스로 갈린다).
///
/// ⚠️ **`rawValue`는 로컬 저장 키의 일부다** — 한 번 정하면 바꾸지 않는다. 바꾸면 이미 힌트를 본
/// 유저에게도 "안 봤음"으로 판정돼 다시 뜬다(키가 달라져 이전 플래그를 못 찾는다).
public enum OnboardingHint: String, Sendable, CaseIterable {
    /// 작품 상세 첫 진입 시 평가 상태바를 가리키는 안내 오버레이(#221, V1 parity 복원).
    case novelDetailReview
}
