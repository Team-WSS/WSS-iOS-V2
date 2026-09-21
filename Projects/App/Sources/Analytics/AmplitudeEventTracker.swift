//
//  AmplitudeEventTracker.swift
//  WSS-iOS
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import AmplitudeSwift

import Analytics

/// `AnalyticsTracker`의 Amplitude 구현체(#249). App 레이어에만 존재 — Core/Analytics는 Amplitude를 모른다.
/// `@unchecked Sendable`: 유일한 저장 상태가 `Amplitude`(SDK 자체가 내부 이벤트 큐로 스레드 세이프,
/// 30초/30건 배치로 자체 flush)라 `WSSImageCache`(NSCache 래퍼)와 같은 결.
final class AmplitudeEventTracker: AnalyticsTracker, @unchecked Sendable {
    private let amplitude: Amplitude

    init(apiKey: String) {
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))
    }

    func track(_ name: String, properties: [String: AnalyticsPropertyValue]?) {
        amplitude.track(eventType: name, eventProperties: properties?.mapValues(\.rawValue))
    }
}

private extension AnalyticsPropertyValue {
    /// Amplitude SDK가 받는 `[String: Any]?`로 풀어주는 변환 — `AnalyticsTracker`가 `Any` 대신 고정
    /// 케이스만 노출하는 이유(Sendable)는 `Core/Analytics/CLAUDE.md` 참고.
    var rawValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value
        }
    }
}
