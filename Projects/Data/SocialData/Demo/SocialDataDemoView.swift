//
//  SocialDataDemoView.swift
//  SocialDataDemo
//
//  Created by WonsunLee on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SocialData
import SocialDomain
import BaseDomain
import Networking

struct SocialDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var userIDText: String = ""
    @State private var blockIDText: String = ""
    @State private var feedIDText: String = ""
    @State private var commentIDText: String = ""
    @State private var isLoading: Bool = false

    private let repository: SocialRepository

    init() {
        let client = NetworkingClient()
        self.repository = SocialDataFactory.makeSocialRepository(client: client)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    blockSection
                    Divider()
                    reportFeedSection
                    Divider()
                    reportCommentSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Social Demo")
        }
    }

    // MARK: - Sections

    private var blockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Block").font(.headline).padding(.horizontal)

            HStack {
                TextField("유저 ID", text: $userIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                TextField("차단 ID", text: $blockIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Button("차단") { Task { await blockUser() } }
                Button("해제") { Task { await unblockUser() } }
                Button("목록 조회") { Task { await loadBlockedUsers() } }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private var reportFeedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report Feed").font(.headline).padding(.horizontal)

            TextField("피드 ID", text: $feedIDText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Button("스포일러 신고") { Task { await reportSpoilerFeed() } }
                Button("부적절 신고") { Task { await reportImproperFeed() } }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private var reportCommentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report Comment").font(.headline).padding(.horizontal)

            HStack {
                TextField("피드 ID", text: $feedIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                TextField("댓글 ID", text: $commentIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Button("스포일러 신고") { Task { await reportSpoilerComment() } }
                Button("부적절 신고") { Task { await reportImproperComment() } }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private var logSection: some View {
        ScrollView {
            Text(log)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Computed IDs

    private var userID: UserID? {
        guard let value = Int(userIDText) else { return nil }
        return UserID(value)
    }

    private var blockID: BlockID? {
        guard let value = Int(blockIDText) else { return nil }
        return BlockID(value)
    }

    private var feedID: FeedID? {
        guard let value = Int(feedIDText) else { return nil }
        return FeedID(value)
    }

    private var commentID: CommentID? {
        guard let value = Int(commentIDText) else { return nil }
        return CommentID(value)
    }

    // MARK: - Actions

    private func blockUser() async {
        guard let userID else { log = "유저 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.blockUser(id: userID)
            log = "차단 성공 (userID: \(userID.value))"
        } catch {
            log = "차단 실패\n\(error)"
        }
    }

    private func unblockUser() async {
        guard let blockID else { log = "차단 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.unblockUser(id: blockID)
            log = "차단 해제 성공 (blockID: \(blockID.value))"
        } catch {
            log = "차단 해제 실패\n\(error)"
        }
    }

    private func loadBlockedUsers() async {
        isLoading = true; defer { isLoading = false }
        do {
            let users = try await repository.loadBlockedUsers()
            log = formatBlockedUsers(users)
        } catch {
            log = "차단 목록 조회 실패\n\(error)"
        }
    }

    private func reportSpoilerFeed() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportSpoilerFeed(id: feedID)
            log = "피드 스포일러 신고 성공 (feedID: \(feedID.value))"
        } catch {
            log = "피드 스포일러 신고 실패\n\(error)"
        }
    }

    private func reportImproperFeed() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportImproperFeed(id: feedID)
            log = "피드 부적절 신고 성공 (feedID: \(feedID.value))"
        } catch {
            log = "피드 부적절 신고 실패\n\(error)"
        }
    }

    private func reportSpoilerComment() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        guard let commentID else { log = "댓글 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportSpoilerComment(feedID: feedID, commentID: commentID)
            log = "댓글 스포일러 신고 성공 (feedID: \(feedID.value), commentID: \(commentID.value))"
        } catch {
            log = "댓글 스포일러 신고 실패\n\(error)"
        }
    }

    private func reportImproperComment() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        guard let commentID else { log = "댓글 ID를 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportImproperComment(feedID: feedID, commentID: commentID)
            log = "댓글 부적절 신고 성공 (feedID: \(feedID.value), commentID: \(commentID.value))"
        } catch {
            log = "댓글 부적절 신고 실패\n\(error)"
        }
    }

    // MARK: - Formatters

    private func formatBlockedUsers(_ users: [BlockedUser]) -> String {
        if users.isEmpty { return "차단 목록 없음" }
        var text = "차단 유저 \(users.count)명\n\n"
        for user in users {
            text += "[\(user.blockID.value)] \(user.nickname) (userID: \(user.userID.value))\n"
        }
        return text
    }
}
