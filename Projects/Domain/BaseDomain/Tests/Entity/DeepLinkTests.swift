//
//  DeepLinkTests.swift
//  BaseDomain
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain

@Suite("딥링크")
struct DeepLinkTests {

    // MARK: - 링크 만들기

    @Test("컬렉션 상세 링크는 websoso 스킴, collections 주소, id 하나로 만든다")
    func collectionDetailMakesURL() {
        let link = DeepLink.collectionDetail(CollectionID(22))

        #expect(link.url == URL(string: "websoso://collections/22"))
    }

    @Test(
        "작품·피드·알림 상세는 링크를 만들지 않는다",
        arguments: [
            DeepLink.novelDetail(NovelID(7)),               // 푸시로 받기만 한다
            .feedDetail(FeedID(7)),                         // 푸시로 받기만 한다
            .notificationDetail(NotificationID(7))          // 푸시로 받기만 한다
        ]
    )
    func pushOnlyLinksMakeNoURL(link: DeepLink) {
        let url = link.url

        #expect(url == nil)
    }

    @Test("컬렉션 상세의 카카오 공유 값에는 컬렉션 id 하나만 담는다")
    func collectionDetailMakesKakaoParameters() {
        let link = DeepLink.collectionDetail(CollectionID(22))

        #expect(link.kakaoExecutionParameters == ["collectionId": "22"])
    }

    @Test(
        "작품·피드·알림 상세는 카카오 공유 값이 비어 있다",
        arguments: [
            DeepLink.novelDetail(NovelID(7)),               // 푸시로 받기만 한다
            .feedDetail(FeedID(7)),                         // 푸시로 받기만 한다
            .notificationDetail(NotificationID(7))          // 푸시로 받기만 한다
        ]
    )
    func pushOnlyLinksMakeNoKakaoParameters(link: DeepLink) {
        let parameters = link.kakaoExecutionParameters

        #expect(parameters.isEmpty)
    }

    // MARK: - 링크 읽기

    @Test(
        "주소가 화면 종류를, 경로의 숫자가 id를 정한다",
        arguments: [
            ("websoso://collections/22", DeepLink.collectionDetail(CollectionID(22))),     // 컬렉션 상세
            ("websoso://novels/22", .novelDetail(NovelID(22))),                            // 작품 상세
            ("websoso://feeds/22", .feedDetail(FeedID(22))),                               // 피드 상세
            ("websoso://notifications/22", .notificationDetail(NotificationID(22)))        // 알림 상세
        ]
    )
    func hostAndPathDecideLink(rawURL: String, expected: DeepLink) {
        let link = DeepLink(url: makeURL(rawURL))

        #expect(link == expected)
    }

    @Test("스킴과 주소는 대소문자를 가리지 않는다")
    func schemeAndHostIgnoreCase() {
        let link = DeepLink(url: makeURL("WEBSOSO://Collections/22"))

        #expect(link == .collectionDetail(CollectionID(22)))
    }

    @Test("websoso가 아닌 스킴은 읽지 않는다")
    func otherSchemeIsIgnored() {
        let link = DeepLink(url: makeURL("https://collections/22"))

        #expect(link == nil)
    }

    @Test(
        "모르는 주소나 주소가 없는 링크는 읽지 않는다",
        arguments: [
            "websoso://comments/22",  // 모르는 주소
            "websoso:///22"           // 주소가 없다
        ]
    )
    func unknownOrMissingHostIsIgnored(rawURL: String) {
        let link = DeepLink(url: makeURL(rawURL))

        #expect(link == nil)
    }

    @Test(
        "id가 양의 정수가 아니면 읽지 않는다",
        arguments: [
            "abc",  // 숫자가 아니다
            "0",    // 서버가 주는 id는 1부터다
            "-1"    // 음수다
        ]
    )
    func nonPositiveIDIsIgnored(rawID: String) {
        let link = DeepLink(url: makeURL("websoso://collections/\(rawID)"))

        #expect(link == nil)
    }

