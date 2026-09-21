//
//  AuthorTests.swift
//  BaseDomain
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import BaseDomain

@Suite
struct AuthorTests {

    // MARK: - accessibleUserId

    @Test("userId가 정상 값이면 accessibleUserId가 그 값을 그대로 반환한다")
    func accessibleUserIdReturnsValue() {
        let author = makeAuthor(userId: UserID(42))

        #expect(author.accessibleUserId == UserID(42))
    }

    @Test("userId가 탈퇴 유저 센티널(-1)이면 accessibleUserId가 nil이다")
    func accessibleUserIdNilWhenWithdrawn() {
        let author = makeAuthor(userId: UserID(-1))

        #expect(author.accessibleUserId == nil)
    }

    @Test("userId가 nil이면 accessibleUserId가 nil이다")
    func accessibleUserIdNilWhenMissing() {
        let author = makeAuthor(userId: nil)

        #expect(author.accessibleUserId == nil)
    }
}

private extension AuthorTests {
    func makeAuthor(userId: UserID?) -> Author {
        Author(userId: userId, nickname: "닉네임", profileImage: nil)
    }
}
