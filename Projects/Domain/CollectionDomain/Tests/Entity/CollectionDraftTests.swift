//
//  CollectionDraftTests.swift
//  CollectionDomainTests
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import CollectionDomain

@Suite("컬렉션 만들기·수정하기")
struct CollectionDraftTests {

    // MARK: - 제출

    @Test("이름이 있고 작품이 하나 이상이면 설명이 없어도 제출할 수 있다")
    func submittableWithNameAndNovel() {
        let draft = makeDraft(name: "취향 저격 로판", description: "", novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable == true)
    }

    @Test(
        "이름이 비었거나 공백뿐이면 제출할 수 없다",
        arguments: [
            "",      // 아무것도 쓰지 않음
            "   ",   // 스페이스만
            "\n\t "  // 줄바꿈·탭도 공백으로 본다
        ]
    )
    func notSubmittableWithBlankName(name: String) {
        let draft = makeDraft(name: name, novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable == false)
    }

    @Test("작품이 하나도 없으면 제출할 수 없다")
    func notSubmittableWithoutNovel() {
        let draft = makeDraft(name: "취향 저격 로판", novelIDs: [])

        #expect(draft.isSubmittable == false)
    }

    // MARK: - 이름·설명

    @Test("이름은 20자까지 입력할 수 있다")
    func nameAcceptsUpToTwenty() throws {
        var draft = makeDraft()
        let name = String(repeating: "가", count: 20)

        try draft.updateName(name)

        #expect(draft.name == name)
    }

