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

    public static let scheme = "websoso"

    private enum Host {
        static let collections = "collections"
        /// 카카오톡이 여는 URL의 host. 스킴은 `kakao{APP_KEY}`라 이 모듈은 모른다(아래 `init?(url:)` 참고).
        static let kakaoLink = "kakaolink"
    }

    /// 카카오톡 공유 카드 execution params의 키.
    private enum KakaoParameter {
        static let collectionID = "collectionId"
    }

    /// 공유 시트 등에 실어 보낼 커스텀 스킴 URL.
    public var url: URL? {
        switch self {
        case .collectionDetail(let id):
            return URL(string: "\(Self.scheme)://\(Host.collections)/\(id.value)")
        }
    }

    /// 카카오톡 공유 카드의 `Link.iosExecutionParams`/`androidExecutionParams`에 실을 값 — 받는 앱엔
    /// `kakao{APP_KEY}://kakaolink?collectionId={id}`로 도착하고 `init?(url:)`이 다시 이 값으로 푼다.
    public var kakaoExecutionParameters: [String: String] {
        switch self {
        case .collectionDetail(let id):
            return [KakaoParameter.collectionID: String(id.value)]
        }
    }

    /// 형식에 안 맞으면(모르는 host·양의 정수가 아닌 ID·ID 없음·경로 초과·`websoso` 형식인데 다른 스킴) nil.
    /// 스킴·host는 대소문자를 가리지 않는다(URL 규격). ID는 서버 발급 양수라 `0`·음수는 형식 위반으로 본다 —
    /// 통과시키면 존재할 수 없는 ID로 상세를 열어 404 실패 화면부터 보게 된다.
    public init?(url: URL) {
        guard let host = url.host?.lowercased() else { return nil }

        switch host {
        case Host.collections:
            guard url.scheme?.lowercased() == Self.scheme else { return nil }
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard pathComponents.count == 1, let id = Self.parseID(pathComponents[0]) else { return nil }
            self = .collectionDetail(CollectionID(id))
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

    /// 양의 정수만 ID로 인정한다.
    private static func parseID(_ raw: String) -> Int? {
        guard let id = Int(raw), id > 0 else { return nil }
        return id
    }
}
