//
//  DeepLink.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱 밖(공유 링크 등)에서 특정 화면으로 바로 들어오는 딥링크 — `websoso://` 커스텀 스킴.
///
/// 만드는 쪽(Feature의 공유 버튼)과 받는 쪽(App의 `onOpenURL`)이 같은 규칙을 봐야 어긋나지 않으므로
/// URL 생성(`url`)과 파싱(`init?(url:)`)을 한 타입에 둔다. Feature는 Data를 import할 수 없어
/// (`App → Feature → Domain ← Data`) `AppURL`과 같은 이유로 BaseDomain에 있다.
///
/// 형식: `websoso://<host>/<id>` — host가 화면 종류, 첫 path 요소가 정수 ID. 스킴 등록은
/// App `Info.plist`의 `CFBundleURLTypes`(#228).
public enum DeepLink: Hashable, Sendable {
    /// 컬렉션 상세 — `websoso://collections/{collectionId}`.
    case collectionDetail(CollectionID)

    public static let scheme = "websoso"

    private enum Host {
        static let collections = "collections"
    }

    /// 공유 시트 등에 실어 보낼 URL.
    public var url: URL? {
        switch self {
        case .collectionDetail(let id):
            return URL(string: "\(Self.scheme)://\(Host.collections)/\(id.value)")
        }
    }

    /// 형식에 안 맞으면(다른 스킴·모르는 host·정수가 아닌 ID·ID 없음·경로 초과) nil.
    /// 스킴·host는 대소문자를 가리지 않는다(URL 규격).
    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              let host = url.host?.lowercased() else { return nil }
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case Host.collections:
            guard pathComponents.count == 1, let rawID = Int(pathComponents[0]) else { return nil }
            self = .collectionDetail(CollectionID(rawID))
        default:
            return nil
        }
    }
}
