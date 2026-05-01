//
//  KeywordDataDemoView.swift
//  KeywordDataDemo
//
//  Created by Seoyeon Choi on 4/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import KeywordData
import KeywordDomain
import Networking
import BaseData
import Logger

struct KeywordDataDemoView: View {
    @State private var logs: [LogEntry] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var localCount: Int = 0

    private let repository: KeywordRepository

    init() {
        let client = NetworkingClient()
        let logger = DataLogger(moduleName: "KeywordData", underlying: OSLogger.keyword)
        self.repository = KeywordDataFactory.makeRepository(client: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                statusBar

                searchBar

                actionButtons

                logList
            }
            .navigationTitle("Keyword Demo")
            .task {
                await initialSync()
            }
        }
    }

    // MARK: - 상단 상태 바

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(localCount > 0 ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(localCount > 0
                 ? "로컬 DB: \(localCount)개 그룹 저장됨"
                 : "로컬 DB: 비어있음")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - 검색 바

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("키워드 검색", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await searchKeywords() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Button("검색") {
                Task { await searchKeywords() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isLoading || searchText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 액션 버튼

    private var actionButtons: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "전체 조회",
                subtitle: "로컬 DB",
                icon: "cylinder.split.1x2",
                color: .blue
            ) {
                Task { await fetchAllKeywords() }
            }

            ActionButton(
                title: "서버 동기화",
                subtitle: "서버 → 로컬",
                icon: "arrow.triangle.2.circlepath",
                color: .green
            ) {
                Task { await syncKeywords() }
            }

            ActionButton(
                title: "로그 초기화",
                subtitle: "\(logs.count)개",
                icon: "trash",
                color: .red
            ) {
                logs.removeAll()
            }
        }
        .disabled(isLoading)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 로그 리스트

    private var logList: some View {
        List {
            if logs.isEmpty {
                ContentUnavailableView(
                    "로그 없음",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("앱 시작 시 자동으로 서버 동기화가 실행됩니다.")
                )
            }

            ForEach(logs) { entry in
                LogEntryRow(entry: entry)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func initialSync() async {
        appendLog(.info("앱 시작 — 서버 동기화 시작"))
        isLoading = true
        defer { isLoading = false }

        await repository.syncKeywords()
        appendLog(.success("서버 동기화 완료"))

        do {
            let groups = try await repository.fetchKeywords()
            localCount = groups.count

            if groups.isEmpty {
                appendLog(.warning("로컬 DB가 비어있음 (서버 응답 확인 필요)"))
            } else {
                appendLog(.keywordResult(groups, title: "동기화 후 로컬 키워드"))
            }
        } catch {
            appendLog(.error("동기화 후 로컬 조회 실패: \(error)"))
        }
    }

    private func syncKeywords() async {
        appendLog(.info("수동 서버 동기화 시작"))
        isLoading = true
        defer { isLoading = false }

        await repository.syncKeywords()
        appendLog(.success("서버 동기화 완료"))

        do {
            let groups = try await repository.fetchKeywords()
            localCount = groups.count
            appendLog(.keywordResult(groups, title: "동기화 후 로컬 키워드"))
        } catch {
            appendLog(.error("동기화 후 로컬 조회 실패: \(error)"))
        }
    }

    private func fetchAllKeywords() async {
        appendLog(.info("로컬 DB 전체 조회"))
        isLoading = true
        defer { isLoading = false }

        do {
            let groups = try await repository.fetchKeywords()
            localCount = groups.count
            appendLog(.keywordResult(groups, title: "로컬 전체 키워드"))
        } catch {
            appendLog(.error("전체 조회 실패: \(error)"))
        }
    }

    private func searchKeywords() async {
        let query = searchText
        appendLog(.info("로컬 검색: \"\(query)\""))
        isLoading = true
        defer { isLoading = false }

        do {
            let groups = try await repository.searchKeywords(query)
            appendLog(.keywordResult(groups, title: "검색 결과: \"\(query)\""))
        } catch {
            appendLog(.error("검색 실패: \(error)"))
        }
    }

    private func appendLog(_ entry: LogEntry) {
        withAnimation(.easeInOut(duration: 0.2)) {
            logs.insert(entry, at: 0)
        }
    }
}

// MARK: - Log Entry Model

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let type: LogType
    let message: String
    let detail: String?

    enum LogType {
        case info, success, warning, error, result
    }

    static func info(_ message: String) -> LogEntry {
        LogEntry(type: .info, message: message, detail: nil)
    }

    static func success(_ message: String) -> LogEntry {
        LogEntry(type: .success, message: message, detail: nil)
    }

    static func warning(_ message: String) -> LogEntry {
        LogEntry(type: .warning, message: message, detail: nil)
    }

    static func error(_ message: String) -> LogEntry {
        LogEntry(type: .error, message: message, detail: nil)
    }

    static func keywordResult(_ groups: [KeywordGroup], title: String) -> LogEntry {
        if groups.isEmpty {
            return LogEntry(type: .result, message: "\(title) — 결과 없음", detail: nil)
        }

        let totalKeywords = groups.flatMap(\.keywords).count
        var detail = ""
        for group in groups {
            detail += "[\(group.name)] \(group.keywords.count)개\n"
            for keyword in group.keywords.prefix(5) {
                detail += "  · \(keyword.name) (ID: \(keyword.id))\n"
            }
            if group.keywords.count > 5 {
                detail += "  ... 외 \(group.keywords.count - 5)개\n"
            }
        }

        return LogEntry(
            type: .result,
            message: "\(title): \(groups.count)개 그룹, \(totalKeywords)개 키워드",
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded: Bool = false

    private var icon: String {
        switch entry.type {
        case .info: "arrow.right.circle"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        case .result: "list.bullet.rectangle"
        }
    }

    private var iconColor: Color {
        switch entry.type {
        case .info: .blue
        case .success: .green
        case .warning: .orange
        case .error: .red
        case .result: .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.caption)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.message)
                        .font(.caption)
                        .fontWeight(entry.type == .result ? .medium : .regular)

                    Text(entry.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if entry.detail != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if entry.detail != nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }

            if isExpanded, let detail = entry.detail {
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 24)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

