//
//  CommentDataDemoView.swift
//  CommentDataDemo
//
//  Created by Seoyeon Choi on 4/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CommentData
import CommentDomain
import BaseDomain
import Networking
import BaseData
import Logger

struct CommentDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var feedIDText: String = ""
    @State private var commentIDText: String = ""
    @State private var commentContent: String = ""
    @State private var isLoading: Bool = false

    private let repository: CommentRepository

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let logger = DataLogger(moduleName: "CommentData", underlying: OSLogger.comment)
        self.repository = CommentDataFactory.makeRepository(client: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    TextField("피드 ID", text: $feedIDText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    TextField("댓글 ID", text: $commentIDText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal)

                TextField("댓글 내용 입력", text: $commentContent)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    Button("조회") {
                        Task { await fetchComments() }
                    }
                    Button("작성") {
                        Task { await submitComment() }
                    }
                    Button("수정") {
                        Task { await editComment() }
                    }
                    Button("삭제") {
                        Task { await deleteComment() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

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
            .navigationTitle("Comment Demo")
        }
    }

    private var feedID: FeedID? {
        guard let value = Int(feedIDText) else { return nil }
        return FeedID(value)
    }

    private var commentID: CommentID? {
        guard let value = Int(commentIDText) else { return nil }
        return CommentID(value)
    }

    private func fetchComments() async {
        guard let feedID else {
            log = "피드 ID를 입력해주세요."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let comments = try await repository.fetchComments(feedID: feedID)
            log = formatComments(comments)
        } catch {
            log = "댓글 조회 실패\n\(error)"
        }
    }

    private func submitComment() async {
        guard let feedID else {
            log = "피드 ID를 입력해주세요."
            return
        }
        guard !commentContent.isEmpty else {
            log = "댓글 내용을 입력해주세요."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let draft = CommentDraft(content: commentContent)
            try await repository.submitComment(feedID: feedID, draft: draft)
            log = "댓글 작성 성공"
        } catch {
            log = "댓글 작성 실패\n\(error)"
        }
    }

    private func editComment() async {
        guard let feedID else {
            log = "피드 ID를 입력해주세요."
            return
        }
        guard let commentID else {
            log = "댓글 ID를 입력해주세요."
            return
        }
        guard !commentContent.isEmpty else {
            log = "댓글 내용을 입력해주세요."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let draft = CommentDraft(content: commentContent)
            try await repository.editComment(id: commentID, feedID: feedID, draft: draft)
            log = "댓글 수정 성공"
        } catch {
            log = "댓글 수정 실패\n\(error)"
        }
    }

    private func deleteComment() async {
        guard let feedID else {
            log = "피드 ID를 입력해주세요."
            return
        }
        guard let commentID else {
            log = "댓글 ID를 입력해주세요."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.deleteComment(id: commentID, feedID: feedID)
            log = "댓글 삭제 성공"
        } catch {
            log = "댓글 삭제 실패\n\(error)"
        }
    }

    private func formatComments(_ comments: [FeedComment]) -> String {
        if comments.isEmpty {
            return "댓글 없음 (총 \(comments.count)개)"
        }

        var text = "댓글 \(comments.count)개\n\n"
        for comment in comments {
            text += "[\(comment.id)] \(comment.user.nickname)\n"
            text += "  \(comment.content)\n"
            text += "  \(comment.createdDate)"
            if comment.isModified { text += " (수정됨)" }
            if comment.isSpoiler { text += " [스포]" }
            text += "\n\n"
        }
        return text
    }
}
