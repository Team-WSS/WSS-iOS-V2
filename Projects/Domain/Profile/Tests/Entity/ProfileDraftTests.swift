//
//  ProfileDraftTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain

@Suite("ProfileDraft")
struct ProfileDraftTests {

    // MARK: - Init

    @Test("초기화 시 전달한 값으로 생성된다")
    func initializesWithGivenValues() {
        let genre = makeGenre()
        let draft = makeDraft(characterID: 3,
                              nickname: "서연",
                              introduction: "반가워요",
                              genrePreferences: [genre])

        #expect(draft.characterID == 3)
        #expect(draft.nickname.text == "서연")
        #expect(draft.introduction == "반가워요")
        #expect(draft.genrePreferences == [genre])
    }

    // MARK: - Change Detection

    @Test("초기화 직후에는 변경된 항목이 없다")
    func noChangesRightAfterInit() {
        let draft = makeDraft()

        #expect(draft.isCharacterChanged == false)
        #expect(draft.isNicknameChanged == false)
        #expect(draft.isIntroductionChanged == false)
        #expect(draft.isGenrePreferencesChanged == false)
    }

    @Test("다른 캐릭터로 변경하면 isCharacterChanged가 true다")
    func isCharacterChangedWhenDifferentID() {
        var draft = makeDraft(characterID: 1)
        draft.setCharacter(2)

        #expect(draft.isCharacterChanged == true)
    }

    @Test("동일한 캐릭터로 설정하면 isCharacterChanged가 false다")
    func isCharacterNotChangedWhenSameID() {
        var draft = makeDraft(characterID: 1)
        draft.setCharacter(1)

        #expect(draft.isCharacterChanged == false)
    }

    @Test("닉네임이 변경되고 중복확인까지 통과하면 isNicknameChanged가 true다")
    func isNicknameChangedWhenAvailable() {
        let draft = makeDraftWithAvailableNickname()

        #expect(draft.isNicknameChanged == true)
    }

    @Test("닉네임이 변경됐지만 중복확인 전이면 isNicknameChanged가 false다")
    func isNicknameNotChangedBeforeDuplicationCheck() {
        var draft = makeDraft(nickname: "서연")
        draft.updateNickname("newNick")

        #expect(draft.isNicknameChanged == false)
    }

    @Test("소개글을 다른 값으로 변경하면 isIntroductionChanged가 true다")
    func isIntroductionChangedWhenDifferent() {
        var draft = makeDraft(introduction: "안녕하세요")
        draft.updateIntroduction("반가워요")

        #expect(draft.isIntroductionChanged == true)
    }

    @Test("소개글을 초기값으로 되돌리면 isIntroductionChanged가 false다")
    func isIntroductionNotChangedWhenReverted() {
        var draft = makeDraft(introduction: "안녕하세요")
        draft.updateIntroduction("반가워요")
        draft.updateIntroduction("안녕하세요")

        #expect(draft.isIntroductionChanged == false)
    }

    @Test("장르를 추가하면 isGenrePreferencesChanged가 true다")
    func isGenreChangedAfterAdd() {
        var draft = makeDraft(genrePreferences: [])
        draft.addGenrePreference(makeGenre())

        #expect(draft.isGenrePreferencesChanged == true)
    }

    @Test("장르를 추가했다가 삭제해 초기 상태로 돌아오면 isGenrePreferencesChanged가 false다")
    func isGenreNotChangedWhenReverted() {
        let genre = makeGenre()
        var draft = makeDraft(genrePreferences: [genre])
        draft.removeGenrePreference(genre)
        draft.addGenrePreference(genre)

        #expect(draft.isGenrePreferencesChanged == false)
    }

    // MARK: - isSubmittable

    @Test("아무것도 변경되지 않으면 isSubmittable이 false다")
    func notSubmittableWhenNothingChanged() {
        let draft = makeDraft()

        #expect(draft.isSubmittable == false)
    }

    @Test("캐릭터만 변경해도 isSubmittable이 true다")
    func submittableWhenOnlyCharacterChanged() {
        var draft = makeDraft(characterID: 1)
        draft.setCharacter(2)

        #expect(draft.isSubmittable == true)
    }

    @Test("닉네임만 변경하고 중복확인까지 통과하면 isSubmittable이 true다")
    func submittableWhenNicknameAvailable() {
        let draft = makeDraftWithAvailableNickname()

        #expect(draft.isSubmittable == true)
    }

    @Test("소개글만 변경해도 isSubmittable이 true다")
    func submittableWhenOnlyIntroductionChanged() {
        var draft = makeDraft(introduction: "안녕하세요")
        draft.updateIntroduction("반가워요")

        #expect(draft.isSubmittable == true)
    }

    @Test("장르만 변경해도 isSubmittable이 true다")
    func submittableWhenOnlyGenreChanged() {
        var draft = makeDraft(genrePreferences: [])
        draft.addGenrePreference(makeGenre())

        #expect(draft.isSubmittable == true)
    }

