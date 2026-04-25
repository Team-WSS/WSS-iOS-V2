//
//  RecommendationDataDemoView.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 10/31/25.
//

import SwiftUI

import RecommendationData
import RecommendationDomain
import Networking
import BaseData
import Logger

struct RecommendationDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var isLoading: Bool = false

    private let repository: RecommendationRepository

    init() {
        let client = NetworkingClient()
        let logger = DataLogger(moduleName: "RecommendationData", underlying: OSLogger.recommendation)
        self.repository = RecommendationDataFactory.makeRepository(network: client,
                                                                   logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                apiButtons

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
            .navigationTitle("Recommendation Demo")
        }
    }

    private var apiButtons: some View {
        VStack(spacing: 8) {
            Button("오늘의 발견 조회") {
                Task { await fetchTodayDiscoveries() }
            }
            Button("지금 뜨는 글 조회") {
                Task { await fetchTrendingFeeds() }
            }
            Button("관심 글 조회") {
                Task { await fetchInterestFeeds() }
            }
            Button("선호 장르 기반 소설 조회") {
                Task { await fetchPreferenceGenreNovels() }
            }
            Button("소소픽 조회") {
                Task { await fetchSosoPick() }
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}

// MARK: - API Calls

extension RecommendationDataDemoView {

    private func fetchTodayDiscoveries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchTodayDiscoveries()
            log = "✅ 오늘의 발견 (\(result.count)건)\n\n"
            for item in result {
                log += "[\(item.title)] \(item.novelTitle)\n"
                log += "  → \(item.description)\n\n"
            }
        } catch {
            log = "❌ 오늘의 발견 실패\n\(error)"
        }
    }

    private func fetchTrendingFeeds() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchTrendingFeeds()
            log = "✅ 지금 뜨는 글 (\(result.count)건)\n\n"
            for feed in result {
                log += "Feed #\(feed.feedID)\n"
                log += "  \(feed.displayDescription)\n"
                log += "  ❤️ \(feed.likeCount)  💬 \(feed.commentCount)\n\n"
            }
        } catch {
            log = "❌ 지금 뜨는 글 실패\n\(error)"
        }
    }

    private func fetchInterestFeeds() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchInterestFeeds()
            switch result {
            case .feeds(let feeds):
                log = "✅ 관심 글 (\(feeds.count)건)\n\n"
                for feed in feeds {
                    log += "📖 \(feed.novelTitle) (⭐️ \(feed.novelRating))\n"
                    log += "  \(feed.user.nickname): \(feed.userComment)\n\n"
                }
            case .noInterestSettings:
                log = "ℹ️ 관심 설정이 없습니다."
            case .noAssociatedFeeds:
                log = "ℹ️ 관련 피드가 없습니다."
            }
        } catch {
            log = "❌ 관심 글 실패\n\(error)"
        }
    }

    private func fetchPreferenceGenreNovels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchPreferenceGenreNovels()
            switch result {
            case .novels(let novels):
                log = "✅ 선호 장르 소설 (\(novels.count)건)\n\n"
                for novel in novels {
                    log += "📚 \(novel.novelTitle)\n"
                    log += "  작가: \(novel.novelAuthors.joined(separator: ", "))\n"
                    log += "  ⭐️ \(novel.rating) (\(novel.ratingCount)) | 관심 \(novel.interestCount)\n\n"
                }
            case .noGenreSettings:
                log = "ℹ️ 선호 장르가 설정되지 않았습니다."
            }
        } catch {
            log = "❌ 선호 장르 소설 실패\n\(error)"
        }
    }

    private func fetchSosoPick() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await repository.fetchSosoPick()
            log = "✅ 소소픽 (\(result.count)건)\n\n"
            for pick in result {
                log += "📕 \(pick.novelTitle) (ID: \(pick.novelID))\n"
            }
        } catch {
            log = "❌ 소소픽 실패\n\(error)"
        }
    }
}
