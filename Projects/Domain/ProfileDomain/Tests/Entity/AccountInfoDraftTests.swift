//
//  AccountInfoDraftTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 11/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import ProfileDomain

// 규칙은 없지만 설정 화면은 이 메서드로만 값을 바꾼다 — 안 담기면 고른 값 대신 옛 값이 저장된다(#308 뮤테이션).
@Suite("계정 정보 수정")
struct AccountInfoDraftTests {

    @Test("성별을 바꾸면 담긴다")
    func setsGender() throws {
        var draft = AccountInfoDraft(email: nil, gender: .male, birth: try BirthYear(2000))

        draft.setGender(.female)

        #expect(draft.gender == .female)
    }

    @Test("생년을 바꾸면 담긴다")
    func setsBirth() throws {
        var draft = AccountInfoDraft(email: nil, gender: .male, birth: try BirthYear(2000))

        draft.setBirth(try BirthYear(1999))

        #expect(draft.birth == (try BirthYear(1999)))
    }
}
