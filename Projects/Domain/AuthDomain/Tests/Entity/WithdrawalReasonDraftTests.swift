//
//  WithdrawalReasonDraftTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import AuthDomain

@Suite("탈퇴 사유 작성")
struct WithdrawalReasonDraftTests {

    @Test("처음에는 '자주 사용하지 않아서' 항목이 골라져 있고, 탈퇴 이유는 비어 있고, 정책에 동의하지 않은 상태다")
    func startsWithFirstOptionAndNothingFilled() {
        let draft = WithdrawalReasonDraft()

        #expect(draft.option == .notFrequentlyUsed)
        #expect(draft.customReasonText == "")
        #expect(draft.policyAgreed == false)
    }

    @Test("'직접입력' 항목을 고르면 탈퇴 이유를 작성할 수 있다")
    func customOptionAcceptsReason() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        draft.setCustomReasonText("읽을 작품이 줄었어요")

        #expect(draft.customReasonText == "읽을 작품이 줄었어요")
    }

    @Test(
        "'직접입력'이 아닌 항목에서는 탈퇴 이유를 작성해도 저장되지 않는다",
        arguments: [
            WithdrawalReasonOption.notFrequentlyUsed,
            .inconvenientAndBuggy,
            .wantToDeleteContent,
            .noDesiredContent
        ]
    )
    func nonCustomOptionIgnoresReason(option: WithdrawalReasonOption) {
        var draft = WithdrawalReasonDraft()
        draft.setOption(option)

        draft.setCustomReasonText("읽을 작품이 줄었어요")

        #expect(draft.customReasonText == "")
    }

    @Test("탈퇴 이유는 80자까지 그대로 저장된다")
    func keepsReasonUpTo80Characters() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        let reason = String(repeating: "가", count: 80)

        draft.setCustomReasonText(reason)

        #expect(draft.customReasonText == reason)
    }

    @Test("탈퇴 이유가 80자를 넘으면 앞 80자만 남는다")
    func cutsReasonOver80Characters() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        // 81번째 글자만 다르게 둬서, 잘려 나간 쪽이 뒤인지 확인한다.
        let reason = String(repeating: "가", count: 80) + "나"

        draft.setCustomReasonText(reason)

        #expect(draft.customReasonText == String(repeating: "가", count: 80))
    }

    @Test(
        "'직접입력'에서 다른 항목으로 바꾸면 작성한 탈퇴 이유가 지워진다",
        arguments: [
            WithdrawalReasonOption.notFrequentlyUsed,
            .inconvenientAndBuggy,
            .wantToDeleteContent,
            .noDesiredContent
        ]
    )
    func switchingAwayFromCustomClearsReason(option: WithdrawalReasonOption) {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        draft.setCustomReasonText("읽을 작품이 줄었어요")

        draft.setOption(option)

        #expect(draft.customReasonText == "")
    }

    @Test("'직접입력'을 다시 골라도 작성한 탈퇴 이유는 그대로다")
    func reselectingCustomKeepsReason() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        draft.setCustomReasonText("읽을 작품이 줄었어요")

        draft.setOption(.custom)

        #expect(draft.customReasonText == "읽을 작품이 줄었어요")
    }

    @Test(
        "정책에 동의하지 않으면 어떤 항목을 골라도 제출할 수 없다",
        arguments: WithdrawalReasonOption.allCases
    )
    func cannotSubmitWithoutPolicyAgreement(option: WithdrawalReasonOption) {
        var draft = WithdrawalReasonDraft()
        draft.setOption(option)
        // '직접입력'이 아닌 항목에선 무시된다. 항목마다 정책 동의 말고는 다 채운 상태로 맞추려는 것.
        draft.setCustomReasonText("읽을 작품이 줄었어요")

        let isSubmittable = draft.isSubmittable

        #expect(isSubmittable == false)
    }

    @Test(
        "정책에 동의하면 '직접입력'이 아닌 항목은 바로 제출할 수 있다",
        arguments: [
            WithdrawalReasonOption.notFrequentlyUsed,
            .inconvenientAndBuggy,
            .wantToDeleteContent,
            .noDesiredContent
        ]
    )
    func nonCustomOptionSubmitsWithPolicyAgreement(option: WithdrawalReasonOption) {
        var draft = WithdrawalReasonDraft()
        draft.setOption(option)

        draft.setPolicyAgreed(true)

        #expect(draft.isSubmittable == true)
    }

    @Test("'직접입력'은 탈퇴 이유를 작성하고 정책에 동의하면 제출할 수 있다")
    func customOptionSubmitsWithReasonAndPolicyAgreement() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        draft.setCustomReasonText("읽을 작품이 줄었어요")

        draft.setPolicyAgreed(true)

        #expect(draft.isSubmittable == true)
    }

    @Test(
        "'직접입력'은 탈퇴 이유가 비었거나 공백뿐이면 정책에 동의해도 제출할 수 없다",
        arguments: [
            "",      // 아무것도 쓰지 않음
            "   ",   // 스페이스만
            "\n\t "  // 줄바꿈·탭도 공백으로 본다
        ]
    )
    func customOptionCannotSubmitWithBlankReason(reason: String) {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        draft.setCustomReasonText(reason)

        draft.setPolicyAgreed(true)

        #expect(draft.isSubmittable == false)
    }

    @Test("정책 동의를 취소하면 다시 제출할 수 없다")
    func withdrawingPolicyAgreementBlocksSubmit() {
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(true)

        draft.setPolicyAgreed(false)

        #expect(draft.isSubmittable == false)
    }
}
