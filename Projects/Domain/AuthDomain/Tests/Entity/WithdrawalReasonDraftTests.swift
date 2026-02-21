//
//  WithdrawalReasonDraftTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import AuthDomain

@Suite("WithdrawalReasonDraft")
struct WithdrawalReasonDraftTests {

    // MARK: - Init

    @Test("초안은 기본 옵션과 빈 텍스트로 생성된다")
    func initializesWithDefaults() {
        let draft = WithdrawalReasonDraft()

        #expect(draft.option == (WithdrawalReasonOption.allCases.first ?? .notFrequentlyUsed))
        #expect(draft.customReasonText == "")
        #expect(draft.isSubmittable == true)
    }

    // MARK: - isSubmittable

    @Test("직접 입력이 아닌 옵션은 텍스트가 없어도 제출 가능하다")
    func isSubmittableIsTrueWhenOptionDoesNotRequireText() {
        var draft = WithdrawalReasonDraft()

        draft.setOption(.notFrequentlyUsed)
        draft.setOtherText("무시되어야 함") // requiresText가 아니므로 setOtherText는 no-op
        #expect(draft.customReasonText == "")
        #expect(draft.isSubmittable == true)

        draft.setOption(.inconvenientAndBuggy)
        #expect(draft.isSubmittable == true)

        draft.setOption(.wantToDeleteContent)
        #expect(draft.isSubmittable == true)

        draft.setOption(.noDesiredContent)
        #expect(draft.isSubmittable == true)
    }

    @Test("직접 입력 옵션은 텍스트가 비어있으면 제출할 수 없다")
    func isSubmittableIsFalseWhenCustomTextIsEmptyOrWhitespace() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        draft.setOtherText("")
        #expect(draft.isSubmittable == false)

        draft.setOtherText("   ")
        #expect(draft.isSubmittable == false)

        draft.setOtherText("\n\t ")
        #expect(draft.isSubmittable == false)
    }

    @Test("직접 입력 옵션은 텍스트가 있으면 제출할 수 있다")
    func isSubmittableIsTrueWhenCustomTextIsNotEmpty() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        draft.setOtherText("원하는 이유를 적었습니다")
        #expect(draft.isSubmittable == true)
    }

    // MARK: - setOption

    @Test("옵션을 직접 입력이 아닌 값으로 바꾸면 입력 텍스트는 초기화된다")
    func setOptionClearsCustomTextWhenSwitchingToNonCustom() {
        var draft = WithdrawalReasonDraft()

        draft.setOption(.custom)
        draft.setOtherText("어떤 이유")
        #expect(draft.customReasonText == "어떤 이유")

        draft.setOption(.notFrequentlyUsed)
        #expect(draft.option == .notFrequentlyUsed)
        #expect(draft.customReasonText == "")
        #expect(draft.isSubmittable == true)
    }

    // MARK: - setOtherText

    @Test("직접 입력이 아닌 옵션에서는 setOtherText가 아무 일도 하지 않는다")
    func setOtherTextIsNoOpWhenOptionDoesNotRequireText() {
        var draft = WithdrawalReasonDraft()

        draft.setOption(.notFrequentlyUsed)
        draft.setOtherText("저장되면 안 됨")
        #expect(draft.customReasonText == "")

        draft.setOption(.inconvenientAndBuggy)
        draft.setOtherText("저장되면 안 됨")
        #expect(draft.customReasonText == "")

        draft.setOption(.wantToDeleteContent)
        draft.setOtherText("저장되면 안 됨")
        #expect(draft.customReasonText == "")

        draft.setOption(.noDesiredContent)
        draft.setOtherText("저장되면 안 됨")
        #expect(draft.customReasonText == "")
    }

    @Test("직접 입력 옵션에서는 입력 텍스트가 최대 80자로 잘린다")
    func setOtherTextClipsToMaxLengthWhenCustom() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        let long = String(repeating: "a", count: WithdrawalReasonDraft.maxOtherLength + 10)
        draft.setOtherText(long)

        #expect(draft.customReasonText.count == WithdrawalReasonDraft.maxOtherLength)
    }

    @Test("직접 입력 옵션에서는 80자 이하면 그대로 저장된다")
    func setOtherTextStoresWhenWithinMaxLengthWhenCustom() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        let text = "짧은 텍스트"
        draft.setOtherText(text)

        #expect(draft.customReasonText == text)
    }
}
