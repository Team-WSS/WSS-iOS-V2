//
//  NovelReviewDataDemoView.swift
//  NovelReviewDataDemo
//

import SwiftUI

import BaseData
import BaseDomain
import Logger
import Networking
import NovelReviewData
import NovelReviewDomain

// MARK: - Log capture

@Observable
private final class LogCapture: Logger {
    var text: String = ""

    func debug(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟦 \(message)" }
    }
    func info(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟩 \(message)" }
    }
    func error(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟥 \(message)" }
    }
    func clear() {
        DispatchQueue.main.async { self.text = "" }
    }
}

// MARK: - Demo View

struct NovelReviewDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var novelIDText: String = ""
    @State private var selectedStatus: ReadingStatus = .watching
    @State private var isLoading: Bool = false

    private let repository: NovelReviewRepository
    private let logCapture: LogCapture

    init() {
        let logCapture = LogCapture()
        let networkLogger = DefaultNetworkLogger(base: logCapture, showBody: true, showHost: false)
        let client = NetworkingClient(logger: networkLogger)
        let dataLogger = DataLogger(moduleName: "NovelReview", underlying: logCapture)
        self.logCapture = logCapture
        self.repository = NovelReviewDataFactory.makeRepository(client: client, logger: dataLogger)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    reviewSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("NovelReview Demo")
        }
    }

    // MARK: - Sections

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Novel Review").font(.headline).padding(.horizontal)

            HStack {
                TextField("소설 ID", text: $novelIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)

            HStack {
                Text("독서 상태")
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedStatus) {
                    Text("읽는 중").tag(ReadingStatus.watching)
                    Text("읽음").tag(ReadingStatus.watched)
                    Text("하차").tag(ReadingStatus.quit)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                demoButton("리뷰 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                    Task { await loadReview() }
                }
                demoButton("리뷰 저장", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await saveReview() }
                }
                demoButton("리뷰 삭제", bg: Color(red: 1.0, green: 0.92, blue: 0.92), fg: .red) {
                    Task { await deleteReview() }
                }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
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
            Text(log + logCapture.text)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Computed

    private var novelID: NovelID? {
        guard let value = Int(novelIDText) else { return nil }
        return NovelID(value)
    }

    // MARK: - Actions

    private func loadReview() async {
        guard let novelID else { log = "소설 ID를 입력해주세요."; return }
        logCapture.clear()
        isLoading = true; defer { isLoading = false }
        do {
            let draft = try await repository.loadNovelReviewDraft(novelID: novelID)
            if let draft {
                log = "리뷰 조회 성공\n소설 ID: \(novelID.value)\n상태: \(draft.status)\n평점: \(draft.rating.map { "\($0)" } ?? "없음")\n키워드: \(draft.keywords.count)개"
            } else {
                log = "리뷰 없음 (novelID: \(novelID.value))"
            }
        } catch {
            log = "리뷰 조회 실패\n\(error)"
        }
    }

    private func saveReview() async {
        guard let novelID else { log = "소설 ID를 입력해주세요."; return }
        logCapture.clear()
        isLoading = true; defer { isLoading = false }
        let draft = NovelReviewDraft(novelID: novelID, status: selectedStatus)
        do {
            try await repository.save(draft: draft)
            log = "리뷰 저장 성공\n소설 ID: \(novelID.value)\n상태: \(selectedStatus)"
        } catch {
            log = "리뷰 저장 실패\n\(error)"
        }
    }

    private func deleteReview() async {
        guard let novelID else { log = "소설 ID를 입력해주세요."; return }
        novelIDText = ""
        logCapture.clear()
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.deleteNovelReview(novelID: novelID)
            log = "리뷰 삭제 성공 (novelID: \(novelID.value))"
        } catch {
            log = "리뷰 삭제 실패\n\(error)"
        }
    }
}
