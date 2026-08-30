//
//  DeepLinkTests.swift
//  BaseDomain
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import BaseDomain

@Suite
struct DeepLinkTests {

    // MARK: - url

    // ⚠️ 설명에 `://`·`/`를 넣지 않는다 — 테스트 리포터가 `/`를 스위트 구분자로 오인해 이름이 쪼개진다(실측).
    @Test("컬렉션 상세 딥링크의 url은 websoso 스킴, collections host, 그 뒤 id 하나로 이뤄진다")
    func collectionDetailURLFormat() {
        let deepLink = DeepLink.collectionDetail(CollectionID(31))

        #expect(deepLink.url?.absoluteString == "websoso://collections/31")
    }

    // MARK: - init(url:)

    @Test("websoso 스킴에 collections host와 정수 id가 붙은 URL을 파싱하면 그 id의 컬렉션 상세 딥링크가 된다")
    func parseCollectionDetail() {
        let url = makeURL("websoso://collections/31")

        #expect(DeepLink(url: url) == .collectionDetail(CollectionID(31)))
    }

    @Test("딥링크가 만든 url을 다시 파싱하면 원래 딥링크와 같다")
    func roundTrip() throws {
        let original = DeepLink.collectionDetail(CollectionID(7))

        let url = try #require(original.url)

        #expect(DeepLink(url: url) == original)
    }

    @Test("스킴과 host는 대소문자를 가리지 않는다")
    func parseIsCaseInsensitive() {
        let url = makeURL("WEBSOSO://Collections/31")

        #expect(DeepLink(url: url) == .collectionDetail(CollectionID(31)))
    }

    @Test("websoso 스킴이 아니면 nil이다")
    func nilWhenSchemeDiffers() {
        let url = makeURL("https://collections/31")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("모르는 host면 nil이다")
    func nilWhenHostUnknown() {
        let url = makeURL("websoso://novels/31")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("id가 정수가 아니면 nil이다")
    func nilWhenIDNotInteger() {
        let url = makeURL("websoso://collections/abc")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("id가 없으면 nil이다")
    func nilWhenIDMissing() {
        let url = makeURL("websoso://collections")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("id 뒤에 경로가 더 붙어 있으면 nil이다")
    func nilWhenExtraPath() {
        let url = makeURL("websoso://collections/31/extra")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("id가 0이거나 음수면 nil이다 — 서버 발급 ID는 양수뿐이다", arguments: ["0", "-1"])
    func nilWhenIDNotPositive(rawID: String) {
        let url = makeURL("websoso://collections/\(rawID)")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("host가 없으면 nil이다")
    func nilWhenHostEmpty() {
        let url = makeURL("websoso:///31")

        #expect(DeepLink(url: url) == nil)
    }

    // MARK: - kakaoExecutionParameters (카카오톡 공유 카드)

    @Test("컬렉션 상세 딥링크의 카카오 execution params는 collectionId 키에 id 문자열 하나다")
    func kakaoExecutionParametersFormat() {
        let deepLink = DeepLink.collectionDetail(CollectionID(31))

        #expect(deepLink.kakaoExecutionParameters == ["collectionId": "31"])
    }

    @Test("카카오톡이 여는 kakaolink host URL의 collectionId 쿼리를 파싱하면 그 id의 컬렉션 상세 딥링크가 된다")
    func parseKakaoLink() {
        let url = makeURL("kakaoabc123://kakaolink?collectionId=31")

        #expect(DeepLink(url: url) == .collectionDetail(CollectionID(31)))
    }

    @Test("카카오 execution params를 kakaolink URL 쿼리로 되돌려 파싱하면 원래 딥링크와 같다")
    func kakaoRoundTrip() throws {
        let original = DeepLink.collectionDetail(CollectionID(7))
        var components = try #require(URLComponents(string: "kakaoabc123://kakaolink"))
        components.queryItems = original.kakaoExecutionParameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        let url = try #require(components.url)

        #expect(DeepLink(url: url) == original)
    }

    @Test("kakaolink host는 스킴이 무엇이든 파싱한다")
    func parseKakaoLinkIgnoresScheme() {
        let url = makeURL("KAKAOXYZ://KakaoLink?collectionId=31")

        #expect(DeepLink(url: url) == .collectionDetail(CollectionID(31)))
    }

    @Test("kakaolink host인데 collectionId 쿼리가 없으면 nil이다")
    func nilWhenKakaoLinkMissingCollectionID() {
        let url = makeURL("kakaoabc123://kakaolink?novelId=31")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("kakaolink host의 collectionId가 정수가 아니면 nil이다")
    func nilWhenKakaoLinkCollectionIDNotInteger() {
        let url = makeURL("kakaoabc123://kakaolink?collectionId=abc")

        #expect(DeepLink(url: url) == nil)
    }

    @Test("kakaolink host의 collectionId가 0이거나 음수면 nil이다", arguments: ["0", "-1"])
    func nilWhenKakaoLinkCollectionIDNotPositive(rawID: String) {
        let url = makeURL("kakaoabc123://kakaolink?collectionId=\(rawID)")

        #expect(DeepLink(url: url) == nil)
    }
}

private extension DeepLinkTests {
    func makeURL(_ string: String) -> URL {
        URL(string: string)!
    }
}
