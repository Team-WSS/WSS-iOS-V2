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
}

private extension DeepLinkTests {
    func makeURL(_ string: String) -> URL {
        URL(string: string)!
    }
}
