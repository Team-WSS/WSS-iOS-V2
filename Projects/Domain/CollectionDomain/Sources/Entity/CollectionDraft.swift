//
//  CollectionDraft.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 컬렉션 만들기·수정하기 화면이 편집하는 초안. 생성과 수정이 같은 입력 계약을 쓴다.
///
/// 제한값은 서버가 검증해 에러로 돌려주지만(`COLLECTION-002`·`COLLECTION-004`, 이름 공백 등),
/// 화면은 그 전에 완료 버튼을 잠가야 하므로 같은 규칙을 여기서도 판단한다 → `isSubmittable`.
public struct CollectionDraft: Equatable, Sendable {

    public private(set) var name: String
    public private(set) var description: String
    public private(set) var isPrivate: Bool

    /// 담긴 작품. **배열 순서가 그대로 표시 순서로 저장된다**(앞쪽이 최신·우선).
    /// 서버는 순서를 재정렬하지 않으므로 화면에 보이는 순서 그대로 넘겨야 한다.
    public private(set) var novelIDs: [NovelID]

    /// 카드 표지로 쓸 대표 작품. `novelIDs`에 없는 작품을 지정하면 서버가 거부한다(`COLLECTION-004`).
    public private(set) var representativeNovelID: NovelID?

    // MARK: - init

    public init(
        name: String = "",
        description: String = "",
        isPrivate: Bool = false,
        novelIDs: [NovelID] = [],
        representativeNovelID: NovelID? = nil
    ) {
        self.name = String(name.prefix(Self.maxNameCount))
        self.description = String(description.prefix(Self.maxDescriptionCount))
        self.isPrivate = isPrivate
        self.novelIDs = Array(novelIDs.prefix(Self.maxNovelCount))
        self.representativeNovelID = representativeNovelID
    }

    /// 수정하기 화면 진입용. 이미 저장된 컬렉션을 편집 가능한 초안으로 되돌린다.
    public init(from detail: CollectionDetail) {
        self.init(
            name: detail.name,
            description: detail.description ?? "",
            isPrivate: detail.isPrivate,
            novelIDs: detail.novels.map(\.id),
            representativeNovelID: detail.representativeNovelID
        )
    }

    // MARK: - Policy

    public static let maxNameCount: Int = 20
    public static let maxDescriptionCount: Int = 60
    public static let minNovelCount: Int = 1
    public static let maxNovelCount: Int = 100

    public enum ValidationError: Error, Equatable {
        case nameOverLimit(max: Int)
        case descriptionOverLimit(max: Int)
        case novelOverLimit(max: Int)
        case duplicatedNovel
        case representativeNovelNotIncluded
    }

    /// 완료 버튼 활성화 조건. 이름이 공백이 아니고 작품이 최소 하나 있으면 제출할 수 있다.
    /// 설명은 선택 항목이라 비어 있어도 된다.
    public var isSubmittable: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && novelIDs.count >= Self.minNovelCount
    }

    /// 제출 시점에 서버로 보낼 대표 작품. 서버는 이 값을 필수로 요구하는데 화면에서는 아직 고르지 않았을 수 있어,
    /// 미지정이면 표시 순서 첫 작품(= 가장 최신)을 대표로 본다.
    public var effectiveRepresentativeNovelID: NovelID? {
        representativeNovelID ?? novelIDs.first
    }

    public mutating func updateName(_ newValue: String) throws(ValidationError) {
        guard newValue.count <= Self.maxNameCount else {
            throw .nameOverLimit(max: Self.maxNameCount)
        }
        name = newValue
    }

    public mutating func updateDescription(_ newValue: String) throws(ValidationError) {
        guard newValue.count <= Self.maxDescriptionCount else {
            throw .descriptionOverLimit(max: Self.maxDescriptionCount)
        }
        description = newValue
    }

    public mutating func togglePrivate() {
        isPrivate.toggle()
    }

    public mutating func addNovel(_ id: NovelID) throws(ValidationError) {
        guard novelIDs.contains(id) == false else { throw .duplicatedNovel }
        guard novelIDs.count < Self.maxNovelCount else {
            throw .novelOverLimit(max: Self.maxNovelCount)
        }
        novelIDs.append(id)
    }

    /// 대표 작품을 지운 경우 대표 지정도 함께 풀린다 — 없는 작품을 대표로 둔 채 제출하면 서버가 거부한다.
    public mutating func removeNovel(_ id: NovelID) {
        novelIDs.removeAll { $0 == id }
        if representativeNovelID == id {
            representativeNovelID = nil
        }
    }

    /// 작품 리스트 전체를 새 선택 결과로 교체한다("작품 추가" 화면이 반환하는 편집 결과 전체 반영용 —
    /// 그 화면은 추가뿐 아니라 기존 선택 해제도 가능해 append가 아니라 통째 교체가 맞는 계약이다).
    /// count 상한은 `addNovel`과 동일하게 throw — 선택 화면이 UI에서 이미 100개로 막아두므로 실사용에서는
    /// 도달하지 않지만, "사용자 입력 검증은 거부"(clamp 아님) 방침을 `updateName`과 동일하게 지킨다.
    /// 대표 작품이 새 목록에 더 이상 없으면 대표 지정도 함께 풀린다(`removeNovel`과 같은 이유).
    public mutating func setNovels(_ ids: [NovelID]) throws(ValidationError) {
        guard ids.count <= Self.maxNovelCount else {
            throw .novelOverLimit(max: Self.maxNovelCount)
        }
        novelIDs = ids
        if let representativeNovelID, !ids.contains(representativeNovelID) {
            self.representativeNovelID = nil
        }
    }

    public mutating func setRepresentativeNovel(_ id: NovelID) throws(ValidationError) {
        guard novelIDs.contains(id) else { throw .representativeNovelNotIncluded }
        representativeNovelID = id
    }

    public func remainsNameCount() -> Int {
        Self.maxNameCount - name.count
    }

    public func remainsDescriptionCount() -> Int {
        Self.maxDescriptionCount - description.count
    }
}
