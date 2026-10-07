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
    /// 성공 여부를 돌려준다 — 성공한 토큰만 `registeredToken`으로 기억해, 실패한 토큰은 다음 기회에 다시 보낸다.
    private var registerDeviceToken: (@Sendable (DevicePushToken) async -> Bool)?
    /// `AppDependencies`가 조립 시 주입 — 현재 로그인(세션 보유) 여부.
    private var isLoggedIn: (@Sendable () -> Bool)?
    /// `AppDependencies`가 조립 시 주입 — 알림 읽음 처리 훅(`MarkNotificationAsReadUseCase` 래핑, 인자는 알림 id).
    private var markNotificationAsRead: (@Sendable (Int) async -> Void)?
    /// 마지막으로 받은 FCM 등록 토큰. 로그인 전에 도착하면 보관만 하고, 로그인/조립 시점에 등록에 쓴다.
    private var latestFCMToken: String?
    /// 이번 세션에서 서버 등록에 성공한 토큰 / 지금 등록 요청 중인 토큰. 한 실행 안에서 여러 경로(시작 시 delegate,
    /// 메인 탭 진입의 `token()` 조회)가 같은 토큰을 거듭 보내지 않게 거른다. `configure`(세션 시작·종료 시 재조립)가
    /// 비우므로 로그아웃 → 재로그인하면 다시 등록된다 — 서버가 로그아웃 때 이 기기의 토큰 행을 지우기 때문에 필요하다.
    private var registeredToken: String?
    private var registeringToken: String?
    /// `configure`마다 1씩 오른다. 이전 세션에서 시작된 등록 요청이 늦게 끝나 새 세션의 `registeredToken`을 채우지 않게 한다.
    private var sessionGeneration = 0

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

    /// 서버 등록 훅과 로그인 판정을 주입한다. 앱 시작과 세션 종료(`resetToOnboarding`)로 `AppDependencies`가
    /// 조립될 때마다 불려 새 UseCase/tokenStore로 갱신되고, 등록 기록도 비운다. 이미 토큰을 들고 있고 로그인 상태면
    /// 여기서 한 번 등록을 시도한다.
    func configure(
        registerDeviceToken: @escaping @Sendable (DevicePushToken) async -> Bool,
        isLoggedIn: @escaping @Sendable () -> Bool,
        markNotificationAsRead: @escaping @Sendable (Int) async -> Void
    ) {
        self.registerDeviceToken = registerDeviceToken
        self.isLoggedIn = isLoggedIn
        self.markNotificationAsRead = markNotificationAsRead
        registeredToken = nil
        registeringToken = nil
        sessionGeneration += 1

        guard let latestFCMToken else { return }
        registerIfLoggedIn(latestFCMToken)
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
        registerIfLoggedIn(token)
    }

    /// 로그인 상태면 토큰을 서버에 등록한다. 이번 세션에서 이미 성공했거나 요청 중인 토큰이면 건너뛴다.
    /// 로그인 전이면 아무것도 안 한다 — 토큰은 `latestFCMToken`에 남아 있고, 로그인 후 메인 탭 진입이 다시 등록을 부른다.
    private func registerIfLoggedIn(_ token: String) {
        guard isLoggedIn?() == true, let registerDeviceToken else { return }
        guard token != registeredToken, token != registeringToken else { return }

        registeringToken = token
        let generation = sessionGeneration
        let devicePushToken = DevicePushToken(token: token, deviceID: deviceIdentifier())
        Task {
            let succeeded = await registerDeviceToken(devicePushToken)
            guard generation == sessionGeneration else { return }
            if registeringToken == token { registeringToken = nil }
            if succeeded { registeredToken = token }
        }
    }

    /// 알림 탭(`AppDelegate.didReceive`)의 payload를 딥링크로 풀어 앱으로 넘긴다. `view`에 맞는 화면으로
    /// 이동한다(작품/피드/알림 상세). 콜백이 아직 없으면(콜드 스타트) 보관 후 등록 시 flush. 모르는 payload는 무시.
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

    /// 로그인 상태의 메인 진입 시 호출(V1은 홈 진입에서 수행). 권한이 미결정이면 요청하고, **결과와 무관하게**
    /// APNs 등록을 시작한다(#287) — 서버는 등록된 기기가 없으면 앱 내 알림도 만들지 않으므로, 권한을 거절한
    /// 사용자도 기기 등록은 돼 있어야 한다(V1 parity). 배너 표시 여부는 iOS가 권한에 따라 알아서 거른다.
    /// 등록이 끝나면 `didRegister…`(AppDelegate) → `setAPNSToken`으로 이어진다.
    func requestAuthorizationAndRegisterForRemoteNotifications() async {
        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
        UIApplication.shared.registerForRemoteNotifications()
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