    @Test("이름이 20자를 넘으면 거부하고 이전 이름을 지킨다")
    func nameOverTwentyIsRejected() {
        var draft = makeDraft(name: "원래 이름")

        #expect(throws: CollectionDraft.ValidationError.nameOverLimit(max: 20)) {
            try draft.updateName(String(repeating: "가", count: 21))
        }
        #expect(draft.name == "원래 이름")
    }

    @Test("남은 이름 글자 수는 20에서 지금 길이를 뺀 값이다")
    func remainingNameCount() {
        let draft = makeDraft(name: "다섯글자야")

        let remains = draft.remainsNameCount()

        #expect(remains == 20 - 5)
    }

    @Test("설명은 60자까지 입력할 수 있다")
    func descriptionAcceptsUpToSixty() throws {
        var draft = makeDraft()
        let description = String(repeating: "가", count: 60)

        try draft.updateDescription(description)

        #expect(draft.description == description)
    }

    @Test("설명이 60자를 넘으면 거부하고 이전 설명을 지킨다")
    func descriptionOverSixtyIsRejected() {
        var draft = makeDraft(description: "원래 설명")

        #expect(throws: CollectionDraft.ValidationError.descriptionOverLimit(max: 60)) {
            try draft.updateDescription(String(repeating: "가", count: 61))
        }
        #expect(draft.description == "원래 설명")
    }

    @Test("남은 설명 글자 수는 60에서 지금 길이를 뺀 값이다")
    func remainingDescriptionCount() {
        let draft = makeDraft(description: "다섯글자야")

        let remains = draft.remainsDescriptionCount()

        #expect(remains == 60 - 5)
    }

    // MARK: - 수정하기 열기

    @Test("수정하기를 열면 저장된 컬렉션 내용이 그대로 채워진다")
    func editingFillsSavedCollection() {
        let detail = makeDetail(
            name: "취향 저격 로판",
            description: "여주가 강한 로맨스 판타지",
            isPrivate: true,
            novelIDs: [NovelID(9), NovelID(5)],
            representativeNovelID: NovelID(5)
        )

        let draft = CollectionDraft(from: detail)

        #expect(draft.name == "취향 저격 로판")
        #expect(draft.description == "여주가 강한 로맨스 판타지")
        #expect(draft.isPrivate == true)
        #expect(draft.novelIDs == [NovelID(9), NovelID(5)])
        #expect(draft.representativeNovelID == NovelID(5))
    }

    @Test("설명이 없던 컬렉션은 수정하기를 열면 설명이 비어 있다")
    func editingCollectionWithoutDescription() {
        let detail = makeDetail(description: nil)

        let draft = CollectionDraft(from: detail)

        #expect(draft.description == "")
    }

    @Test("저장된 컬렉션이 제한을 넘으면 넘는 부분을 잘라 채운다")
    func editingCutsOverLimitValues() {
        // 넘치는 마지막 글자만 다르게 둬서, 잘려 나간 쪽이 뒤인지 확인한다.
        let detail = makeDetail(
            name: String(repeating: "가", count: 20) + "나",
            description: String(repeating: "가", count: 60) + "나",
            novelIDs: (1...101).map { NovelID($0) }
        )

        let draft = CollectionDraft(from: detail)

        #expect(draft.name == String(repeating: "가", count: 20))
        #expect(draft.description == String(repeating: "가", count: 60))
        #expect(draft.novelIDs == (1...100).map { NovelID($0) })
    }

    // MARK: - 작품 추가·빼기

    @Test("작품을 추가하면 목록 끝에 붙는다")
    func addingNovelAppends() throws {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        try draft.addNovel(NovelID(2))

        #expect(draft.novelIDs == [NovelID(1), NovelID(2)])
    }

    @Test("이미 담긴 작품은 다시 추가할 수 없다")
    func addingDuplicatedNovelIsRejected() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.duplicatedNovel) {
            try draft.addNovel(NovelID(1))
        }
        #expect(draft.novelIDs == [NovelID(1)])
    }

    @Test("작품이 100개면 더 추가할 수 없다")
    func addingOverHundredIsRejected() {
        let novelIDs = (1...100).map { NovelID($0) }
        var draft = makeDraft(novelIDs: novelIDs)

        #expect(throws: CollectionDraft.ValidationError.novelOverLimit(max: 100)) {
            try draft.addNovel(NovelID(101))
        }
        #expect(draft.novelIDs == novelIDs)
    }

    @Test("작품을 빼면 목록에서 사라진다")
    func removingNovelDropsIt() {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])

        draft.removeNovel(NovelID(1))

        #expect(draft.novelIDs == [NovelID(2)])
    }

    // MARK: - 작품 목록 바꾸기

    @Test("작품 목록을 새 목록으로 통째로 바꿀 수 있다")
    func settingNovelsReplacesAll() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])

        try draft.setNovels([NovelID(3), NovelID(4), NovelID(5)])

        #expect(draft.novelIDs == [NovelID(3), NovelID(4), NovelID(5)])
    }

    @Test("새 목록이 100개여도 통째로 바꿀 수 있다")
    func settingNovelsAcceptsUpToHundred() throws {
        var draft = makeDraft(novelIDs: [NovelID(1)])
        let novelIDs = (1...100).map { NovelID($0) }

        try draft.setNovels(novelIDs)

        #expect(draft.novelIDs == novelIDs)
    }

    @Test("새 목록이 100개를 넘으면 바꿀 수 없다")
    func settingOverHundredNovelsIsRejected() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.novelOverLimit(max: 100)) {
            try draft.setNovels((1...101).map { NovelID($0) })
        }
        #expect(draft.novelIDs == [NovelID(1)])
    }

    @Test("새 목록에 같은 작품이 두 번 있으면 바꿀 수 없다")
    func settingDuplicatedNovelsIsRejected() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.duplicatedNovel) {
            try draft.setNovels([NovelID(2), NovelID(3), NovelID(2)])
        }
        #expect(draft.novelIDs == [NovelID(1)])
    }

    // MARK: - 대표 작품

    @Test("담긴 작품을 대표로 고를 수 있다")
    func choosingIncludedNovelAsRepresentative() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])

        try draft.setRepresentativeNovel(NovelID(2))

        #expect(draft.representativeNovelID == NovelID(2))
    }

    @Test("담기지 않은 작품은 대표로 고를 수 없다")
    func choosingMissingNovelAsRepresentativeIsRejected() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.representativeNovelNotIncluded) {
            try draft.setRepresentativeNovel(NovelID(99))
        }
        #expect(draft.representativeNovelID == nil)
    }

    @Test("대표를 고르지 않았으면 첫 작품이 대표다")
    func firstNovelIsRepresentativeByDefault() {
        let draft = makeDraft(novelIDs: [NovelID(7), NovelID(3)])

        let representative = draft.effectiveRepresentativeNovelID

        #expect(representative == NovelID(7))
    }

    @Test("대표를 골랐으면 고른 작품이 대표다")
    func chosenNovelIsRepresentative() {
        let draft = makeDraft(novelIDs: [NovelID(7), NovelID(3)], representativeNovelID: NovelID(3))

        let representative = draft.effectiveRepresentativeNovelID

        #expect(representative == NovelID(3))
    }

    @Test("작품이 없으면 대표도 없다")
    func noRepresentativeWithoutNovel() {
        let draft = makeDraft(novelIDs: [])

        let representative = draft.effectiveRepresentativeNovelID

        #expect(representative == nil)
    }

    // MARK: - 작품이 빠질 때 대표

    @Test("대표로 고른 작품을 빼면 대표 선택도 풀린다")
    func removingRepresentativeClearsIt() {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)], representativeNovelID: NovelID(1))

        draft.removeNovel(NovelID(1))

        #expect(draft.representativeNovelID == nil)
    }

    @Test("대표로 고르지 않은 작품을 빼면 대표 선택은 그대로다")
    func removingOtherNovelKeepsRepresentative() {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)], representativeNovelID: NovelID(1))

        draft.removeNovel(NovelID(2))

        #expect(draft.representativeNovelID == NovelID(1))
    }

    @Test("대표로 고른 작품이 새 목록에 없으면 대표 선택도 풀린다")
    func settingNovelsWithoutRepresentativeClearsIt() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)], representativeNovelID: NovelID(1))

        try draft.setNovels([NovelID(2), NovelID(3)])

        #expect(draft.representativeNovelID == nil)
    }

    @Test("대표로 고른 작품이 새 목록에도 있으면 대표 선택은 그대로다")
    func settingNovelsWithRepresentativeKeepsIt() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)], representativeNovelID: NovelID(1))

        try draft.setNovels([NovelID(3), NovelID(1)])

        #expect(draft.representativeNovelID == NovelID(1))
    }

    // MARK: - 나만 보기

    @Test("컬렉션을 새로 만들 때 나만 보기는 꺼져 있다")
    func privateIsOffForNewCollection() {
        let draft = CollectionDraft()

        #expect(draft.isPrivate == false)
    }

    @Test("꺼진 나만 보기를 누르면 켜진다")
    func togglingPrivateTurnsItOn() {
        var draft = makeDraft(isPrivate: false)

        draft.togglePrivate()

        #expect(draft.isPrivate == true)
    }

    // MARK: - Helpers

    private func makeDraft(
        name: String = "컬렉션",
        description: String = "설명",
        isPrivate: Bool = false,
        novelIDs: [NovelID] = [NovelID(1)],
        representativeNovelID: NovelID? = nil
    ) -> CollectionDraft {
        CollectionDraft(
            name: name,
            description: description,
            isPrivate: isPrivate,
            novelIDs: novelIDs,
            representativeNovelID: representativeNovelID
        )
    }

    private func makeDetail(
        name: String = "컬렉션",
        description: String? = "설명",
        isPrivate: Bool = false,
        novelIDs: [NovelID] = [NovelID(1)],
        representativeNovelID: NovelID = NovelID(1)
    ) -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(1),
            name: name,
            description: description,
            owner: Author(userId: UserID(1), nickname: "웹소소", profileImage: nil),
            isMine: true,
            isPrivate: isPrivate,
            representativeNovelID: representativeNovelID,
            novels: novelIDs.map {
                CollectionNovel(id: $0, title: "작품", author: "작가", thumbnailImage: nil)
            },
            likeCount: 0,
            isLiked: false
        )
    }
}
