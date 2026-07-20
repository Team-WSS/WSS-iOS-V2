//
//  SearchDataDemoView.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import SwiftUI

import SearchData
import SearchDomain
import Networking
import BaseData
import Logger

struct SearchDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var lastFetchedRecentSearchWords: [RecentSearchWord] = []

    private let repository: any RecentSearchRepository & SearchAutoCompletionRepository

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let logger = DataLogger(moduleName: "SearchData", underlying: OSLogger.search)
        self.repository = SearchDataFactory.makeRepository(network: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                apiButtons

                HStack {
                    TextField("자동완성 검색어", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    Button("자동완성 조회") {
                        Task { await fetchAutoCompletionWords() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

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
            .navigationTitle("Search Demo")
        }
    }

    private var apiButtons: some View {
        VStack(spacing: 8) {
            Button("최근 검색어 조회") {
                Task { await fetchRecentSearchWords() }
            }
            Button("최근 검색어 첫 항목 삭제") {
                Task { await removeFirstRecentSearchWord() }
            }
            Button("최근 검색어 전체 삭제") {
                Task { await clearRecentSearchWords() }
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}

// MARK: - API Calls

extension SearchDataDemoView {

    private func fetchRecentSearchWords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchRecentSearchWords()
            lastFetchedRecentSearchWords = result
            log = "✅ 최근 검색어 (\(result.count)건)\n\n"
            for word in result {
                log += "[\(word.id.value)] \(word.title)\n"
            }
        } catch {
            log = "❌ 최근 검색어 조회 실패\n\(error)"
        }
    }

    private func removeFirstRecentSearchWord() async {
        guard let word = lastFetchedRecentSearchWords.first else {
            log = "ℹ️ 먼저 '최근 검색어 조회'로 목록을 불러오세요."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.removeRecentSearchWord(word)
            log = "✅ 삭제됨: [\(word.id.value)] \(word.title)"
        } catch {
            log = "❌ 최근 검색어 삭제 실패\n\(error)"
        }
    }

    private func clearRecentSearchWords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.clearRecentSearchWords()
            lastFetchedRecentSearchWords = []
            log = "✅ 최근 검색어 전체 삭제 완료"
        } catch {
            log = "❌ 최근 검색어 전체 삭제 실패\n\(error)"
        }
    }

    private func fetchAutoCompletionWords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchAutoCompletionWords(searchText: searchText)
            log = "✅ 자동완성 결과 (\(result.count)건)\n\n"
            for word in result {
                log += "- \(word.word)\n"
            }
        } catch {
            log = "❌ 자동완성 조회 실패\n\(error)"
        }
    }
}
