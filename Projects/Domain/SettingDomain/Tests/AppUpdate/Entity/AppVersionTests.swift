//
//  AppVersionTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import SettingDomain

@Suite("앱 버전")
struct AppVersionTests {

    @Suite("문자열 읽기")
    struct Parsing {

        @Test(
            "숫자가 하나나 둘이면 비어 있는 자리를 0으로 채운다",
            arguments: [
                ("1", AppVersion(major: 1, minor: 0, patch: 0)),    // minor·patch가 빔
                ("1.2", AppVersion(major: 1, minor: 2, patch: 0))   // patch만 빔
            ]
        )
        func fillsMissingComponentsWithZero(text: String, expected: AppVersion) throws {
            let version = try AppVersion(text)

            #expect(version == expected)
        }

        @Test("숫자가 셋이면 그대로 읽는다")
        func readsThreeComponents() throws {
            let version = try AppVersion("1.2.3")

            #expect(version == AppVersion(major: 1, minor: 2, patch: 3))
        }

        @Test("앞뒤 공백은 무시하고 읽는다")
        func ignoresSurroundingWhitespace() throws {
            let version = try AppVersion("  2.0.1\n")

            #expect(version == AppVersion(major: 2, minor: 0, patch: 1))
        }

        @Test(
            "버전 모양이 아니면 오류로 처리한다",
            arguments: [
                "",          // 아무것도 없음
                "   ",       // 공백뿐
                "1.2.3.4",   // 숫자가 넷
                "a.b.c",     // 숫자가 아님
                "1.-2.3",    // 음수
                "v1.2.3",    // 앞에 글자가 붙음
                "1..2",      // 가운데 자리가 빔
                "1.",        // 끝 자리가 빔
                ".1"         // 첫 자리가 빔
            ]
        )
        func rejectsMalformedText(text: String) {
            #expect(throws: AppVersion.ParseError.invalidFormat(text)) {
                try AppVersion(text)
            }
        }
    }

    @Suite("비교")
    struct Comparison {

        @Test(
            "앞자리부터 차례로 비교해 처음 다른 자리로 크기를 정한다",
            arguments: [
                // major가 작으면 minor·patch가 커도 작다
                (AppVersion(major: 1, minor: 9, patch: 9), AppVersion(major: 2, minor: 0, patch: 0)),
                // major가 같으면 minor가 작은 쪽이 작다(patch가 커도)
                (AppVersion(major: 1, minor: 2, patch: 9), AppVersion(major: 1, minor: 3, patch: 0)),
                // major·minor가 같으면 patch로 정한다
                (AppVersion(major: 1, minor: 2, patch: 3), AppVersion(major: 1, minor: 2, patch: 4))
            ]
        )
        func higherComponentDecidesOrder(smaller: AppVersion, larger: AppVersion) {
            let sorted = [larger, smaller].sorted()

            #expect(sorted == [smaller, larger])
        }

        @Test("세 자리가 모두 같으면 더 작다고 보지 않는다")
        func sameComponentsAreNotSmaller() {
            let version = AppVersion(major: 1, minor: 2, patch: 3)

            let isSmaller = version < AppVersion(major: 1, minor: 2, patch: 3)

            #expect(isSmaller == false)
        }
    }
}
