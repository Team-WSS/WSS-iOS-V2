//
//  PushAuthorizationStatus.swift
//  PushAuthorization
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 시스템 푸시 알림 권한 상태 — `UserNotifications`의 `UNAuthorizationStatus`를 상위 레이어에 그대로
/// 노출하지 않고 이 모듈이 정리해서 재분류한다(`.provisional`/`.ephemeral`도 알림을 받을 수 있는
/// 상태라 `.authorized`로 합친다).
public enum PushAuthorizationStatus: Sendable {
    /// 권한이 있어 알림을 받을 수 있다(`.authorized`/`.provisional`/`.ephemeral`).
    case authorized
    /// 사용자가 명시적으로 거부했다 — 앱 안에서 다시 물어볼 수 없고, 기기 설정으로 안내해야 한다.
    case denied
    /// 아직 한 번도 물어보지 않았다 — `requestAuthorization()`으로 시스템 프롬프트를 띄울 수 있다.
    case notDetermined
}
