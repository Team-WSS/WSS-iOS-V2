//
//  TermsAgreementDraftTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import SettingDomain

@Suite("약관 동의")
struct TermsAgreementDraftTests {

    @Suite("처음 상태")
    struct Initial {

        @Test("아무 값 없이 만들면 모든 약관이 미동의다")
        func startsWithEverythingDisagreed() {
            let draft = TermsAgreementDraft()

            #expect(draft.agreements == [
                .serviceAgreement: false,
                .privacyPolicy: false,
                .marketingConsent: false
            ])
        }

        @Test("값을 주지 않은 약관은 미동의로 채운다")
        func fillsUnspecifiedTermsAsDisagreed() {
            let draft = TermsAgreementDraft(initial: [.marketingConsent: true])

            #expect(draft.agreements == [
                .serviceAgreement: false,
                .privacyPolicy: false,
                .marketingConsent: true
            ])
        }
    }

    @Suite("동의 여부 편집")
    struct Changing {

        @Test(
            "약관 하나에 동의하거나 철회하면 그 약관만 바뀐다",
            arguments: [
                true,   // 전부 미동의인 상태에서 하나만 동의
                false   // 전부 동의한 상태에서 하나만 철회
            ]
        )
        func changesOnlyThatTerm(isAgreed: Bool) {
            var draft = TermsAgreementDraft(initial: [
                .serviceAgreement: !isAgreed,
                .privacyPolicy: !isAgreed,
                .marketingConsent: !isAgreed
            ])

            draft.setAgreed(isAgreed, for: .privacyPolicy)

            #expect(draft.agreements == [
                .serviceAgreement: !isAgreed,
                .privacyPolicy: isAgreed,
                .marketingConsent: !isAgreed
            ])
        }

        @Test("모두 동의하면 선택 약관까지 전부 동의가 된다")
        func agreeToAllIncludesOptionalTerms() {
            var draft = TermsAgreementDraft()

            draft.agreeToAll()

            #expect(draft.agreements == [
                .serviceAgreement: true,
                .privacyPolicy: true,
                .marketingConsent: true
            ])
        }
    }

    @Suite("제출")
    struct Submission {

        @Test(
            "필수 약관 중 하나라도 동의하지 않으면 제출할 수 없다",
            // 선택 약관(마케팅)까지 동의해도 필수 하나가 빠지면 소용없다.
            arguments: [
                [.serviceAgreement: false, .privacyPolicy: true, .marketingConsent: true],   // 서비스 이용약관만 빠짐
                [.serviceAgreement: true, .privacyPolicy: false, .marketingConsent: true]    // 개인정보 처리방침만 빠짐
            ] as [[TermsType: Bool]]
        )
        func notSubmittableWithoutARequiredTerm(agreements: [TermsType: Bool]) {
            let draft = TermsAgreementDraft(initial: agreements)

            #expect(draft.isSubmittable == false)
        }

        @Test("선택 약관인 마케팅 수신에 동의하지 않아도 제출할 수 있다")
        func submittableWithoutOptionalTerm() {
            let draft = TermsAgreementDraft(initial: [
                .serviceAgreement: true,
                .privacyPolicy: true,
                .marketingConsent: false
            ])

            #expect(draft.isSubmittable == true)
        }
    }
}
