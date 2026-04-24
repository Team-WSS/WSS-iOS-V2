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
import BaseData

struct NovelLoggerDemoView: View {
    @State private var logs: [LogEntry] = []

    private let osLogger = OSLogger.novel
    private let dataLogger = DataLogger(moduleName: "NovelData", underlying: OSLogger.novel)
    private let service: NovelService = DefaultNovelService(
        client: NetworkingClient(
            logger: ConsoleNetworkLogger(base: OSLogger.network)
        )
    )

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
                    asyncButton("기본 정보 (ID=1)", color: .indigo) {
                        await fetchNovelBasicInfo(novelID: 1)
                    }

                    asyncButton("상세 정보 (ID=1)", color: .indigo) {
                        await fetchNovelDetailInfo(novelID: 1)
                    }
                }

                HStack(spacing: 12) {
                    asyncButton("기본 정보 (ID=23)", color: .orange) {
                        await fetchNovelBasicInfo(novelID: 23)
                    }

                    asyncButton("상세 정보 (ID=23)", color: .orange) {
                        await fetchNovelDetailInfo(novelID: 23)
                    }
                }

                Divider()

                // MARK: 관심 등록/해제

                sectionHeader("관심 등록 / 해제")

                HStack(spacing: 12) {
                    asyncButton("관심 등록 (ID=1)", color: .teal) {
                        await postNovelInterest(novelID: 1)
                    }

                    asyncButton("관심 해제 (ID=1)", color: .pink) {
                        await deleteNovelInterest(novelID: 1)
                    }
                }

                Divider()

                // MARK: 검색

                sectionHeader("작품 검색")

                HStack(spacing: 12) {
                    asyncButton("일반 검색 '소녀'", color: .cyan) {
                        await searchNovelByText("소녀")
                    }

                    asyncButton("일반 검색 ''(빈값)", color: .orange) {
                        await searchNovelByText("")
                    }
                }

                Divider()

                // MARK: 서재 조회

                sectionHeader("서재 / 통계 조회")

                HStack(spacing: 12) {
                    asyncButton("내 서재 (userID=10035)", color: .mint) {
                        await fetchUserLibrary(userID: 10035)
                    }

                    asyncButton("등록 통계 (userID=10035)", color: .mint) {
                        await fetchRegisteredNovelStats(userID: 10035)
                    }
                }

                Divider()

                // MARK: OSLogger / DataLogger

                sectionHeader("OSLogger / DataLogger")

                HStack(spacing: 12) {
                    logButton("Debug", color: .blue) {
                        osLogger.debug("작품 상세 화면 진입")
                        appendLog(level: .debug, message: "debug: 작품 상세 화면 진입")
                    }

                    logButton("Info", color: .green) {
                        osLogger.info("작품 ID=42 정보 로드 완료")
                        appendLog(level: .info, message: "info: 작품 ID=42 정보 로드 완료")
                    }

                    logButton("Error", color: .red) {
                        dataLogger.logUnknownError(action: NovelAction.fetchNovel.text,
                                                   error: NSError(domain: "Test", code: 401))
                        appendLog(level: .error, message: "DataLogger: unknown error 401")
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

    private func fetchNovelBasicInfo(novelID: Int) async {
        appendLog(level: .debug, message: "GET /novels/\(novelID) 요청...")
        do {
            let response = try await service.getNovelBasicInfo(novelID: novelID)
            appendLog(level: .info,
                      message: "성공: \(response.novelTitle) | 장르: \(response.novelGenres) | 평점: \(response.novelRating)")
        } catch {
            logDataError(action: .fetchNovel, error: error)
        }
    }

    private func fetchNovelDetailInfo(novelID: Int) async {
        appendLog(level: .debug, message: "GET /novels/\(novelID)/info 요청...")
        do {
            let response = try await service.getNovelDetailInfo(novelID: novelID)
            appendLog(level: .info,
                      message: "성공: 설명 \(response.novelDescription.prefix(50))... | 플랫폼 \(response.platforms.count)개 | 보는중 \(response.watchingCount)")
        } catch {
            logDataError(action: .fetchNovel, error: error)
        }
    }

    private func postNovelInterest(novelID: Int) async {
        appendLog(level: .debug, message: "POST /novels/\(novelID)/is-interest 요청...")
        do {
            try await service.postNovelInterest(novelID: novelID)
            appendLog(level: .info, message: "성공: 관심 등록 완료")
        } catch {
            logDataError(action: .addInterest, error: error)
        }
    }

    private func deleteNovelInterest(novelID: Int) async {
        appendLog(level: .debug, message: "DELETE /novels/\(novelID)/is-interest 요청...")
        do {
            try await service.deleteNovelInterest(novelID: novelID)
            appendLog(level: .info, message: "성공: 관심 해제 완료")
        } catch {
            logDataError(action: .removeInterest, error: error)
        }
    }

    private func searchNovelByText(_ text: String) async {
        appendLog(level: .debug, message: "GET /novels?query=\(text) 요청...")
        do {
            let query = NormalSearchQuery(query: text, page: 0, size: 10)
            let response = try await service.getNormalSearchNovels(query: query)
            let titles = response.novels.prefix(3).map { $0.title }.joined(separator: ", ")
            appendLog(level: .info,
                      message: "성공: 총 \(response.resultCount)건 | \(titles)\(response.novels.count > 3 ? " ..." : "")")
        } catch {
            logDataError(action: .searchByText, error: error)
        }
    }

    private func fetchUserLibrary(userID: Int) async {
        appendLog(level: .debug, message: "GET /users/\(userID)/novels 요청...")
        do {
            let query = UserLibraryQuery(
                lastUserNovelId: 0, size: 10, sortCriteria: "RECENT",
                isInterest: false, readstatues: [], attractivePoints: [],
                novelRating: 0, query: "", updatedSince: ""
            )
            let response = try await service.getUserLibraryNovels(userID: userID, query: query)
            let titles = response.userNovels.prefix(3).map { $0.title }.joined(separator: ", ")
            appendLog(level: .info,
                      message: "성공: 총 \(response.userNovelCount)건 | \(titles)\(response.userNovels.count > 3 ? " ..." : "")")
        } catch {
            logDataError(action: .fetchUserLibrary, error: error)
        }
    }

    private func fetchRegisteredNovelStats(userID: Int) async {
        appendLog(level: .debug, message: "GET /users/\(userID)/user-novel-stats 요청...")
        do {
            let response = try await service.getUserRegisteredNovelStats(userID: userID)
            appendLog(level: .info,
                      message: "성공: 관심 \(response.interestNovelCount) | 보는중 \(response.watchingNovelCount) | 봤어요 \(response.watchedNovelCount) | 하차 \(response.quitNovelCount)")
        } catch {
            logDataError(action: .fetchRegisteredStats, error: error)
        }
    }

    private func logDataError(action: NovelAction, error: Error) {
        if let networkError = error as? NetworkingError {
            dataLogger.logNetworkError(action: action.text, error: networkError)
        } else {
            dataLogger.logUnknownError(action: action.text, error: error)
        }
        appendLog(level: .error, message: "실패: \(error)")
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func logButton(
        _ title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .tint(color)
            .font(.callout)
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
