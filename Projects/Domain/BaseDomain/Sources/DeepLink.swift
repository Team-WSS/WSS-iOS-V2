//
//  DeepLink.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱 밖(공유 링크 등)에서 특정 화면으로 바로 들어오는 딥링크.
///
/// 만드는 쪽(Feature의 공유 버튼)과 받는 쪽(App의 `onOpenURL`)이 같은 규칙을 봐야 어긋나지 않으므로
/// URL 생성과 파싱(`init?(url:)`)을 한 타입에 둔다. Feature는 Data를 import할 수 없어
/// (`App → Feature → Domain ← Data`) `AppURL`과 같은 이유로 BaseDomain에 있다.
///
/// 받는 형식은 둘이고 파싱 결과는 같다(#228):
/// - `websoso://<host>/<id>` — 커스텀 스킴(`url`). host가 화면 종류, 첫 path 요소가 정수 ID. 스킴 등록은
///   App `Info.plist`의 `CFBundleURLTypes`.
/// - `kakao{APP_KEY}://kakaolink?<key>=<value>…` — 카카오톡 공유 카드의 "앱에서 보기"가 앱을 열 때
///   카카오톡이 만드는 URL. 쿼리는 카드에 실어 보낸 `kakaoExecutionParameters`가 그대로 돌아온 것이다.
public enum DeepLink: Hashable, Sendable {
    /// 컬렉션 상세 — `websoso://collections/{collectionId}` / 카카오 `collectionId={collectionId}`.
    case collectionDetail(CollectionID)
    /// 작품 상세 — 푸시 알림(`view=novelDetail`, #243) / 테스트용 `websoso://novels/{novelId}`.
    case novelDetail(NovelID)
    /// 피드 상세 — 푸시 알림(`view=feedDetail`, #243) / 테스트용 `websoso://feeds/{feedId}`.
    case feedDetail(FeedID)

    public static let scheme = "websoso"

    private enum Host {
        static let collections = "collections"
        static let novels = "novels"
        static let feeds = "feeds"
        /// 카카오톡이 여는 URL의 host. 스킴은 `kakao{APP_KEY}`라 이 모듈은 모른다(아래 `init?(url:)` 참고).
        static let kakaoLink = "kakaolink"
    }

    /// 카카오톡 공유 카드 execution params의 키.
    private enum KakaoParameter {
        static let collectionID = "collectionId"
    }

    /// 푸시 알림 payload(FCM userInfo) 키 — 서버 계약(#243, V1과 동일 키를 잇는다).
    private enum NotificationKey {
        static let view = "view"
        static let novelID = "novelId"
        static let feedID = "feedId"
    }

    /// 푸시 payload의 `view` 값 → 화면 종류. 서버가 `view`에 맞는 id만 채워 보낸다(나머진 빈 문자열).
    private enum NotificationView {
        static let novelDetail = "novelDetail"
        static let feedDetail = "feedDetail"
    }

    /// 공유 시트 등에 실어 보낼 커스텀 스킴 URL.
    public var url: URL? {
        switch self {
        case .collectionDetail(let id):
            return URL(string: "\(Self.scheme)://\(Host.collections)/\(id.value)")
        case .novelDetail, .feedDetail:
            // 푸시로 **받는** 딥링크라 outbound(공유) URL 생성 대상이 아니다 — 수신 파싱만 지원한다.
            return nil
        }
    }

    /// 카카오톡 공유 카드의 `Link.iosExecutionParams`/`androidExecutionParams`에 실을 값 — 받는 앱엔
    /// `kakao{APP_KEY}://kakaolink?collectionId={id}`로 도착하고 `init?(url:)`이 다시 이 값으로 푼다.
    public var kakaoExecutionParameters: [String: String] {
        switch self {
        case .collectionDetail(let id):
            return [KakaoParameter.collectionID: String(id.value)]
        case .novelDetail, .feedDetail:
            // 카카오 공유 카드는 컬렉션 전용 — 작품/피드 딥링크는 푸시로만 온다.
            return [:]
        }
    }

    /// 형식에 안 맞으면(모르는 host·양의 정수가 아닌 ID·ID 없음·경로 초과·`websoso` 형식인데 다른 스킴) nil.
    /// 스킴·host는 대소문자를 가리지 않는다(URL 규격). ID는 서버 발급 양수라 `0`·음수는 형식 위반으로 본다 —
    /// 통과시키면 존재할 수 없는 ID로 상세를 열어 404 실패 화면부터 보게 된다.
    public init?(url: URL) {
        guard let host = url.host?.lowercased() else { return nil }

        switch host {
        case Host.collections:
            guard let id = Self.singlePathID(from: url) else { return nil }
            self = .collectionDetail(CollectionID(id))
        case Host.novels:
            guard let id = Self.singlePathID(from: url) else { return nil }
            self = .novelDetail(NovelID(id))
        case Host.feeds:
            guard let id = Self.singlePathID(from: url) else { return nil }
            self = .feedDetail(FeedID(id))
        case Host.kakaoLink:
            // 스킴(`kakao{APP_KEY}`)은 검사하지 않는다 — 앱 키는 App 설정(Info.plist)에만 있고, 어차피
            // `CFBundleURLTypes`에 등록된 스킴만 앱에 도착한다.
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard let rawID = queryItems.first(where: { $0.name == KakaoParameter.collectionID })?.value,
                  let id = Self.parseID(rawID) else { return nil }
            self = .collectionDetail(CollectionID(id))
        default:
            return nil
        }
    }

    /// `websoso://<host>/<id>` 형식에서 단일 경로 ID를 뽑는다 — 스킴이 `websoso`이고 경로 요소가 정확히
    /// 하나(양의 정수)일 때만 통과. collections/novels/feeds가 같은 형식을 공유한다.
    private static func singlePathID(from url: URL) -> Int? {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count == 1 else { return nil }
        return parseID(pathComponents[0])
    }

    /// 양의 정수만 ID로 인정한다.
    private static func parseID(_ raw: String) -> Int? {
        guard let id = Int(raw), id > 0 else { return nil }
        return id
    }

    /// 푸시 알림 payload(FCM userInfo, #243)에서 딥링크를 만든다. `view`가 화면 종류이고 그에 맞는 id만
    /// 서버가 채워 보낸다(나머진 빈 문자열). id는 문자열이며 양의 정수만 인정한다(URL 파싱과 동일 정책).
    /// 모르는 `view`·유효하지 않은 id면 nil(무시).
    public static func fromNotificationPayload(_ payload: [String: String]) -> DeepLink? {
        guard let view = payload[NotificationKey.view] else { return nil }

        switch view {
        case NotificationView.novelDetail:
            guard let id = parseID(payload[NotificationKey.novelID] ?? "") else { return nil }
            return .novelDetail(NovelID(id))
        case NotificationView.feedDetail:
            guard let id = parseID(payload[NotificationKey.feedID] ?? "") else { return nil }
            return .feedDetail(FeedID(id))
        default:
            return nil
        }
    }
}
