//
//  AppDelegate.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UIKit
import UserNotifications

import FirebaseCore
import FirebaseMessaging

/// 순수 SwiftUI 앱(`WSSIOSV2App`)에 원격 알림용 UIKit 진입점을 붙이는 어댑터(#243).
/// `@UIApplicationDelegateAdaptor`로 연결한다. 시스템 콜백을 받아 `PushNotificationCenter`(FCM 허브)로 넘길 뿐,
/// 상태·정책은 두지 않는다. Firebase method swizzling은 끈다(`Info.plist`의 `FirebaseAppDelegateProxyEnabled=NO`) —
/// SwiftUI 어댑터 환경에서 자동 프록시가 불안정해, APNs 토큰을 우리가 직접 `Messaging`에 넘긴다(V1과 동일).
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 빌드 구성별 올바른 GoogleService-Info를 **실제로 그 옵션으로** configure한다
        // (V1은 옵션을 만들고 버린 뒤 인자 없는 configure를 불러 항상 운영 plist만 썼다 — 그 버그를 물려받지 않는다).
        // plist가 없으면(gitignore돼 로컬에 안 받은 환경·CI) Firebase를 조용히 비활성화한다 — 크래시 대신.
        guard let options = Self.firebaseOptions() else {
            NSLog("[Push] GoogleService-Info plist가 번들에 없어 Firebase/FCM을 비활성화합니다.")
            return true
        }
        FirebaseApp.configure(options: options)

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    /// 빌드 구성에 맞는 GoogleService-Info를 로드한다(Debug=디버그 앱 `kr.websoso.debug2`, Release=운영 `kr.websoso`).
    private static func firebaseOptions() -> FirebaseOptions? {
        #if DEBUG
        let resource = "GoogleService-Info-Debug"
        #else
        let resource = "GoogleService-Info"
        #endif
        guard let path = Bundle.main.path(forResource: resource, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            return nil
        }
        return options
    }

    // MARK: - APNs 등록 콜백

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        MainActor.assumeIsolated {
            PushNotificationCenter.shared.setAPNSToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // 등록 실패(시뮬레이터·망 문제 등)는 로깅만 — 앱 흐름을 막지 않는다.
        NSLog("[Push] APNs 등록 실패: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate (FCM 토큰 수신)

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            PushNotificationCenter.shared.setFCMRegistrationToken(fcmToken)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate (표시·탭)

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 포그라운드 수신 시에도 배너/사운드/뱃지를 표시한다(V1 parity).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림 탭 → payload(`view`/`novelId`/`feedId`)를 딥링크로 풀어 해당 화면(작품/피드 상세)으로 이동한다(#243).
    /// 라우팅은 `PushNotificationCenter`가 앱의 `pendingDeepLink` 채널로 넘겨 처리한다(콜드 스타트도 보관→flush).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        MainActor.assumeIsolated {
            PushNotificationCenter.shared.handleNotificationTap(userInfo: userInfo)
        }
        completionHandler()
    }
}