    @Test("닉네임이 중복확인 필요 상태면 다른 필드가 변경되어도 isSubmittable이 false다")
    func notSubmittableWhenNeedDuplicatedCheck() {
        var draft = makeDraft(nickname: "서연")
        draft.updateNickname("newNick") // needDuplicatedCheck
        draft.setCharacter(2)

        #expect(draft.isSubmittable == false)
    }

    @Test("닉네임이 중복이면 다른 필드가 변경되어도 isSubmittable이 false다")
    func notSubmittableWhenNicknameDuplicated() {
        var draft = makeDraft(nickname: "서연")
        draft.updateNickname("newNick")
        draft.applyNicknameDuplicationCheck(.duplicated, checkedText: "newNick")
        draft.setCharacter(2)

        #expect(draft.isSubmittable == false)
    }

    @Test("닉네임에 공백이 포함되면 다른 필드가 변경되어도 isSubmittable이 false다")
    func notSubmittableWhenNicknameHasWhitespace() {
        var draft = makeDraft(nickname: "서연")
        draft.updateNickname("new Nick")
        draft.setCharacter(2)

        #expect(draft.isSubmittable == false)
    }

    @Test("닉네임이 유효하지 않은 패턴이면 다른 필드가 변경되어도 isSubmittable이 false다")
    func notSubmittableWhenNicknameInvalidPattern() {
        var draft = makeDraft(nickname: "서연")
        draft.updateNickname("ab!cd")
        draft.setCharacter(2)

        #expect(draft.isSubmittable == false)
    }

    // MARK: - update Introduction

    @Test("소개글 50자 이하면 그대로 저장된다")
    func keepsIntroductionUnder50Characters() {
        var draft = makeDraft()
        let text = String(repeating: "가", count: 50)
        draft.updateIntroduction(text)

        #expect(draft.introduction.count == 50)
    }

    @Test("소개글이 50자를 초과하면 50자까지만 저장된다")
    func clipsIntroductionTo50Characters() {
        var draft = makeDraft()
        let text = String(repeating: "가", count: 60)
        draft.updateIntroduction(text)

        #expect(draft.introduction.count == 50)
    }

    @Test("소개글 3줄 이하면 그대로 저장된다")
    func keeps3LinesExactly() {
        var draft = makeDraft()
        draft.updateIntroduction("1줄\n2줄\n3줄")

        #expect(draft.introduction == "1줄\n2줄\n3줄")
    }

    @Test("소개글이 3줄을 초과하면 3줄까지만 저장된다")
    func clipsIntroductionTo3Lines() {
        var draft = makeDraft()
        draft.updateIntroduction("1줄\n2줄\n3줄\n4줄")

        #expect(draft.introduction == "1줄\n2줄\n3줄")
    }

    @Test("소개글에 앞뒤 공백이 포함되어도 그대로 저장된다")
    func allowsWhitespaceInIntroduction() {
        var draft = makeDraft()
        draft.updateIntroduction("  공백 포함  ")

        #expect(draft.introduction == "  공백 포함  ")
    }

    @Test("소개글을 빈 문자열로 업데이트할 수 있다")
    func allowsEmptyIntroduction() {
        var draft = makeDraft(introduction: "안녕하세요")
        draft.updateIntroduction("")

        #expect(draft.introduction == "")
    }

    // MARK: - Genre Preference

    @Test("장르를 추가할 수 있다")
    func addsGenrePreference() {
        var draft = makeDraft()
        let genre = makeGenre(name: "로맨스")
        draft.addGenrePreference(genre)

        #expect(draft.genrePreferences.contains(genre))
    }

    @Test("장르를 삭제할 수 있다")
    func removesGenrePreference() {
        let genre = makeGenre(name: "로맨스")
        var draft = makeDraft(genrePreferences: [genre])
        draft.removeGenrePreference(genre)

        #expect(draft.genrePreferences.isEmpty)
    }

    @Test("존재하지 않는 장르를 삭제해도 기존 장르는 유지된다")
    func removingNonExistentGenreKeepsOthers() {
        let romance = makeGenre(name: "로맨스")
        let fantasy = makeGenre(name: "판타지")
        var draft = makeDraft(genrePreferences: [romance])
        draft.removeGenrePreference(fantasy)

        #expect(draft.genrePreferences == [romance])
    }
}

extension ProfileDraftTests {
    
    // MARK: - Helpers

    private func makeDraft(
        characterID: Int = 1,
        nickname: String = "서연",
        introduction: String = "안녕하세요",
        genrePreferences: [GenrePreference] = []
    ) -> ProfileDraft {
        ProfileDraft(
            characterID: characterID,
            nickname: nickname,
            introduction: introduction,
            genrePreferences: genrePreferences
        )
    }

    private func makeGenre(name: String = "로맨스") -> GenrePreference {
        GenrePreference(name: name, image: nil, count: 0)
    }

    // 닉네임 변경 + 중복확인까지 통과한 draft
    private func makeDraftWithAvailableNickname(
        initial: String = "서연",
        new: String = "newNick"
    ) -> ProfileDraft {
        var draft = makeDraft(nickname: initial)
        draft.updateNickname(new)
        draft.applyNicknameDuplicationCheck(.notDuplicated, checkedText: new)
        return draft
    }

}
