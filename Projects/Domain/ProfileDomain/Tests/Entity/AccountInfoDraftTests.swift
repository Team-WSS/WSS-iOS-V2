//
//  AccountInfoDraftTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain

@Suite("AccountInfoDraft")
struct AccountInfoDraftTests {
    private func makeBirthYear(_ year: Int) -> BirthYear {
        try! BirthYear(year)
    }
    
    private func makeDraft(
        email: String? = "test@email.com",
        gender: Gender = .male,
        birth: BirthYear = try! BirthYear(2002)
    ) -> AccountInfoDraft {
        AccountInfoDraft(
            email: email,
            gender: gender,
            birth: birth
        )
    }

    @Test("초기화 시 전달한 값으로 생성된다")
    func initializesWithGivenValues() {
        let draft = makeDraft(
            email: "hello@test.com",
            gender: .female,
            birth: makeBirthYear(1999)
        )

        #expect(draft.email == "hello@test.com")
        #expect(draft.gender == .female)
        #expect(draft.birth == makeBirthYear(1999))
    }

    @Test("성별을 변경할 수 있다")
    func changesGender() {
        var draft = makeDraft(gender: .male)

        draft.setGender(.female)

        #expect(draft.gender == .female)
    }

    @Test("출생년도를 변경할 수 있다")
    func changesBirthYear() {
        var draft = makeDraft(birth: makeBirthYear(2000))

        draft.setBirth(makeBirthYear(1995))

        #expect(draft.birth == makeBirthYear(1995))
    }
}
