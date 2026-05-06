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
import BaseData

struct SocialDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var userIDText: String = ""
    @State private var blockIDText: String = ""
    @State private var feedIDText: String = ""
    @State private var commentFeedIDText: String = ""
    @State private var commentIDText: String = ""
    @State private var isLoading: Bool = false

    private let repository: SocialRepository

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
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
                TextField("차단할 유저 ID", text: $userIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                demoButton("차단", bg: Color(red: 1.0, green: 0.92, blue: 0.92), fg: .red) {
                    Task { await blockUser() }
                }
            }
            .padding(.horizontal)

            HStack {
                TextField("해제할 차단 ID (목록의 [ ] 값)", text: $blockIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                demoButton("해제", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await unblockUser() }
                }
            }
            .padding(.horizontal)

            demoButton("목록 조회", bg: Color(red: 0.92, green: 0.90, blue: 0.99), fg: .indigo) {
                Task { await loadBlockedUsers() }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private var reportFeedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report Feed").font(.headline).padding(.horizontal)

            TextField("피드 ID", text: $feedIDText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .padding(.horizontal)

            HStack(spacing: 8) {
                demoButton("스포일러 신고", bg: Color(red: 1.0, green: 0.94, blue: 0.88), fg: .orange) {
                    Task { await reportSpoilerFeed() }
                }
                demoButton("부적절 신고", bg: Color(red: 0.99, green: 0.90, blue: 0.95), fg: .pink) {
                    Task { await reportImproperFeed() }
                }
            }
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private var reportCommentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report Comment").font(.headline).padding(.horizontal)

            HStack {
                TextField("피드 ID", text: $commentFeedIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                TextField("댓글 ID", text: $commentIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                demoButton("스포일러 신고", bg: Color(red: 1.0, green: 0.94, blue: 0.88), fg: .orange) {
                    Task { await reportSpoilerComment() }
                }
                demoButton("부적절 신고", bg: Color(red: 0.99, green: 0.90, blue: 0.95), fg: .pink) {
                    Task { await reportImproperComment() }
                }
            }
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private func demoButton(
        _ title: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(fg)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
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

    private var commentFeedID: FeedID? {
        guard let value = Int(commentFeedIDText) else { return nil }
        return FeedID(value)
    }

    private var commentID: CommentID? {
        guard let value = Int(commentIDText) else { return nil }
        return CommentID(value)
    }

    // MARK: - Actions

    private func blockUser() async {
        guard let userID else { log = "유저 ID를 입력해주세요."; return }
        userIDText = ""
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
        blockIDText = ""
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
        feedIDText = ""
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
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportImproperFeed(id: feedID)
            log = "피드 부적절 신고 성공 (feedID: \(feedID.value))"
        } catch {
            log = "피드 부적절 신고 실패\n\(error)"
        }
    }

    private func reportSpoilerComment() async {
        guard let commentFeedID else { log = "피드 ID를 입력해주세요."; return }
        guard let commentID else { log = "댓글 ID를 입력해주세요."; return }
        commentFeedIDText = ""
        commentIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportSpoilerComment(feedID: commentFeedID, commentID: commentID)
            log = "댓글 스포일러 신고 성공 (feedID: \(commentFeedID.value), commentID: \(commentID.value))"
        } catch {
            log = "댓글 스포일러 신고 실패\n\(error)"
        }
    }

    private func reportImproperComment() async {
        guard let commentFeedID else { log = "피드 ID를 입력해주세요."; return }
        guard let commentID else { log = "댓글 ID를 입력해주세요."; return }
        commentFeedIDText = ""
        commentIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.reportImproperComment(feedID: commentFeedID, commentID: commentID)
            log = "댓글 부적절 신고 성공 (feedID: \(commentFeedID.value), commentID: \(commentID.value))"
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
