//
//  PushNotificationCenter.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

import FirebaseCore
import FirebaseMessaging

import BaseData
import BaseDomain
import NotificationDomain

/// 앱의 FCM/APNs 런타임 허브(#243).
///
/// **왜 shared 싱글턴인가**: UIKit `AppDelegate`(원격 알림 시스템 콜백을 받는 쪽)와 SwiftUI DI
/// (`AppDependencies` — 토큰 등록 UseCase를 조립하는 쪽)는 서로 다른 생명주기라 인스턴스를 공유할
/// 마땅한 통로가 없다. V1도 같은 이유로 `NotificationHelper.shared`를 썼다. Firebase(`Messaging`) import는
/// 이 App 레이어 안(이 파일 + `AppDelegate`)에만 가둔다 — Domain/Data는 `DevicePushToken` 추상화로 이미 분리돼 있다.
///
/// **등록이 일어나는 두 경로**(둘 다 필요):
/// 1. 부트스트랩 pull — `currentDevicePushToken()`을 `SplashDomain`의 런치 태스크가 세션 있을 때 당겨간다
///    (이미 권한을 허용한 재방문 사용자). 이 허브는 Firebase에서 현재 토큰을 만들어 돌려주기만 한다.
/// 2. 반응 push — 권한을 새로 허용하거나 토큰이 갱신되면 `setFCMRegistrationToken`이 로그인 상태에서 서버로 등록한다
///    (부트스트랩이 이미 지나간 뒤 로그인/허용하는 신규 사용자 — 이게 없으면 다음 실행까지 등록이 밀린다).
@MainActor
final class PushNotificationCenter {

    static let shared = PushNotificationCenter()

    private let deviceIdentifierStore: DeviceIdentifierStore
    /// `AppDependencies`가 조립 시 주입 — FCM 토큰을 서버에 등록하는 훅(`RegisterDeviceTokenUseCase` 래핑).
    private var registerDeviceToken: (@Sendable (DevicePushToken) async -> Void)?
    /// `AppDependencies`가 조립 시 주입 — 현재 로그인(세션 보유) 여부.
    private var isLoggedIn: (@Sendable () -> Bool)?
    /// `AppDependencies`가 조립 시 주입 — 알림 읽음 처리 훅(`MarkNotificationAsReadUseCase` 래핑, 인자는 알림 id).
    private var markNotificationAsRead: (@Sendable (Int) async -> Void)?
    /// 마지막으로 받은 FCM 등록 토큰. 로그인 전에 도착하면 보관만 하고, 로그인/조립 시점에 등록에 쓴다.
    private var latestFCMToken: String?

    /// 알림 탭으로 만들어진 딥링크를 앱(`WSSIOSV2App`)의 `pendingDeepLink` 채널로 넘기는 통로. App이 등록한다.
    /// ⚠️ 콜드 스타트(알림 탭으로 앱이 실행)면 콜백 등록 전에 탭이 도착할 수 있어, 등록되는 순간 보관분을 flush한다.
    var onNotificationDeepLink: (@MainActor (DeepLink) -> Void)? {
        didSet {
            guard let onNotificationDeepLink, let pending = pendingNotificationDeepLink else { return }
            pendingNotificationDeepLink = nil
            onNotificationDeepLink(pending)
        }
    }
    private var pendingNotificationDeepLink: DeepLink?

    private init(deviceIdentifierStore: DeviceIdentifierStore = DefaultDeviceIdentifierStore()) {
        self.deviceIdentifierStore = deviceIdentifierStore
    }

    // MARK: - Configuration (AppDependencies가 조립 시 호출)

    /// 서버 등록 훅과 로그인 판정을 주입한다. 세션이 끝나 `AppDependencies`가 재조립되면 다시 불려
    /// 새 UseCase/tokenStore로 갱신된다(idempotent). 이미 토큰을 들고 있고 로그인 상태면 여기서 한 번 등록을 시도한다
    /// (부트스트랩이 지나간 뒤 로그인한 신규 사용자가 이 조립 시점에 걸리는 경로).
    func configure(
        registerDeviceToken: @escaping @Sendable (DevicePushToken) async -> Void,
        isLoggedIn: @escaping @Sendable () -> Bool,
        markNotificationAsRead: @escaping @Sendable (Int) async -> Void
    ) {
        self.registerDeviceToken = registerDeviceToken
        self.isLoggedIn = isLoggedIn
        self.markNotificationAsRead = markNotificationAsRead

        guard let token = latestFCMToken, isLoggedIn() else { return }
        let devicePushToken = DevicePushToken(token: token, deviceID: deviceIdentifier())
        Task { await registerDeviceToken(devicePushToken) }
    }

