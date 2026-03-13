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
        #expect(draft.policyAgreed == false)
        #expect(draft.isSubmittable == false)
    }
    
    // MARK: - setOption
    
    @Test("탈퇴 사유 옵션을 변경 가능하며, 직접 입력 옵션의 경우 이유를 작성할 수 있다")
    func canChangeWithdrawalReasonOptionAndEditCustomReasonWhenSelected() {
        var draft = WithdrawalReasonDraft()
        
        for option in WithdrawalReasonOption.allCases {
            draft.setOption(option)
            #expect(draft.option == option)
        }
        
        draft.setOption(.custom)
        draft.setCustomReasonText("어떤 이유")
        #expect(draft.customReasonText == "어떤 이유")
    }
    
    @Test("직접 입력이 아닌 옵션으로 바꾸면 입력 텍스트는 초기화된다")
    func setOptionClearsCustomTextWhenSwitchingToNonCustom() {
        var draft = WithdrawalReasonDraft()
        let reason = "어떤 이유"
        
        for option in WithdrawalReasonOption.allCases {
            draft.setOption(.custom)
            draft.setCustomReasonText(reason)
            #expect(draft.customReasonText == reason)
            
            draft.setOption(option)
            
            if case .custom = option {
                #expect(draft.customReasonText == reason)
            } else {
                #expect(draft.customReasonText == "")
            }
        }
    }

    @Test("직접 입력이 아닌 옵션에서는 이유 작성 함수가 아무 일도 하지 않는다")
    func setOtherTextIsNoOpWhenOptionDoesNotRequireText() {
        var draft = WithdrawalReasonDraft()
        let reason = "저장되면 안 됨"
        
        for option in WithdrawalReasonOption.allCases {
            draft.setOption(option)
            draft.setCustomReasonText(reason)
            
            if case .custom = option {
                #expect(draft.customReasonText == reason)
            } else {
                #expect(draft.customReasonText == "")
            }
        }
    }

    @Test("직접 입력 옵션의 입력 텍스트가 최대 80자로 잘린다")
    func setOtherTextClipsToMaxLengthWhenCustom() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        let long = String(repeating: "a", count: WithdrawalReasonDraft.maxCustomReasonLength + 10)
        draft.setCustomReasonText(long)

        #expect(draft.customReasonText.count == WithdrawalReasonDraft.maxCustomReasonLength)
    }

    @Test("직접 입력 옵션에서는 80자 이하면 그대로 저장된다")
    func setOtherTextStoresWhenWithinMaxLengthWhenCustom() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)

        let text = "짧은 텍스트"
        draft.setCustomReasonText(text)

        #expect(draft.customReasonText == text)
    }

    // MARK: - isSubmittable
    
    @Test("탈퇴 정책 동의를 하지 않으면 제출 불가능하다")
    func isSubmittableIsFalseWhenPolicyDoesNotRequireText() {
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(false)
        
        for option in WithdrawalReasonOption.allCases {
            draft.setOption(option)
            draft.setCustomReasonText("그냥 이유")
            #expect(draft.isSubmittable == false)
        }
    }


    @Test("탈퇴 정책 동의를 한 경우, 직접 입력이 아닌 옵션은 텍스트가 없어도 제출 가능하다")
    func isSubmittableIsTrueWhenOptionDoesNotRequireText() {
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(true)
        
        for option in WithdrawalReasonOption.allCases {
            if case .custom = option { continue }
            draft.setOption(option)
            draft.setCustomReasonText("")
            #expect(draft.isSubmittable == true)
        }
    }

    @Test("탈퇴 정책 동의를 한 경우, 직접 입력 옵션은 텍스트가 비어있으면 제출할 수 없다")
    func isSubmittableIsFalseWhenCustomTextIsEmptyOrWhitespace() {
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(true)
        draft.setOption(.custom)

        draft.setCustomReasonText("")
        #expect(draft.isSubmittable == false)

        draft.setCustomReasonText("   ")
        #expect(draft.isSubmittable == false)

        draft.setCustomReasonText("\n\t ")
        #expect(draft.isSubmittable == false)
    }

    @Test("탈퇴 정책 동의를 한 경우, 직접 입력 옵션은 텍스트가 있으면 제출할 수 있다")
    func isSubmittableIsTrueWhenCustomTextIsNotEmpty() {
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(true)
        draft.setOption(.custom)

        draft.setCustomReasonText("원하는 이유를 적었습니다")
        #expect(draft.isSubmittable == true)
    }
}
