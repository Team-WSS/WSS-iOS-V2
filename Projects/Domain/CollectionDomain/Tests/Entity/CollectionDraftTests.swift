//
//  CollectionDraftTests.swift
//  CollectionDomainTests
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation

@testable import CollectionDomain
import BaseDomain

@Suite("CollectionDraft")
struct CollectionDraftTests {

    // MARK: - isSubmittable

    @Test("이름이 있고 작품이 하나 이상이면 제출할 수 있다")
    func submittableWithNameAndNovel() {
        let draft = makeDraft(name: "취향 저격 로판", novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable)
    }

    @Test("설명은 선택 항목이라 비어 있어도 제출할 수 있다")
    func submittableWithoutDescription() {
        let draft = makeDraft(name: "취향 저격 로판", description: "", novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable)
    }

    @Test("이름이 비어 있으면 제출할 수 없다")
    func notSubmittableWithoutName() {
        let draft = makeDraft(name: "", novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable == false)
    }

    @Test("이름이 공백 문자뿐이면 제출할 수 없다")
    func notSubmittableWithBlankName() {
        let draft = makeDraft(name: "   ", novelIDs: [NovelID(1)])

        #expect(draft.isSubmittable == false)
    }

    @Test("작품이 하나도 없으면 제출할 수 없다")
    func notSubmittableWithoutNovel() {
        let draft = makeDraft(name: "취향 저격 로판", novelIDs: [])

        #expect(draft.isSubmittable == false)
    }

    // MARK: - updateName

    @Test("이름을 20자까지는 입력할 수 있다")
    func updateNameAtLimit() throws {
        var draft = makeDraft()

        try draft.updateName(String(repeating: "가", count: 20))

        #expect(draft.name.count == 20)
    }