    @Test(
        "id가 없거나 경로가 더 붙어 있으면 읽지 않는다",
        arguments: [
            "websoso://collections",           // id가 없다
            "websoso://collections/22/extra"   // id 뒤에 경로가 더 있다
        ]
    )
    func missingIDOrExtraPathIsIgnored(rawURL: String) {
        let link = DeepLink(url: makeURL(rawURL))

        #expect(link == nil)
    }

    // MARK: - 카카오톡 링크 읽기

    @Test("카카오톡 링크의 컬렉션 id를 읽어 컬렉션 상세로 간다")
    func kakaoLinkOpensCollection() {
        let link = DeepLink(url: makeURL("kakao1234abcd://kakaolink?collectionId=22"))

        #expect(link == .collectionDetail(CollectionID(22)))
    }

    @Test("카카오톡 링크는 스킴이 무엇이든 읽는다")
    func kakaoLinkIgnoresScheme() {
        // 스킴의 앱 키는 앱 설정에만 있어 이 모듈은 모른다. 등록된 스킴만 앱에 오므로 검사하지 않는다.
        let link = DeepLink(url: makeURL("anything://kakaolink?collectionId=22"))

        #expect(link == .collectionDetail(CollectionID(22)))
    }

    @Test(
        "카카오톡 링크에 컬렉션 id가 없거나 양의 정수가 아니면 읽지 않는다",
        arguments: [
            "kakao1234abcd://kakaolink",                     // 컬렉션 id가 없다
            "kakao1234abcd://kakaolink?collectionId=abc",    // 숫자가 아니다
            "kakao1234abcd://kakaolink?collectionId=0",      // 서버가 주는 id는 1부터다
            "kakao1234abcd://kakaolink?collectionId=-1"      // 음수다
        ]
    )
    func kakaoLinkWithoutValidIDIsIgnored(rawURL: String) {
        let link = DeepLink(url: makeURL(rawURL))

        #expect(link == nil)
    }

    // MARK: - 푸시 알림 읽기

    @Test(
        "푸시의 화면 종류에 맞는 id로 상세를 연다",
        arguments: [
            // 작품 상세. 서버는 다른 id를 빈 값으로 함께 보내기도 한다.
            (["view": "novelDetail", "novelId": "12345", "feedId": ""], DeepLink.novelDetail(NovelID(12345))),
            // 피드 상세
            (["view": "feedDetail", "feedId": "42", "novelId": ""], .feedDetail(FeedID(42))),
            // 알림 상세(공지). 실제 공지 푸시는 알림 id만 있고 작품 id 키는 없다(#243).
            (["view": "notificationDetail", "notificationId": "3853"], .notificationDetail(NotificationID(3853)))
        ]
    )
    func pushOpensDetailForView(payload: [String: String], expected: DeepLink) {
        let link = DeepLink.fromNotificationPayload(payload)

        #expect(link == expected)
    }

    @Test(
        "모르는 화면 종류이거나 화면 종류가 없으면 읽지 않는다",
        arguments: [
            ["view": "commentDetail", "novelId": "7"],  // 모르는 화면 종류
            ["novelId": "7"]                            // 화면 종류가 없다
        ]
    )
    func unknownOrMissingViewIsIgnored(payload: [String: String]) {
        let link = DeepLink.fromNotificationPayload(payload)

        #expect(link == nil)
    }

    @Test(
        "화면 종류에 맞는 id가 없거나 양의 정수가 아니면 읽지 않는다",
        arguments: [
            ["view": "notificationDetail", "novelId": "7"],  // 화면 종류와 다른 id만 있다
            ["view": "novelDetail", "novelId": ""],           // id가 비었다
            ["view": "novelDetail", "novelId": "abc"],        // 숫자가 아니다
            ["view": "novelDetail", "novelId": "0"],          // 서버가 주는 id는 1부터다
            ["view": "novelDetail", "novelId": "-1"]          // 음수다
        ]
    )
    func pushWithoutValidIDIsIgnored(payload: [String: String]) {
        let link = DeepLink.fromNotificationPayload(payload)

        #expect(link == nil)
    }

    // MARK: - Helpers

    private func makeURL(_ raw: String) -> URL {
        URL(string: raw)!
    }
}
