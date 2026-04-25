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
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false

    private let repository: KeywordRepository

    init() {
        let client = NetworkingClient()
        let logger = DataLogger(moduleName: "KeywordData", underlying: OSLogger.keyword)
        self.repository = KeywordDataFactory.makeRepository(client: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    TextField("키워드 검색어 입력", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    Button("검색") {
                        Task { await searchKeywords() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                .padding(.horizontal)

                Button("전체 키워드 조회") {
                    Task { await fetchAllKeywords() }
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
            .navigationTitle("Keyword Demo")
        }
    }

    private func fetchAllKeywords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let groups = try await repository.fetchKeywords()
            log = formatKeywordGroups(groups, title: "전체 키워드")
        } catch {
            log = "❌ 전체 키워드 조회 실패\n\(error)"
        }
    }

    private func searchKeywords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let groups = try await repository.searchKeywords(searchText)
            log = formatKeywordGroups(groups, title: "검색 결과: \"\(searchText)\"")
        } catch {
            log = "❌ 키워드 검색 실패\n\(error)"
        }
    }

    private func formatKeywordGroups(_ groups: [KeywordGroup], title: String) -> String {
        if groups.isEmpty {
            return "ℹ️ \(title) — 결과 없음"
        }

        var text = "✅ \(title) (\(groups.count)개 그룹)\n\n"
        for group in groups {
            text += "📁 \(group.name)\n"
            for keyword in group.keywords {
                text += "  · \(keyword.name) (ID: \(keyword.id))\n"
            }
            text += "\n"
        }
        return text
    }
}
