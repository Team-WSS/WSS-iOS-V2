//
//  AppVersionTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import Foundation
@testable import SettingDomain

@Suite("AppVersion")
struct AppVersionTests {

    @Test("버전 문자열이 한 자리일 경우 1.0.0 형태로 해석된다")
    func parsesSingleComponentVersion() throws {
        let v = try AppVersion("1")
        #expect(v.major == 1)
        #expect(v.minor == 0)
        #expect(v.patch == 0)
        #expect(v.description == "1.0.0")
    }

    @Test("버전 문자열이 두 자리일 경우 patch는 0으로 보정된다")
    func parsesTwoComponentVersion() throws {
        let v = try AppVersion("1.2")
        #expect(v.major == 1)
        #expect(v.minor == 2)
        #expect(v.patch == 0)
        #expect(v.description == "1.2.0")
    }

    @Test("버전 문자열이 세 자리일 경우 그대로 해석된다")
    func parsesThreeComponentVersion() throws {
        let v = try AppVersion("1.2.3")
        #expect(v.major == 1)
        #expect(v.minor == 2)
        #expect(v.patch == 3)
        #expect(v.description == "1.2.3")
    }

    @Test("버전 문자열 앞뒤 공백은 무시된다")
    func trimsWhitespace() throws {
        let v = try AppVersion("  2.0.1  ")
        #expect(v == AppVersion(major: 2, minor: 0, patch: 1))
    }

    @Test("유효하지 않은 버전 문자열이면 파싱에 실패한다")
    func throwsOnInvalidFormat() async {
        #expect(throws: AppVersion.ParseError.invalidFormat("1.2.3.4")) {
            _ = try AppVersion("1.2.3.4")
        }

        #expect(throws: AppVersion.ParseError.invalidFormat("a.b.c")) {
            _ = try AppVersion("a.b.c")
        }

        #expect(throws: AppVersion.ParseError.invalidFormat("")) {
            _ = try AppVersion("")
        }
    }

    @Test("patch 버전이 다르면 patch 값을 기준으로 비교한다")
    func comparesPatchVersion() {
        let a = AppVersion(major: 1, minor: 2, patch: 3)
        let b = AppVersion(major: 1, minor: 2, patch: 4)
        #expect(a < b)
        #expect(b > a)
    }

    @Test("minor 버전이 다르면 minor 값을 기준으로 비교한다")
    func comparesMinorVersion() {
        let a = AppVersion(major: 1, minor: 2, patch: 9)
        let b = AppVersion(major: 1, minor: 3, patch: 0)
        #expect(a < b)
    }

    @Test("major 버전이 다르면 major 값을 기준으로 비교한다")
    func comparesMajorVersion() {
        let a = AppVersion(major: 1, minor: 9, patch: 9)
        let b = AppVersion(major: 2, minor: 0, patch: 0)
        #expect(a < b)
    }

    @Test("1.2와 1.2.0은 같은 버전으로 취급된다")
    func treatsNormalizedVersionsAsEqual() throws {
        let a = try AppVersion("1.2")
        let b = try AppVersion("1.2.0")
        #expect(a == b)
    }
}
