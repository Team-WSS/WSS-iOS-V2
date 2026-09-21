//
//  CollectionDataDemoView.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionData
import CollectionDomain
import BaseDomain
import Networking
import BaseData
import Logger

struct CollectionDataDemoView: View {

    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var isLoading: Bool = false
    @State private var userIDText: String = "1"
    @State private var collectionIDText: String = ""

    /// 다음 페이지 호출에 쓸 서버 발급 커서. 페이지네이션이 실제로 이어지는지 Demo에서 확인하려면 들고 있어야 한다.
    @State private var nextCursor: String?

    private let repository: any CollectionRepository

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let logger = DataLogger(moduleName: "CollectionData", underlying: OSLogger.collection)
        self.repository = CollectionDataFactory.makeRepository(network: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                inputFields
                listButtons
                detailButtons

                ScrollView {
                    Text(log)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Collection Demo")
            .overlay { if isLoading { ProgressView() } }
        }
    }

    private var inputFields: some View {
        HStack {
            TextField("userID", text: $userIDText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            TextField("collectionID", text: $collectionIDText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
        }
        .padding(.horizontal)
    }

    private var listButtons: some View {
        VStack(spacing: 8) {
            HStack {
                Button("미리보기(size=3)") { Task { await fetchPreviews() } }
                Button("목록 첫 페이지") { Task { await fetchCollections(useCursor: false) } }
                Button("다음 페이지") { Task { await fetchCollections(useCursor: true) } }
            }
            Button("좋아요한 컬렉션") { Task { await fetchLikedCollections() } }
        }
        .buttonStyle(.bordered)
    }

    private var detailButtons: some View {
        HStack {
            Button("상세(최신순)") { Task { await fetchDetail(sortType: .recent) } }
            Button("상세(오래된순)") { Task { await fetchDetail(sortType: .old) } }
            Button("좋아요") { Task { await toggleLike(isLike: true) } }
            Button("좋아요 취소") { Task { await toggleLike(isLike: false) } }
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - API 호출

private extension CollectionDataDemoView {

    var userID: UserID { UserID(Int(userIDText) ?? 0) }
    var collectionID: CollectionID { CollectionID(Int(collectionIDText) ?? 0) }

    func fetchPreviews() async {
        await run {
            let (previews, totalCount) = try await repository.fetchCollectionPreviews(userID: userID, size: 3)
            return """
            미리보기 \(previews.count)개 / 전체 \(totalCount)개
            \(previews.map { "· \($0.name) — 대표: \($0.representativeNovel.title)" }.joined(separator: "\n"))
            """
        }
    }

    func fetchCollections(useCursor: Bool) async {
        await run {
            let (page, totalCount) = try await repository.fetchCollections(
                userID: userID,
                cursor: useCursor ? nextCursor : nil,
                size: 10
            )
            nextCursor = page.nextCursor

            return """
            카드 \(page.items.count)개 / 전체 \(totalCount)개 / hasNext \(page.hasNext)
            nextCursor: \(page.nextCursor ?? "없음")
            \(page.items.map(describe(card:)).joined(separator: "\n"))
            """
        }
    }

    func fetchLikedCollections() async {
        await run {
            let (page, totalCount) = try await repository.fetchLikedCollections(cursor: nil, size: 10)
            return """
            좋아요한 컬렉션 \(page.items.count)개 / 전체 \(totalCount)개
            \(page.items.map(describe(card:)).joined(separator: "\n"))
            """
        }
    }

    func fetchDetail(sortType: SortType) async {
        await run {
            let detail = try await repository.fetchCollectionDetail(id: collectionID, sortType: sortType)
            return """
            \(detail.name) (\(detail.isPrivate ? "나만 보는" : "공개"))
            소유자: \(detail.owner.nickname) / 내 컬렉션: \(detail.isMine)
            좋아요 \(detail.likeCount) / 눌렀나: \(detail.isLiked)
            작품 \(detail.novelCount)개, 정렬 \(sortType)
            \(detail.novels.map { "· \($0.title) — \($0.author)" }.joined(separator: "\n"))
            """
        }
    }

    func toggleLike(isLike: Bool) async {
        await run {
            if isLike {
                try await repository.likeCollection(id: collectionID)
            } else {
                try await repository.unlikeCollection(id: collectionID)
            }
            return "좋아요 \(isLike ? "등록" : "취소") 성공 (서버가 멱등이라 반복 호출도 성공한다)"
        }
    }

    /// 카드에서 확인할 값들 — 대표 작품이 미리보기에 함께 오는지, novelCount가 미리보기 개수와 다른지가 핵심이다.
    func describe(card: CollectionCard) -> String {
        """
        · \(card.name) [\(card.isPrivate ? "나만 보는" : "공개")]
          전체 \(card.novelCount)개 / 미리보기 \(card.recentNovels.count)개
          미리보기: \(card.recentNovels.map(\.title).joined(separator: ", "))
        """
    }

    func run(_ operation: @escaping () async throws -> String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            log = try await operation()
        } catch let error as RepositoryError {
            log = "❌ RepositoryError.\(error)"
        } catch {
            log = "❌ \(error)"
        }
    }
}
