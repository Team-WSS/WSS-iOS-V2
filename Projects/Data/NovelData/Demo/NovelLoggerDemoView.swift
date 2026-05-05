//
//  NovelLoggerDemoView.swift
//  NovelDataDemo
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import Logger
import Networking
import NovelData
import NovelDomain
import BaseDomain
import BaseData

struct NovelLoggerDemoView: View {
    @State private var logs: [LogEntry] = []
    @State private var isLoading: Bool = false

    private let repository: NovelRepository

    init() {
        let client = NetworkingClient()
        let userDefaults = UserDefaultsStorage()
        userDefaults.set(.userID, 10035)
        let logger = DataLogger(moduleName: "NovelData", underlying: OSLogger.novel)
        self.repository = NovelDataFactory.makeNovelRepository(client: client,
                                                               appStorage: userDefaults,
                                                               logger: logger)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                logListView
                    .frame(maxHeight: .infinity)
                Divider()
                buttonSection
                    .frame(maxHeight: 340)
            }
            .navigationTitle("NovelData Demo")
        }
    }

    // MARK: - Log List

    private var logListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logs) { entry in
                        logRow(entry)
                            .id(entry.id)
                    }
                }
                .padding()
            }
            .onChange(of: logs.count) {
                if let last = logs.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func logRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.timestamp)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(entry.level.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(entry.level.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Button Section

    private var buttonSection: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: 작품 정보 조회

                sectionHeader("작품 정보 조회")

                HStack(spacing: 12) {
                    asyncButton("작품 조회 (ID=1)", color: .indigo) {
                        await fetchNovel(novelID: 1)
                    }

                    asyncButton("작품 조회 (ID=23)", color: .orange) {
                        await fetchNovel(novelID: 23)
                    }
                }

                Divider()

                // MARK: 관심 등록/해제

                sectionHeader("관심 등록 / 해제")

                HStack(spacing: 12) {
                    asyncButton("관심 등록 (ID=1)", color: .teal) {
                        await addNovelInterest(novelID: 1)
                    }

                    asyncButton("관심 해제 (ID=1)", color: .pink) {
                        await removeNovelInterest(novelID: 1)
                    }
                }

                Divider()

                // MARK: 검색

                sectionHeader("작품 검색")

                HStack(spacing: 12) {
                    asyncButton("텍스트 검색 '소녀'", color: .cyan) {
                        await searchNovelByText("소녀")
                    }

                    asyncButton("텍스트 검색 ''(빈값)", color: .orange) {
                        await searchNovelByText("")
                    }
                }

                Divider()

                // MARK: 서재 / 통계

                sectionHeader("서재 / 통계 조회")

                HStack(spacing: 12) {
                    asyncButton("내 서재", color: .mint) {
                        await fetchMyLibraryNovels()
                    }

                    asyncButton("유저 서재 (ID=1)", color: .mint) {
                        await fetchUserLibraryNovels(userID: 1)
                    }
                }

                HStack(spacing: 12) {
                    asyncButton("등록 통계", color: .mint) {
                        await fetchRegisteredNovelStats()
                    }
                }

                Button("Clear") { logs.removeAll() }
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - API Calls

    private func fetchNovel(novelID: Int) async {
        appendLog(level: .debug, message: "작품 정보 조회 (ID=\(novelID)) 요청...")
        do {
            let info = try await repository.fetchNovel(id: NovelID(novelID))
            let novel = info.novel
            appendLog(level: .info,
                      message: "성공: \(novel.title) | 장르: \(info.genres) | 평점: \(novel.rating) | 피드: \(info.feedCount)개")
        } catch {
            appendError(action: .fetchNovel, error: error)
        }
    }

    private func addNovelInterest(novelID: Int) async {
        appendLog(level: .debug, message: "관심 등록 (ID=\(novelID)) 요청...")
        do {
            try await repository.addNovelInterest(id: NovelID(novelID))
            appendLog(level: .info, message: "성공: 관심 등록 완료")
        } catch {
            appendError(action: .addInterest, error: error)
        }
    }

    private func removeNovelInterest(novelID: Int) async {
        appendLog(level: .debug, message: "관심 해제 (ID=\(novelID)) 요청...")
        do {
            try await repository.removeNovelInterest(id: NovelID(novelID))
            appendLog(level: .info, message: "성공: 관심 해제 완료")
        } catch {
            appendError(action: .removeInterest, error: error)
        }
    }

    private func searchNovelByText(_ text: String) async {
        appendLog(level: .debug, message: "텍스트 검색 '\(text)' 요청...")
        do {
            let (paginated, totalCount) = try await repository.searchNovelByText(text)
            let titles = paginated.items.prefix(3).map { $0.title }.joined(separator: ", ")
            appendLog(level: .info,
                      message: "성공: 총 \(totalCount)건 | \(titles)\(paginated.items.count > 3 ? " ..." : "")")
        } catch {
            appendError(action: .searchByText(query: text), error: error)
        }
    }

    private func fetchMyLibraryNovels() async {
        appendLog(level: .debug, message: "내 서재 조회 요청...")
        do {
            let filter = MyLibraryFilter(
                isInterest: false,
                readingStatus: [],
                attractivePoint: [],
                ratingThreshold: nil,
                sortType: .recent
            )
            let (paginated, totalCount) = try await repository.fetchMyLibraryNovels(filter)
            let titles = paginated.items.prefix(3).map { $0.title }.joined(separator: ", ")
            appendLog(level: .info,
                      message: "성공: 총 \(totalCount)건 | \(titles)\(paginated.items.count > 3 ? " ..." : "")")
        } catch {
            appendError(action: .fetchMyLibrary, error: error)
        }
    }

    private func fetchUserLibraryNovels(userID: Int) async {
        appendLog(level: .debug, message: "유저 서재 조회 (ID=\(userID)) 요청...")
        do {
            let filter = LibraryFilter(sortType: .recent)
            let (paginated, totalCount) = try await repository.fetchUserLibraryNovels(id: UserID(userID), filter)
            let titles = paginated.items.prefix(3).map { $0.title }.joined(separator: ", ")
            appendLog(level: .info,
                      message: "성공: 총 \(totalCount)건 | \(titles)\(paginated.items.count > 3 ? " ..." : "")")
        } catch {
            appendError(action: .fetchUserLibrary, error: error)
        }
    }

    private func fetchRegisteredNovelStats() async {
        appendLog(level: .debug, message: "등록 작품 통계 조회 요청...")
        do {
            let stats = try await repository.fetchRegisteredNovelStats()
            appendLog(level: .info,
                      message: "성공: 관심 \(stats.interest) | 보는중 \(stats.watching) | 봤어요 \(stats.watched) | 하차 \(stats.quit)")
        } catch {
            appendError(action: .fetchRegisteredStats, error: error)
        }
    }

    // MARK: - Helpers

    private func appendError(action: NovelAction, error: Error) {
        appendLog(level: .error, message: "실패: \(error)")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func asyncButton(
        _ title: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button(title) { Task { await action() } }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .font(.callout)
            .disabled(isLoading)
    }

    private func appendLog(level: LogLevel, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())

        logs.append(LogEntry(
            timestamp: timestamp,
            level: level,
            message: message
        ))
    }
}

// MARK: - Models

private struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let level: LogLevel
    let message: String
}

private enum LogLevel {
    case debug, info, error

    var color: Color {
        switch self {
        case .debug: return .blue
        case .info:  return .green
        case .error: return .red
        }
    }

    var backgroundColor: Color {
        switch self {
        case .debug: return .blue.opacity(0.08)
        case .info:  return .green.opacity(0.08)
        case .error: return .red.opacity(0.08)
        }
    }
}
