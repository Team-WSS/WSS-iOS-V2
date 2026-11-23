//
//  ProfileDraftTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain
import ProfileDomain

// 프로필 수정 화면은 저장소가 불러온 값으로 시작한다. 장르 개수는 수정 화면에서 쓰지 않아 0으로 채워 온다.
private let romance = GenrePreference(genre: .romance, count: 0)
private let fantasy = GenrePreference(genre: .fantasy, count: 0)

private func makeDraft() -> ProfileDraft {
    ProfileDraft(characterID: 1, nickname: "서연", introduction: "반가워요", genrePreferences: [romance])
}

/// 저장 가능 여부를 볼 때 바꿔 볼 항목 하나.
enum Edit: CaseIterable {
    case character
    case nickname
    case introduction
    case genre

    func apply(to draft: inout ProfileDraft) {
        switch self {
        case .character:
            draft.setCharacter(2)
        case .nickname:
            draft.updateNickname("새이름")
            draft.applyNicknameDuplicationCheck(.notDuplicated, checkedText: "새이름")
        case .introduction:
            draft.updateIntroduction("새 소개")
        case .genre:
            draft.addGenrePreference(fantasy)
        }
    }
}

/// 다른 항목을 바꿔도 저장을 막는 닉네임 상태.
// 빈 닉네임은 여기 없다 — 지금은 다른 항목을 바꾸면 저장되는데, 막아야 할 동작이라 #309에서 고친다.
enum BlockingNickname: CaseIterable {
    case notChecked
    case duplicated
    case whitespace
    case invalidPattern

    func apply(to draft: inout ProfileDraft) {
        switch self {
        case .notChecked:
            draft.updateNickname("새이름")
        case .duplicated:
            draft.updateNickname("새이름")
            draft.applyNicknameDuplicationCheck(.duplicated, checkedText: "새이름")
        case .whitespace:
            draft.updateNickname("새 이름")
        case .invalidPattern:
            draft.updateNickname("새이름!")
        }
    }
}

@Suite("프로필 수정")
struct ProfileDraftTests {

    @Suite("바뀐 것 알아보기")
    struct ChangeDetection {

        @Test("처음에는 바뀐 것이 없다")
        func nothingChangedAtFirst() {
            let draft = makeDraft()

            let changes = [
                draft.isCharacterChanged,
                draft.isNicknameChanged,
                draft.isIntroductionChanged,
                draft.isGenrePreferencesChanged
            ]

            #expect(changes == [false, false, false, false])
        }

        @Test("다른 캐릭터를 고르면 캐릭터가 바뀐 것이다")
        func otherCharacterIsChanged() {
            var draft = makeDraft()

            draft.setCharacter(2)

            #expect(draft.isCharacterChanged)
        }

        @Test("같은 캐릭터를 다시 고르면 캐릭터가 바뀐 것이 아니다")
        func sameCharacterIsNotChanged() {
            var draft = makeDraft()

            draft.setCharacter(1)

            #expect(!draft.isCharacterChanged)
        }

        @Test(
            "닉네임은 중복 확인까지 통과해야 바뀐 것이다",
            arguments: [
                (NicknameDraft.DuplicationCheckState.notYet, false), // 확인 전
                (.duplicated, false), // 중복
                (.notDuplicated, true) // 통과
            ]
        )
        func nicknameIsChangedOnlyAfterPassingCheck(
            check: NicknameDraft.DuplicationCheckState,
            isChanged: Bool
        ) {
            var draft = makeDraft()
            draft.updateNickname("새이름")

            draft.applyNicknameDuplicationCheck(check, checkedText: "새이름")

            #expect(draft.isNicknameChanged == isChanged)
        }

        @Test("소개글을 고쳤다가 처음대로 되돌리면 바뀐 것이 아니다")
        func revertedIntroductionIsNotChanged() {
            var draft = makeDraft()
            draft.updateIntroduction("새 소개")

            draft.updateIntroduction("반가워요")

            #expect(!draft.isIntroductionChanged)
        }

        @Test("장르를 넣었다 빼서 처음과 같아지면 바뀐 것이 아니다")
        func revertedGenresAreNotChanged() {
            var draft = makeDraft()
            draft.addGenrePreference(fantasy)

            draft.removeGenrePreference(fantasy)

            #expect(!draft.isGenrePreferencesChanged)
        }
    }

    @Suite("저장 가능 여부")
    struct Submittable {

        @Test("아무것도 안 바꾸면 저장할 수 없다")
        func cannotSubmitWithoutChanges() {
            let draft = makeDraft()

            let isSubmittable = draft.isSubmittable

            #expect(!isSubmittable)
        }

        @Test("캐릭터·닉네임·소개글·장르 중 하나만 바꿔도 저장할 수 있다", arguments: Edit.allCases)
        func canSubmitWithOneChange(edit: Edit) {
            var draft = makeDraft()

            edit.apply(to: &draft)

            #expect(draft.isSubmittable)
        }

        @Test(
            "닉네임이 확인 전·중복·공백·규칙 위반이면 다른 걸 바꿔도 저장할 수 없다",
            arguments: BlockingNickname.allCases
        )
        func blockingNicknamePreventsSubmit(nickname: BlockingNickname) {
            var draft = makeDraft()
            draft.updateIntroduction("새 소개")

            nickname.apply(to: &draft)

            #expect(!draft.isSubmittable)
        }
    }

    @Suite("소개글")
    struct Introduction {

        @Test(
            "소개글은 50자까지만 입력된다",
            arguments: [
                (50, 50), // 딱 50자는 그대로
                (51, 50) // 넘치면 50자로 자른다
            ]
        )
        func clipsToMaxLength(inputCount: Int, savedCount: Int) {
            var draft = makeDraft()

            draft.updateIntroduction(String(repeating: "가", count: inputCount))

            #expect(draft.introduction == String(repeating: "가", count: savedCount))
        }

        // 줄 수 판단이 자르기 전 소개글을 봐서, 넷째 줄만 더하면 바뀐 게 없는데 저장할 수 있다 — #309에서 고친다.
        @Test(
            "저장 직전에 소개글을 세 줄까지만 남긴다",
            arguments: [
                ("하나\n둘\n셋", "하나\n둘\n셋"), // 세 줄은 그대로
                ("하나\n둘\n셋\n넷", "하나\n둘\n셋") // 넷째 줄부터 버린다
            ]
        )
        func keepsUpToThreeLinesBeforeSaving(typed: String, saved: String) {
            var draft = makeDraft()
            draft.updateIntroduction(typed)

            draft.truncateIntroductionToLineLimit()

            #expect(draft.introduction == saved)
        }
    }

    // 장르는 장르+개수가 모두 같아야 빠지고, 뺐다 다시 넣으면 순서가 바뀌어 바뀐 것으로 본다 — #309에서 고친다.
    @Suite("선호 장르")
    struct GenrePreferences {

        @Test("장르를 고르면 담긴다")
        func addsGenre() {
            var draft = makeDraft()

            draft.addGenrePreference(fantasy)

            #expect(draft.genrePreferences == [romance, fantasy])
        }

        @Test("고른 장르를 빼면 사라진다")
        func removesGenre() {
            var draft = makeDraft()

            draft.removeGenrePreference(romance)

            #expect(draft.genrePreferences == [])
        }
    }
}
