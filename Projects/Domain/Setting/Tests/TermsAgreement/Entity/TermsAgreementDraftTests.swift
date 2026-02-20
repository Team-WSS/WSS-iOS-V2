//
//  TermsAgreementDraftTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SettingDomain

@Suite("TermsAgreementDraft")
struct TermsAgreementDraftTests {

    @Test("초기화 시 모든 약관 항목은 기본값 false로 채워진다")
    func initFillsAllCasesWithFalseByDefault() throws {
        let draft = TermsAgreementDraft()

        for t in TermsType.allCases {
            #expect(draft.isAgreed(t) == false)
        }
    }

    @Test("초기값으로 전달한 항목은 반영되고, 나머지는 false로 채워진다")
    func initAppliesInitialAndDefaultsTheRestToFalse() throws {
        let some = TermsType.allCases.first!
        let draft = TermsAgreementDraft(initial: [some: true])

        #expect(draft.isAgreed(some) == true)

        for t in TermsType.allCases where t != some {
            #expect(draft.isAgreed(t) == false)
        }
    }

    @Test("특정 약관 동의 여부를 조회할 수 있다")
    func isAgreedReadsCurrentState() {
        var draft = TermsAgreementDraft()
        let t = TermsType.allCases[0]

        #expect(draft.isAgreed(t) == false)

        draft.setAgreed(true, for: t)
        #expect(draft.isAgreed(t) == true)
    }

    @Test("특정 약관 동의 여부를 설정할 수 있다")
    func setAgreedUpdatesAgreementState() {
        var draft = TermsAgreementDraft()
        let t = TermsType.allCases[0]

        draft.setAgreed(true, for: t)
        #expect(draft.isAgreed(t) == true)

        draft.setAgreed(false, for: t)
        #expect(draft.isAgreed(t) == false)
    }

    @Test("모두 동의 기능을 실행하면 모든 약관이 true가 된다")
    func agreeToAllSetsAllToTrue() {
        var draft = TermsAgreementDraft()
        draft.agreeToAll()

        for t in TermsType.allCases {
            #expect(draft.isAgreed(t) == true)
        }
    }

    @Test("필수 약관이 모두 동의되면 제출 가능 상태가 된다")
    func isSubmittableTrueWhenAllRequiredAreAgreed() {
        var draft = TermsAgreementDraft()

        // 필수만 true로
        for t in TermsType.allCases where t.isRequired {
            draft.setAgreed(true, for: t)
        }

        #expect(draft.isSubmittable == true)
    }

    @Test("필수 약관 중 하나라도 미동의면 제출 불가 상태가 된다")
    func isSubmittableFalseWhenAnyRequiredIsNotAgreed() {
        var draft = TermsAgreementDraft()

        // 필수 중 하나만 false로 유지 (나머지 필수는 true)
        let required = TermsType.allCases.filter { $0.isRequired }
        let firstRequired = required.first

        for t in required {
            draft.setAgreed(true, for: t)
        }
        if let firstRequired {
            draft.setAgreed(false, for: firstRequired)
        }

        #expect(draft.isSubmittable == false)
    }

    @Test("선택 약관은 미동의여도 제출 가능 여부에 영향을 주지 않는다")
    func optionalTermsDoNotAffectSubmittable() {
        var draft = TermsAgreementDraft()

        // 필수는 전부 true
        for t in TermsType.allCases where t.isRequired {
            draft.setAgreed(true, for: t)
        }

        // 선택은 전부 false로 유지해도 제출 가능
        for t in TermsType.allCases where !t.isRequired {
            #expect(draft.isAgreed(t) == false)
        }

        #expect(draft.isSubmittable == true)
    }
}
