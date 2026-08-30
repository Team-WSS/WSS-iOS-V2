//
//  CollectionKakaoShare.swift
//  CollectionFeature
//
//  Created by YunhakLee on 8/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UIKit

import KakaoSDKShare
import KakaoSDKTemplate

import BaseDomain
import CollectionDomain

/// 컬렉션 상세 "공유하기"의 카카오 공유 카드(#228) — 제목·설명·대표 표지 + "앱에서 보기" 버튼.
///
/// 받는 사람이 버튼을 누르면 카카오톡이 우리 앱을 `kakao{APP_KEY}://kakaolink?collectionId={id}`로 열고
/// (`DeepLink.kakaoExecutionParameters`), 앱이 없으면 카카오가 App Store로 보낸다(카카오 콘솔의 iOS 플랫폼에
/// Bundle ID·App Store ID가 등록돼 있어야 함). 커스텀 스킴(`websoso://`)을 텍스트로 보내면 카카오톡이
/// 링크로 인식하지 않아 수신자가 진입할 수 없었던 문제의 해법이다.
///
/// 보내는 경로는 둘이고 카드는 같다: 카카오톡이 있으면 **카카오톡 앱**(받는 사람 선택 화면), 없으면
/// **카카오 웹 공유**(Safari — SDK 권장 폴백). 시스템 공유 시트는 쓰지 않는다 — 거기로 나가는 커스텀 스킴
/// 링크는 어디서도 탭이 안 돼 무의미했다(폐기 이력은 모듈 CLAUDE.md).
///
/// `KakaoSDK.initSDK(appKey:)`가 앱 진입점(App·Demo)에서 먼저 불려 있어야 하고, 호출 앱의 `Info.plist`에
/// `CFBundleShortVersionString`이 있어야 한다(SDK가 필수 파라미터 `appver`로 보냄 — `App/CLAUDE.md`).
@MainActor
enum CollectionKakaoShare {

    enum Failure: Error {
        /// SDK가 결과도 에러도 없이 완료를 알린 경우 — 정상 경로에선 안 온다.
        case emptyResult
        /// 웹 공유 URL 조립 실패(템플릿 직렬화 실패) — 정상 경로에선 안 온다.
        case webShareURLUnavailable
        /// 카카오톡/Safari 열기 자체가 거부된 경우(`UIApplication.open`이 false) — 삼키면 버튼을 눌러도
        /// 아무 일이 없는 것처럼 보이므로 토스트로 알린다.
        case openFailed
    }

    /// 카드를 만들어 카카오톡(받는 사람 선택 화면) 또는 카카오 웹 공유(Safari)를 연다. 열리면 성공이고,
    /// 실제 전송 여부는 그 안에서 사용자가 정한다. 템플릿 검증(서버)·앱 열기 실패는 throw.
    static func share(_ detail: CollectionDetail, coverImageURL: URL?) async throws {
        let template = makeTemplate(detail, coverImageURL: coverImageURL)
        let url = if isKakaoTalkAvailable {
            try await makeKakaoTalkURL(template)
        } else {
            try makeWebShareURL(template)
        }
        guard await UIApplication.shared.open(url) else {
            throw Failure.openFailed
        }
    }

    /// 카카오톡이 설치돼 있어 앱으로 보낼 수 있는지. `Info.plist`의 `LSApplicationQueriesSchemes`에
    /// `kakaolink`가 있어야 true가 나온다(없으면 설치돼 있어도 항상 false → 웹 공유로만 나간다).
    private static var isKakaoTalkAvailable: Bool {
        ShareApi.isKakaoTalkSharingAvailable()
    }

    /// 템플릿을 서버에서 검증받고 카카오톡을 열 `kakaolink://send?…` URL을 받는다.
    private static func makeKakaoTalkURL(_ template: FeedTemplate) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ShareApi.shared.shareDefault(templatable: template) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result.url)
                } else {
                    continuation.resume(throwing: Failure.emptyResult)
                }
            }
        }
    }

    /// 카카오 웹 공유(`sharer.kakao.com`) URL — 서버 검증 없이 로컬에서 조립된다.
    private static func makeWebShareURL(_ template: FeedTemplate) throws -> URL {
        guard let url = ShareApi.shared.makeDefaultUrl(templatable: template) else {
            throw Failure.webShareURLUnavailable
        }
        return url
    }

    private static func makeTemplate(_ detail: CollectionDetail, coverImageURL: URL?) -> FeedTemplate {
        let deepLink = DeepLink.collectionDetail(detail.id)
        let link = KakaoSDKTemplate.Link(
            androidExecutionParams: deepLink.kakaoExecutionParameters,
            iosExecutionParams: deepLink.kakaoExecutionParameters
        )
        // 표지(`imageUrl`)는 옵셔널 — 대표 작품에 표지가 없으면 이미지 없는 카드로 나간다.
        let content = Content(
            title: detail.name,
            imageUrl: coverImageURL,
            description: detail.description ?? "작품 \(detail.novelCount)개",
            link: link
        )
        return FeedTemplate(
            content: content,
            buttons: [KakaoSDKTemplate.Button(title: "앱에서 보기", link: link)]
        )
    }
}