    // MARK: - AppDelegate가 전달하는 시스템 콜백

    /// APNs device token 수신 → Firebase에 직접 대입(method swizzling off — `FirebaseAppDelegateProxyEnabled=NO`).
    func setAPNSToken(_ deviceToken: Data) {
        guard isFirebaseConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    /// FCM 등록 토큰 수신/갱신 → 보관 + 로그인 상태면 서버 등록.
    func setFCMRegistrationToken(_ token: String?) {
        guard let token else { return }
        latestFCMToken = token

        guard isLoggedIn?() == true, let registerDeviceToken else { return }
        let devicePushToken = DevicePushToken(token: token, deviceID: deviceIdentifier())
        Task { await registerDeviceToken(devicePushToken) }
    }

    /// 알림 탭(`AppDelegate.didReceive`)의 payload를 딥링크로 풀어 앱으로 넘긴다. `view`에 맞는 화면으로
    /// 이동한다(작품/피드 상세). 콜백이 아직 없으면(콜드 스타트) 보관 후 등록 시 flush. 모르는 payload는 무시.
    func handleNotificationTap(payload: [String: String]) {
        // 읽음 처리는 딥링크(화면 이동) 유무와 무관하게 — 탭한 알림은 읽음으로(V1 parity).
        markNotificationAsReadIfPossible(payload)

        guard let deepLink = DeepLink.fromNotificationPayload(payload) else { return }
        if let onNotificationDeepLink {
            onNotificationDeepLink(deepLink)
        } else {
            pendingNotificationDeepLink = deepLink
        }
    }

    /// 탭한 알림을 서버에 읽음 처리한다(V1 parity). 로그인 상태 + payload에 유효한 `notificationId`가 있을 때만 —
    /// 미로그인이면 어차피 401이라 조용히 건너뛴다. 실패는 fire-and-forget으로 삼킨다(등록 훅과 동일 계약).
    private func markNotificationAsReadIfPossible(_ payload: [String: String]) {
        guard isLoggedIn?() == true, let markNotificationAsRead,
              let raw = payload["notificationId"],   // 서버 push payload 키(#243)
              let id = Int(raw), id > 0
        else { return }
        Task { await markNotificationAsRead(id) }
    }

    // MARK: - 부트스트랩 pull (SplashData의 deviceTokenProvider가 호출)

    /// 부트스트랩(세션 있을 때)이 당겨가는 현재 디바이스 푸시 토큰. 알림 권한이 허용된 경우에만 FCM 토큰을
    /// 만들어 돌려준다 — 미허용/실패면 nil을 주고, 런치 태스크는 등록을 조용히 건너뛴다.
    func currentDevicePushToken() async -> DevicePushToken? {
        guard isFirebaseConfigured else { return nil }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else { return nil }
        guard let token = try? await Messaging.messaging().token() else { return nil }

        latestFCMToken = token
        return DevicePushToken(token: token, deviceID: deviceIdentifier())
    }

    // MARK: - 권한 요청 + 원격 알림 등록 (메인 탭 진입, V1 parity)

    /// 로그인 상태의 메인 진입 시 호출(V1은 홈 진입에서 수행). 권한이 미결정이면 요청하고, 허용 상태면 APNs
    /// 등록을 시작한다. 등록이 끝나면 `didRegister…`(AppDelegate) → `setAPNSToken` → `MessagingDelegate` →
    /// `setFCMRegistrationToken`으로 이어져 서버 등록까지 흐른다.
    func requestAuthorizationAndRegisterIfGranted() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    /// Firebase 기본 앱이 실제로 구성됐는지. `GoogleService-Info` plist가 없으면(gitignore돼 로컬/CI에 미배치)
    /// `AppDelegate`가 `configure`를 건너뛴다 → **`Messaging.messaging()`을 만지기 전에 이걸로 가드**한다.
    /// 미구성 상태에서 `Messaging.messaging()`을 부르면 "default app not configured"로 Firebase가 크래시한다.
    private var isFirebaseConfigured: Bool {
        FirebaseApp.app() != nil
    }

    // MARK: - Device identifier (V1과 동일 — Keychain에 UUID 영속, get-or-create)

    /// 서버 등록 바디의 `deviceIdentifier`. `Auth`가 쓰는 것과 같은 Keychain 저장소를 재사용한다.
    private func deviceIdentifier() -> String {
        if let existing = try? deviceIdentifierStore.deviceIdentifier() {
            return existing
        }
        let generated = UUID().uuidString
        try? deviceIdentifierStore.saveDeviceIdentifier(generated)
        return generated
    }
}
