//
//  AuthorTests.swift
//  BaseDomain
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain

@Suite("작성자 프로필 이동")
struct AuthorTests {

    @Test("작성자를 알면 그 작성자의 프로필로 이동할 수 있다")
    func knownAuthorIsReachable() {
        let author = makeAuthor(userId: UserID(1003))

        #expect(author.accessibleUserId == UserID(1003))
    }

    @Test("탈퇴한 작성자의 프로필로는 이동할 수 없다")
    func withdrawnAuthorIsNotReachable() {
        // 서버는 탈퇴한 작성자를 -1로 보낸다.
        let author = makeAuthor(userId: UserID(-1))

        #expect(author.accessibleUserId == nil)
    }

    @Test("작성자를 모르면 프로필로 이동할 수 없다")
    func unknownAuthorIsNotReachable() {
        let author = makeAuthor(userId: nil)

        #expect(author.accessibleUserId == nil)
    }

    // MARK: - Helpers

    private func makeAuthor(userId: UserID?) -> Author {
        Author(userId: userId, nickname: "소소", profileImage: nil)
    }
}
