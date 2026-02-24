//
//  NicknameDraftTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import ProfileDomain

@Suite("NicknameDraft")
struct NicknameDraftTests {

    // MARK: - Helpers

    private func makeDraft(initial: String = "기존닉네임") -> NicknameDraft {
        NicknameDraft(initial)
    }

    // MARK: - Init

    @Test("초기화 시 text는 초기 닉네임이다")
    func initSetsTextToInitialName() {
        let draft = NicknameDraft("윤학")
        #expect(draft.text == "윤학")
    }
    
    // MARK: - Length clipping

    @Test("닉네임은 최대 10자까지만 입력된다")
    func clipsToMaxLength10() {
        var draft = makeDraft()
        draft.setText("일이삼사오육칠팔구십일") // 11 chars
        #expect(draft.text == "일이삼사오육칠팔구십")
    }

    // MARK: - notAvailable

    @Test("닉네임이 비어있으면 어떠한 검증도 불가하므로 notStarted 상태다")
    func emptyTextIsNotStarted() {
        let draft = makeDraft(initial: "")
        #expect(draft.validationState == .notStarted)
    }
    
    @Test("초기 닉네임과 동일하면 notAvailable(notChanged) 상태다")
    func initialSameAsLastNicknameIsNotChanged() {
        let draft = makeDraft(initial: "윤학")
        #expect(draft.validationState == .notAvailable(reason: .notChanged))
    }
    
    @Test("초기 닉네임으로 되돌리면 notAvailable(notChanged) 상태다")
    func revertingToLastNicknameIsNotChanged() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd")
        #expect(draft.validationState == .needDuplicatedCheck)

        draft.setText("윤학")
        #expect(draft.validationState == .notAvailable(reason: .notChanged))
    }

    @Test("공백 또는 줄바꿈/탭이 포함되면 notAvailable(whiteSpaceIncluded) 상태다")
    func whitespaceIncludedIsNotAvailable() {
        var draft = makeDraft(initial: "윤학")

        draft.setText("ab cd")
        #expect(draft.validationState == .notAvailable(reason: .whiteSpaceIncluded))

        draft.setText("ab\tcd")
        #expect(draft.validationState == .notAvailable(reason: .whiteSpaceIncluded))

        draft.setText("ab\ncd")
        #expect(draft.validationState == .notAvailable(reason: .whiteSpaceIncluded))
    }

    @Test("정규식 조건을 만족하지 않으면 notAvailable(invalidCharacterOrLimitExceeded) 상태다")
    func invalidPatternIsNotAvailable() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("ab!cd") // '!' not allowed
        #expect(draft.validationState == .notAvailable(reason: .invalidCharacterOrLimitExceeded))
    }

    // MARK: - Duplication check flow

    @Test("유효한 닉네임을 입력했지만 중복 검사 전이면 needDuplicatedCheck 상태다")
    func validButNotCheckedIsNeedDuplicatedCheck() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd") // valid, changed
        #expect(draft.validationState == .needDuplicatedCheck)
    }

    @Test("중복 검사 결과가 duplicated면 notAvailable(duplicated) 상태다")
    func duplicatedResultMakesNotAvailableDuplicated() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd")

        draft.applyDuplicationCheckResult(.duplicated, checkedText: "abcd")
        #expect(draft.validationState == .notAvailable(reason: .duplicated))
    }

    @Test("중복 검사 결과가 notDuplicated면 available 상태다")
    func notDuplicatedResultMakesAvailable() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd")

        draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "abcd")
        #expect(draft.validationState == .available)
    }

    @Test("중복 검사 결과는 검사를 실행한 checkedText가 현재 text와 다르면 무시된다(비동기 동작 대비)")
    func ignoresDuplicationResultWhenCheckedTextMismatch() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd")

        // user typed again before response arrives
        draft.setText("abcde")

        // late response for old text
        draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "abcd")

        // still need check for current text
        #expect(draft.validationState == .needDuplicatedCheck)
    }

    @Test("텍스트가 변경되면 중복 검사 상태는 notYet으로 리셋된다")
    func changingTextResetsDuplicationState() {
        var draft = makeDraft(initial: "윤학")
        draft.setText("abcd")
        draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "abcd")
        #expect(draft.validationState == .available)

        // change -> should require check again
        // isValidPattern && notYet -> needDuplicatedCheck
        draft.setText("abcde")
        #expect(draft.validationState == .needDuplicatedCheck)
    }
}
