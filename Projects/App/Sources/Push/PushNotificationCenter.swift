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
/// **서버 등록이 일어나는 경로**(#287). 전부 `latestFCMToken`을 갱신한 뒤 `registerLatestTokenIfNeeded`로 모인다.
/// 같은 세션에서 같은 토큰은 한 번만 보내고, 요청은 한 번에 하나씩 보낸다.
/// 1. 메인 탭 진입 — `registerForRemoteNotifications` → `didRegister…` → `setAPNSToken`이 곧바로 `token()`을 조회해
///    등록한다. 로그인·가입 직후에도 메인 탭을 지나므로 **실행 중 로그인한 사용자를 책임지는 경로는 이것**이다.
/// 2. Firebase delegate(`setFCMRegistrationToken`) — 앱 시작 시 캐시 토큰으로 1회, 그리고 실행 중 토큰이 실제로
///    바뀔 때만 불린다. 같은 APNs 토큰을 다시 넣으면 Firebase는 아무것도 하지 않으므로 delegate만으로는
///    "실행 중 로그아웃 → 재로그인"이나 "로그아웃 상태로 켬 → 로그인"을 놓친다(#287 실측).
/// 3. `configure` — 조립 시점에 이미 토큰을 들고 있고 로그인 상태일 때.
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
    /// 마지막으로 받은 FCM 등록 토큰. 서버에 보내는 값은 항상 이것이다 — 로그인 전에 도착하면 보관만 한다.
    private var latestFCMToken: String?
    /// 이번 세션에서 서버 등록에 성공한 토큰 / 지금 등록 요청 중인 토큰. 한 실행 안에서 여러 경로(시작 시 delegate,
    /// 메인 탭 진입의 `token()` 조회)가 같은 토큰을 거듭 보내지 않게 거른다. 앱 시작·세션 종료(`configure`)와
    /// 로그인 완료(`resetRegistrationRecord`)에서 비운다 — 서버가 로그아웃 때 이 기기의 토큰 행을 지우고, 등록은
    /// 계정마다 따로이기 때문에 새로 로그인한 계정에는 같은 토큰이라도 다시 보내야 한다.
    private var registeredToken: String?
    private var registeringToken: String?
    /// 등록 기록을 비울 때마다 1씩 오른다. 이전 세션에서 시작된 등록 요청이 늦게 끝나 새 세션의 기록을 채우지 않게 한다.
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
        resetRegistrationRecord()
        registerLatestTokenIfNeeded()
    }

    /// 등록 기록을 비워 다음 등록 경로가 토큰을 다시 보내게 한다. `configure` 외에 **로그인 완료 시**(`ContentView`)에도
    /// 불린다 — 로그인 때는 `AppDependencies`를 재조립하지 않아 `configure`가 안 불리는데, 가입을 마치지 않은 세션으로
    /// 켜서 인트로에 간 뒤 다른 계정으로 로그인하면 이전 계정 몫으로 기록된 토큰을 건너뛰어 새 계정이 미등록으로 남는다.
    func resetRegistrationRecord() {
        registeredToken = nil
        registeringToken = nil
        sessionGeneration += 1
    }

    // MARK: - AppDelegate가 전달하는 시스템 콜백

    /// APNs device token 수신 → Firebase에 직접 대입(method swizzling off — `FirebaseAppDelegateProxyEnabled=NO`)한 뒤,
    /// FCM 토큰을 직접 조회해 등록한다. iOS는 `registerForRemoteNotifications`를 부를 때마다 이 콜백을 다시 주므로
    /// 메인 탭 진입마다 여기를 지난다.
    func setAPNSToken(_ deviceToken: Data) {
        guard isFirebaseConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
        Task { await fetchFCMTokenAndRegister() }
    }

    /// `token()`은 APNs 토큰이 있어야 성공하므로 `setAPNSToken` 뒤에서만 부른다. 캐시 토큰이 낡았으면(설치 ID·앱 버전·
    /// 앱 ID·APNs 변경) Firebase가 새로 발급한다 — 재설치 뒤 FCM 서버에서 지워진 캐시 토큰을 계속 보내는 일도 이걸로 막는다.
    private func fetchFCMTokenAndRegister() async {
        guard let token = try? await Messaging.messaging().token() else { return }
        latestFCMToken = token
        registerLatestTokenIfNeeded()
    }

    /// FCM 등록 토큰 수신/갱신 → 보관 + 로그인 상태면 서버 등록.
    func setFCMRegistrationToken(_ token: String?) {
        guard let token else { return }
        latestFCMToken = token
        registerLatestTokenIfNeeded()
    }

    /// 로그인 상태면 `latestFCMToken`을 서버에 등록한다. 이번 세션에서 이미 성공한 토큰이면 건너뛴다.
    /// 로그인 전이면 아무것도 안 한다 — 토큰은 `latestFCMToken`에 남아 있고, 로그인 후 메인 탭 진입이 다시 등록을 부른다.
    /// ⚠️ **요청은 한 번에 하나만 보낸다** — 시작 시 delegate의 캐시 토큰 A와 `token()`이 새로 받은 B를 동시에 보내면
    /// 늦게 끝난 A가 서버의 이 기기 행을 죽은 토큰으로 덮을 수 있다. 진행 중이면 새로 보내지 않고, 끝난 뒤 그새
    /// `latestFCMToken`이 바뀌었으면 최신 값으로 한 번 더 보낸다 → 서버에 마지막으로 남는 값이 항상 최신 토큰이다.
    private func registerLatestTokenIfNeeded() {
        guard let token = latestFCMToken, token != registeredToken, registeringToken == nil,
              isLoggedIn?() == true, let registerDeviceToken
        else { return }

        registeringToken = token
        let generation = sessionGeneration
        let devicePushToken = DevicePushToken(token: token, deviceID: deviceIdentifier())
        Task {
            let succeeded = await registerDeviceToken(devicePushToken)
            guard generation == sessionGeneration else { return }
            registeringToken = nil
            if succeeded { registeredToken = token }
            if latestFCMToken != token { registerLatestTokenIfNeeded() }
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