    @Test("이름이 20자를 넘으면 입력이 거부되고 이전 값이 남는다")
    func updateNameOverLimit() {
        var draft = makeDraft(name: "원래 이름")

        #expect(throws: CollectionDraft.ValidationError.nameOverLimit(max: 20)) {
            try draft.updateName(String(repeating: "가", count: 21))
        }
        #expect(draft.name == "원래 이름")
    }

    @Test("이름 남은 글자 수는 20에서 현재 길이를 뺀 값이다")
    func remainsNameCount() throws {
        var draft = makeDraft()

        try draft.updateName("다섯글자야")

        #expect(draft.remainsNameCount() == 15)
    }

    // MARK: - updateDescription

    @Test("설명을 60자까지는 입력할 수 있다")
    func updateDescriptionAtLimit() throws {
        var draft = makeDraft()

        try draft.updateDescription(String(repeating: "가", count: 60))

        #expect(draft.description.count == 60)
    }

    @Test("설명이 60자를 넘으면 입력이 거부된다")
    func updateDescriptionOverLimit() {
        var draft = makeDraft()

        #expect(throws: CollectionDraft.ValidationError.descriptionOverLimit(max: 60)) {
            try draft.updateDescription(String(repeating: "가", count: 61))
        }
    }

    // MARK: - init

    @Test("저장된 값으로 초안을 만들 때 제한을 넘는 이름은 잘려서 들어온다")
    func initTruncatesOverLimitName() {
        let draft = makeDraft(name: String(repeating: "가", count: 25))

        #expect(draft.name.count == 20)
    }

    @Test("수정하기 화면은 기존 컬렉션을 그대로 편집 가능한 초안으로 되돌린다")
    func initFromDetail() {
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
        #expect(draft.isPrivate)
        #expect(draft.novelIDs == [NovelID(9), NovelID(5)])
        #expect(draft.representativeNovelID == NovelID(5))
    }

    @Test("설명이 없던 컬렉션을 초안으로 되돌리면 설명은 빈 문자열이 된다")
    func initFromDetailWithoutDescription() {
        let detail = makeDetail(description: nil)

        let draft = CollectionDraft(from: detail)

        #expect(draft.description.isEmpty)
    }

    // MARK: - addNovel

    @Test("작품을 추가하면 표시 순서 끝에 붙는다")
    func addNovelAppends() throws {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        try draft.addNovel(NovelID(2))

        #expect(draft.novelIDs == [NovelID(1), NovelID(2)])
    }

    @Test("이미 담긴 작품은 다시 추가할 수 없다")
    func addDuplicatedNovel() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.duplicatedNovel) {
            try draft.addNovel(NovelID(1))
        }
        #expect(draft.novelIDs.count == 1)
    }

    @Test("작품이 100개면 더 추가할 수 없다")
    func addNovelOverLimit() {
        var draft = makeDraft(novelIDs: (1...100).map { NovelID($0) })

        #expect(throws: CollectionDraft.ValidationError.novelOverLimit(max: 100)) {
            try draft.addNovel(NovelID(101))
        }
    }

    // MARK: - removeNovel

    @Test("작품을 빼면 목록에서 사라진다")
    func removeNovel() {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])

        draft.removeNovel(NovelID(1))

        #expect(draft.novelIDs == [NovelID(2)])
    }

    @Test("대표로 지정한 작품을 빼면 대표 지정도 함께 풀린다")
    func removeRepresentativeNovel() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])
        try draft.setRepresentativeNovel(NovelID(1))

        draft.removeNovel(NovelID(1))

        #expect(draft.representativeNovelID == nil)
    }

    @Test("대표가 아닌 작품을 빼면 대표 지정은 그대로 남는다")
    func removeNonRepresentativeNovel() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])
        try draft.setRepresentativeNovel(NovelID(1))

        draft.removeNovel(NovelID(2))

        #expect(draft.representativeNovelID == NovelID(1))
    }

    // MARK: - setRepresentativeNovel

    @Test("담긴 작품 중 하나를 대표로 지정할 수 있다")
    func setRepresentativeNovel() throws {
        var draft = makeDraft(novelIDs: [NovelID(1), NovelID(2)])

        try draft.setRepresentativeNovel(NovelID(2))

        #expect(draft.representativeNovelID == NovelID(2))
    }

    @Test("담기지 않은 작품은 대표로 지정할 수 없다")
    func setRepresentativeNovelNotIncluded() {
        var draft = makeDraft(novelIDs: [NovelID(1)])

        #expect(throws: CollectionDraft.ValidationError.representativeNovelNotIncluded) {
            try draft.setRepresentativeNovel(NovelID(99))
        }
    }

    // MARK: - effectiveRepresentativeNovelID

    @Test("대표를 고르지 않았으면 표시 순서 첫 작품이 대표가 된다")
    func effectiveRepresentativeFallsBackToFirst() {
        let draft = makeDraft(novelIDs: [NovelID(7), NovelID(3)])

        #expect(draft.effectiveRepresentativeNovelID == NovelID(7))
    }

    @Test("대표를 골랐으면 첫 작품이 아니라 고른 작품이 대표가 된다")
    func effectiveRepresentativeUsesChosen() throws {
        var draft = makeDraft(novelIDs: [NovelID(7), NovelID(3)])

        try draft.setRepresentativeNovel(NovelID(3))

        #expect(draft.effectiveRepresentativeNovelID == NovelID(3))
    }

    @Test("작품이 하나도 없으면 대표도 없다")
    func effectiveRepresentativeWithoutNovel() {
        let draft = makeDraft(novelIDs: [])

        #expect(draft.effectiveRepresentativeNovelID == nil)
    }

    // MARK: - togglePrivate

    @Test("나만 보는 컬렉션은 기본적으로 꺼져 있다")
    func privateIsOffByDefault() {
        let draft = CollectionDraft()

        #expect(draft.isPrivate == false)
    }

    @Test("나만 보기를 토글하면 상태가 뒤집힌다")
    func togglePrivate() {
        var draft = makeDraft()

        draft.togglePrivate()

        #expect(draft.isPrivate)
    }
}

// MARK: - Helper

private extension CollectionDraftTests {

    func makeDraft(
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

    func makeDetail(
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
