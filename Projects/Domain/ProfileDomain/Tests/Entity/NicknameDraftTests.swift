//
//  NicknameDraftTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import ProfileDomain

@Suite("닉네임 입력")
struct NicknameDraftTests {

    @Suite("입력 길이")
    struct Length {

        @Test("닉네임은 10자까지만 입력된다")
        func clipsToMaxLength() {
            var draft = NicknameDraft("서연")

            draft.setText(String(repeating: "가", count: 11))

            #expect(draft.text == String(repeating: "가", count: 10))
        }

        @Test("10자를 넘겨 쳐도 잘린 결과가 같으면 중복 확인 결과가 그대로다")
        func keepsDuplicationCheckWhenClippedTextIsSame() {
            let tenLetters = String(repeating: "가", count: 10)
            var draft = NicknameDraft("서연")
            draft.setText(tenLetters)
            draft.applyDuplicationCheckResult(.notDuplicated, checkedText: tenLetters)

            draft.setText(tenLetters + "나")

            #expect(draft.validationState == .available)
        }
    }

    @Suite("입력 상태")
    struct Validation {

        @Test("닉네임이 비어 있으면 아직 입력 전 상태다")
        func emptyIsNotStarted() {
            var draft = NicknameDraft("서연")

            draft.setText("")

            #expect(draft.validationState == .notStarted)
        }

        @Test("처음 닉네임과 같으면 바뀌지 않아 쓸 수 없다")
        func initialNicknameIsNotChanged() {
            let draft = NicknameDraft("서연")

            let state = draft.validationState

            #expect(state == .notAvailable(reason: .notChanged))
        }

        @Test("다른 닉네임을 쳤다가 처음 닉네임으로 되돌리면 바뀌지 않아 쓸 수 없다")
        func revertedNicknameIsNotChanged() {
            var draft = NicknameDraft("서연")
            draft.setText("새이름")

            draft.setText("서연")

            #expect(draft.validationState == .notAvailable(reason: .notChanged))
        }

        @Test(
            "공백·줄바꿈·탭이 들어가면 쓸 수 없다",
            arguments: [
                "새 이름", // 가운데 공백
                "새이름\n", // 줄바꿈
                "새\t이름" // 탭
            ]
        )
        func whitespaceIsNotAvailable(text: String) {
            var draft = NicknameDraft("서연")

            draft.setText(text)

            #expect(draft.validationState == .notAvailable(reason: .whiteSpaceIncluded))
        }

        @Test("공백이 들어가 있으면 처음 닉네임과 같아도 공백 때문에 쓸 수 없다고 알린다")
        func whitespaceIsReportedBeforeNotChanged() {
            let draft = NicknameDraft("서 연")

            let state = draft.validationState

            #expect(state == .notAvailable(reason: .whiteSpaceIncluded))
        }

        @Test(
            "한 글자이거나 한글·영문·숫자 말고 다른 문자가 있으면 쓸 수 없다",
            arguments: [
                "가", // 한 글자 — 두 글자부터 쓸 수 있다
                "새이름!", // 특수문자
                "ㄱㄴㄷ" // 완성되지 않은 한글(자음만)
            ]
        )
        func invalidPatternIsNotAvailable(text: String) {
            var draft = NicknameDraft("서연")

            draft.setText(text)

            #expect(draft.validationState == .notAvailable(reason: .invalidCharacterOrLimitExceeded))
        }

        @Test("두 글자이고 규칙에 맞으면 중복 확인이 필요하다")
        func shortestValidNicknameNeedsDuplicationCheck() {
            var draft = NicknameDraft("서연")

            draft.setText("Ab")

            #expect(draft.validationState == .needDuplicatedCheck)
        }
    }

    @Suite("중복 확인")
    struct DuplicationCheck {

        @Test("중복이면 쓸 수 없다")
        func duplicatedIsNotAvailable() {
            var draft = NicknameDraft("서연")
            draft.setText("새이름")

            draft.applyDuplicationCheckResult(.duplicated, checkedText: "새이름")

            #expect(draft.validationState == .notAvailable(reason: .duplicated))
        }

        @Test("중복이 아니면 쓸 수 있다")
        func notDuplicatedIsAvailable() {
            var draft = NicknameDraft("서연")
            draft.setText("새이름")

            draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "새이름")

            #expect(draft.validationState == .available)
        }

        @Test("확인하는 사이에 닉네임이 바뀌었으면 늦게 온 결과는 버린다")
        func ignoresResultForOldText() {
            var draft = NicknameDraft("서연")
            draft.setText("새이름")
            draft.setText("새이름1")

            draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "새이름")

            #expect(draft.validationState == .needDuplicatedCheck)
        }

        @Test("중복 확인 뒤 닉네임을 고치면 다시 확인해야 한다")
        func editingAfterCheckNeedsCheckAgain() {
            var draft = NicknameDraft("서연")
            draft.setText("새이름")
            draft.applyDuplicationCheckResult(.notDuplicated, checkedText: "새이름")

            draft.setText("새이름1")

            #expect(draft.validationState == .needDuplicatedCheck)
        }
    }
}
