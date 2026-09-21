//
//  AnalyticsTracker.swift
//  Analytics
//
//  Created by Claude on 9/7/26.
//

import Foundation

/// 이벤트 트래킹 추상화. `Logger`와 동일한 형태 — 이 모듈은 Amplitude/Clarity 등 구체 SDK를 모른다.
/// Feature는 이 프로토콜만 보고 호출하고, 실제 구현체는 App(DI)이 만들어 Factory 체인으로 주입한다.
public protocol AnalyticsTracker: Sendable {
    func track(_ name: String, properties: [String: AnalyticsPropertyValue]?)
}

public extension AnalyticsTracker {
    func track(_ name: String) {
        track(name, properties: nil)
    }

    /// `AnalyticsEvent` enum으로 호출하는 타입 세이프 오버로드 — 이벤트 이름 문자열을 호출부에 흩뿌리지
    /// 않는다. 각 Feature 모듈이 자기 화면의 이벤트만 담은 `enum XxxAnalyticsEvent: String, AnalyticsEvent`를
    /// 선언하면(레이어 규칙상 이 모듈에 두지 않는다 — Core는 제품 개념을 모른다), 이 확장이 `rawValue`로
    /// 풀어 위 문자열 버전으로 위임한다.
    func track<Event: AnalyticsEvent>(_ event: Event, properties: [String: AnalyticsPropertyValue]? = nil) {
        track(event.rawValue, properties: properties)
    }
}

/// 이벤트 이름 enum이 채택하는 마커 프로토콜. `RawValue == String`만 요구해 각 Feature 모듈이 제품
/// 개념(화면·액션)을 아는 자기 이벤트 enum을 독립적으로 선언할 수 있게 한다 — 이 프로토콜 자체는
/// 어떤 이벤트가 있는지 모른다(Core는 위를 모른다는 원칙 유지).
public protocol AnalyticsEvent: RawRepresentable, Sendable where RawValue == String {}

/// 이벤트 프로퍼티 값. `Any` 대신 고정된 케이스만 허용해 `Sendable`을 지킨다(Swift 6 mode 6 대비).
public enum AnalyticsPropertyValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}
