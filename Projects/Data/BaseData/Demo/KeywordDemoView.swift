//
//  KeywordDemoView.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import BaseData
import BaseDomain
import Networking
import Logger

struct KeywordDemoView: View {
    @State private var log: String = ""
    @State private var searchText: String = ""

    private let repository: KeywordRepository = KeywordDataFactory.makeRepository(
        client: NetworkingClient(tokenStore: DemoSessionTokenStore()),
        logger: DataLogger(moduleName: "BaseData",
                           underlying: OSLogger.keyword)
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button("동기화") {
                        Task { await syncKeywords() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("전체 조회") {
                        Task { await fetchKeywords() }
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    TextField("키워드 검색", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    Button("검색") {
                        Task { await searchKeywords() }
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
            .padding()
            .navigationTitle("Keyword Demo")
        }
    }

    private func syncKeywords() async {
        log = "동기화 중..."
        await repository.syncKeywords()
        log = "동기화 완료 (keywords.json 저장됨)"
    }

    private func fetchKeywords() async {
        do {
            let groups = try await repository.fetchKeywords()
            log = formatGroups(groups)
        } catch {
            log = "조회 실패: \(error)"
        }
    }

    private func searchKeywords() async {
        do {
            let groups = try await repository.searchKeywords(searchText)
            log = groups.isEmpty
                ? "검색 결과 없음"
                : formatGroups(groups)
        } catch {
            log = "검색 실패: \(error)"
        }
    }

    private func formatGroups(_ groups: [KeywordGroup]) -> String {
        groups.map { group in
            let keywords = group.keywords.map { "  - [\($0.id.value)] \($0.name)" }.joined(separator: "\n")
            return "[\(group.name)] (\(group.keywords.count)개)\n\(keywords)"
        }.joined(separator: "\n\n")
    }
}
