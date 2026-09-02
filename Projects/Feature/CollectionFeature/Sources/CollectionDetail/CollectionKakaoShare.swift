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

/// 컬렉션 상세 "공유하기"의 카카오 공유 카드(#228) — 제목·설명·표지 + "앱에서 보기" 버튼.
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
/// **카드는 작품 수만큼 표지가 붙는다** — **Kakao Developers 콘솔의 사용자 정의 템플릿 3종**(표지
/// 1/2/3장 전용, 2026-09-01 생성)을 작품 수로 골라 쓴다. 처음엔 표지 3장짜리 템플릿 하나로 2개는
/// `image3` 인자를 생략해 커버하려 했으나 **Kakao 커스텀 템플릿은 이미지 슬롯 개수가 고정이라 가변
/// 개수를 못 받는다는 게 실기기 실측으로 확인됐다**(2026-09-01) — 그래서 작품 1/2/3개 이상 각각
/// 전용 템플릿을 따로 만들고, `share(multiThumbnailTemplateID1/2/3:)` 세 파라미터로 받아 `detail.novelCount`
/// (3 이상은 3장 템플릿으로 고정)에 맞는 것만 골라 쓴다(`multiThumbnailTemplate(for:...)`). 셋 중 그 작품
/// 수에 해당하는 ID가 `0`(미설정)이면 그 작품 수만 기존 기본 템플릿(`FeedTemplate`, 표지 1장)으로
/// 폴백한다 — 나머지 두 작품 수는 영향받지 않는다. ⚠️ **세 템플릿의 표지 인자 키는 대소문자가 서로
/// 다르다**(1/2장 템플릿 `IMAGE1`/`IMAGE2`, 3장 템플릿 `image1`/`image2`/`image3`, 2026-09-01 확인) —
/// 아래 `MultiThumbnailTemplate` 참고.
/// 이 커스텀 템플릿들은 기본 카드와 달리 "앱에서 보기" 버튼 컴포넌트 자체가 없다(계획에 없음, 사용자 확정) —
/// 딥링크 인자를 넘길 자리가 없다는 뜻이다.
///
/// **템플릿 ID는 이 파일에 하드코딩하지 않는다** — 개인 Kakao 콘솔에 만든 값이라 커밋되는 Swift
/// 소스에 두면 다른 개발자와도 공유돼버린다. 호출부(`share(_:coverImageURL:multiThumbnailTemplateID1:2:3:)`)가
/// 파라미터로 받고, App/Demo가 gitignore된 `Config/*.xcconfig`(`KAKAO_COLLECTION_SHARE_TEMPLATE_ID_1/2/3`) →
/// `NetworkingConfig.kakaoCollectionShareTemplateID1/2/3`(BaseData)로 읽어 넘긴다.
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

    /// 사용자 정의 템플릿이 얹을 수 있는 표지 최대 장수(= 3장 템플릿이 커버하는 상한, 4개 이상도 이 템플릿으로 묶인다).
    private static let maxThumbnailCount = 3

    /// 카드를 만들어 카카오톡(받는 사람 선택 화면) 또는 카카오 웹 공유(Safari)를 연다. 열리면 성공이고,
    /// 실제 전송 여부는 그 안에서 사용자가 정한다. 템플릿 검증(서버)·앱 열기 실패는 throw.
    ///
    /// - Parameters:
    ///   - multiThumbnailTemplateID1/2/3: Kakao Developers 콘솔의 표지 1/2/3장 전용 사용자 정의 템플릿
    ///     ID 3종(`NetworkingConfig.kakaoCollectionShareTemplateID1/2/3`, 위 헤더 주석 참고) — Kakao
    ///     커스텀 템플릿은 이미지 슬롯 개수가 고정이라 작품 수마다 별도 템플릿이 필요하다. `detail.novelCount`가
    ///     3 이상이면 무조건 3번 템플릿(최대 3장까지만 얹음). 해당 개수의 ID가 `0`이면(그 템플릿을 아직
    ///     콘솔에 안 만들었거나 Config 미설정) 그 작품 수만 기본 카드(표지 1장)로 폴백한다 — 미설정
    ///     상태에서 공유 자체가 막히는 걸 피하려는 의도. 인자 구성은 아래 `multiThumbnailArgs` 참고.
    static func share(
        _ detail: CollectionDetail,
        coverImageURL: URL?,
        multiThumbnailTemplateID1: Int64,
        multiThumbnailTemplateID2: Int64,
        multiThumbnailTemplateID3: Int64
    ) async throws {
        let template = multiThumbnailTemplate(
            for: detail.novelCount,
            id1: multiThumbnailTemplateID1,
            id2: multiThumbnailTemplateID2,
            id3: multiThumbnailTemplateID3
        )
        let url = if let template {
            try await makeMultiThumbnailURL(detail, template: template)
        } else if isKakaoTalkAvailable {
            try await makeKakaoTalkURL(makeTemplate(detail, coverImageURL: coverImageURL))
        } else {
            try makeWebShareURL(makeTemplate(detail, coverImageURL: coverImageURL))
        }
        guard await UIApplication.shared.open(url) else {
            throw Failure.openFailed
        }
    }

    /// 사용자 정의 템플릿 ID + 그 템플릿의 표지 인자 키 접두어(대소문자) 묶음. 세 템플릿을 **서로 다른
    /// 시점에 콘솔에서 따로 만들다 보니 표지 인자 키 대소문자가 템플릿마다 다르다**(2026-09-01 확인 —
    /// 표지 1/2장 템플릿은 `IMAGE1`/`IMAGE2`, 3장 템플릿은 `image1`/`image2`/`image3`). 대소문자가
    /// 하나라도 어긋나면 그 컴포넌트가 "정의 안 된 키"로 무시돼 이미지가 조용히 빠지니, 템플릿 선택과
    /// 이 접두어 선택을 분리하지 말고 항상 짝으로 다룰 것.
    private struct MultiThumbnailTemplate {
        let id: Int64
        let imageArgKeyPrefix: String
    }

    /// 작품 수에 맞는 커스텀 템플릿(+표지 인자 키 접두어)을 고른다 — 1개는 `id1`, 2개는 `id2`, 3개
    /// 이상은 `id3`(표지는 `maxThumbnailCount`까지만). 골라진 ID가 `0`(미설정)이거나 작품이 0개(정상
    /// 경로에선 안 옴 — 도메인상 컬렉션은 항상 작품 1개 이상)면 `nil`을 돌려줘 호출부가 기본 카드로
    /// 폴백하게 한다.
    private static func multiThumbnailTemplate(for novelCount: Int, id1: Int64, id2: Int64, id3: Int64) -> MultiThumbnailTemplate? {
        let id: Int64
        let imageArgKeyPrefix: String
        switch novelCount {
        case 1: id = id1; imageArgKeyPrefix = "IMAGE"
        case 2: id = id2; imageArgKeyPrefix = "IMAGE"
        case 3...: id = id3; imageArgKeyPrefix = "IMAGE"
        default: return nil
        }
        guard id != 0 else { return nil }
        return MultiThumbnailTemplate(id: id, imageArgKeyPrefix: imageArgKeyPrefix)
    }

    /// 카카오톡이 설치돼 있어 앱으로 보낼 수 있는지. `Info.plist`의 `LSApplicationQueriesSchemes`에
    /// `kakaolink`가 있어야 true가 나온다(없으면 설치돼 있어도 항상 false → 웹 공유로만 나간다).
    private static var isKakaoTalkAvailable: Bool {
        ShareApi.isKakaoTalkSharingAvailable()
    }

    // MARK: - 기본 카드 (표지 1장)

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

    // MARK: - 표지 1~3장 카드 (사용자 정의 템플릿)

    /// 사용자 정의 템플릿을 서버에서 검증받아(카카오톡) 또는 로컬 조립해(웹 공유) URL을 받는다.
    /// 호출부(`share`)가 `id != 0`을 이미 확인한 뒤에만 부른다.
    private static func makeMultiThumbnailURL(_ detail: CollectionDetail, template: MultiThumbnailTemplate) async throws -> URL {
        let args = await multiThumbnailArgs(detail, imageArgKeyPrefix: template.imageArgKeyPrefix)
        if isKakaoTalkAvailable {
            return try await withCheckedThrowingContinuation { continuation in
                ShareApi.shared.shareCustom(templateId: template.id, templateArgs: args) { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let result {
                        continuation.resume(returning: result.url)
                    } else {
                        continuation.resume(throwing: Failure.emptyResult)
                    }
                }
            }
        } else {
            guard let url = ShareApi.shared.makeCustomUrl(templateId: template.id, templateArgs: args) else {
                throw Failure.webShareURLUnavailable
            }
            return url
        }
    }

    /// 콘솔 템플릿의 `${KEY}` 자리에 들어갈 인자 — 콘솔에 등록된 키 이름과 대소문자까지 정확히 맞춰야
    /// 한다. `NICKNAME`/`TITLE`/`DESCRIPTION`은 세 템플릿 공통이지만, **표지 인자는 템플릿마다 대소문자가
    /// 다르다**(`imageArgKeyPrefix` 파라미터 — 표지 1/2장 템플릿은 `IMAGE1`/`IMAGE2`, 3장 템플릿은
    /// `image1`/`image2`/`image3`, 위 `MultiThumbnailTemplate` 주석 참고). **`DESCRIPTION`은 아직 콘솔
    /// 템플릿에 텍스트 컴포넌트로 안 만들어져 있다**(2026-09-01 — 사용자가 "일단 진행"으로 확정한 키
    /// 이름만 먼저 코드에 반영, 콘솔 쪽 컴포넌트 추가는 남은 일). 콘솔에 없는 키를 보내면 무시되는지
    /// 검증에서 거부되는지 아직 실기기/웹공유로 확인 안 됨 — 컴포넌트를 추가하기 전까지 공유가 막힌다면
    /// 이 인자부터 의심할 것.
    ///
    /// ⚠️ **표지 URL은 그대로 못 보낸다 — 카카오에 먼저 스크랩(`imageScrap`)해 카카오 CDN URL로 바꿔야
    /// 한다.** 이 템플릿의 표지 슬롯은 카카오 내부적으로 "썸네일 리스트" 컴포넌트라, 원본(네이버 등
    /// 외부 CDN) URL을 그대로 넣으면 앱에 `NONE_KAGE_IMAGE_SUPPORTED` 권한이 없어 **"삭제되거나 변경될
    /// 수 있다"는 `warningMsg`와 함께 그 이미지가 조용히 빠진 채 공유가 "성공"한다**(2026-09-01 실측 —
    /// 요청은 성공(`error`도 `emptyResult`도 아님)했는데 이미지가 안 붙어서 처음엔 원인이 안 보였다).
    /// 기본 카드(`makeTemplate`)의 `content.imageUrl`은 같은 제약이 없다 — 이 제약은 다중 이미지
    /// 컴포넌트에서만 걸린다.
    /// 표지는 `detail.novels` 순서로 최대 `maxThumbnailCount`장 — 호출부(`multiThumbnailTemplate(for:...)`)가
    /// 이미 그 작품 수의 슬롯 개수와 정확히 맞는 템플릿을 골라뒀으므로, `thumbnails`의 개수도 항상 그
    /// 템플릿의 이미지 슬롯 개수와 일치한다(작품 2개 → `IMAGE1`/`IMAGE2`만, 3번째 키 자체가 없음).
    /// ⚠️ **슬롯이 고정(선택 아님, 위 헤더 주석의 2026-09-01 실측)이라 스크랩 실패로 키가 빠지면 그 슬롯이
    /// 통째로 비어 서버 템플릿 검증에서 거부될 수 있다** — 표지 하나가 일시적으로 안 불러와져도 조용히
    /// 넘어가던 예전 가정(옵션 슬롯)은 더 이상 유효하지 않다. 지금은 최선을 다해 스크랩하고 실패 시
    /// 키를 생략하는 동작만 남아 있고, 실패를 별도로 감지해 폴백하는 로직은 아직 없다 — 스크랩 실패로
    /// 공유가 막히는 사례가 실측되면 이 지점부터 볼 것.
    ///
    /// 이 템플릿은 버튼 컴포넌트가 없어 `collectionId` 딥링크 인자를 안 채운다(위 헤더 주석 참고) —
    /// 기본 카드의 `DeepLink.kakaoExecutionParameters`와 달리 `args`엔 텍스트·표지 키만 채운다.
    private static func multiThumbnailArgs(_ detail: CollectionDetail, imageArgKeyPrefix: String) async -> [String: String] {
        var args: [String: String] = [
            "NICKNAME": detail.owner.nickname,
            "TITLE": detail.name,
            "DESCRIPTION": detail.description ?? "작품 \(detail.novelCount)개"
        ]
        let thumbnails = Array(detail.novels.prefix(maxThumbnailCount).map(\.thumbnailImage))
        let scrapedThumbnails = await withTaskGroup(of: (Int, URL?).self) { group in
            for (index, thumbnailURL) in thumbnails.enumerated() {
                group.addTask {
                    guard let thumbnailURL else { return (index, nil) }
                    return (index, try? await scrapImage(thumbnailURL))
                }
            }
            var results: [Int: URL] = [:]
            for await (index, scrapedURL) in group {
                results[index] = scrapedURL
            }
            return results
        }
        for (index, scrapedURL) in scrapedThumbnails {
            args["\(imageArgKeyPrefix)\(index + 1)"] = scrapedURL.absoluteString
        }
        return args
    }

    /// 표지 원본 URL을 카카오 CDN에 스크랩해 다중 이미지 컴포넌트에 넣을 수 있는 URL로 바꾼다
    /// (`multiThumbnailArgs` 참고 — 원본 URL을 그대로 쓰면 조용히 빠진다).
    private static func scrapImage(_ url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ShareApi.shared.imageScrap(imageUrl: url) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result.infos.original.url)
                } else {
                    continuation.resume(throwing: Failure.emptyResult)
                }
            }
        }
    }
}
