//
//  MypageFeatureDemoApp.swift
//  MypageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI

import MypageFeature
import BaseDomain
import ProfileDomain
import NovelDomain
import BaseData
import ProfileData
import NovelData
import Logger
import Networking
import DesignSystem

@main
struct MypageFeatureDemoApp: App {

    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// MARK: - Root: Mock ↔ 실서버 토글

// Demo가 App(DI) 역할을 대행해 UseCase를 조립한다.
// Mock = 인메모리(흐름 시연), 실서버 = NetworkingClient + 실제 Repository.
private struct DemoRootView: View {
    private enum DataSource: String, CaseIterable, Identifiable {
        case mock = "Mock"
        case live = "실서버"
        var id: String { rawValue }
    }

    @State private var dataSource: DataSource = .mock

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                mypageView
                    // 데이터 소스를 바꾸면 새 정체성(= 새 ViewModel)으로 깨끗하게 다시 로드한다.
                    .id(dataSource)
            }
        }
    }

    @ViewBuilder
    private var mypageView: some View {
        switch dataSource {
        case .mock:
            MypageFactory.makeView(
                loadProfileUseCase: DemoLoadProfileUseCase(),
                loadGenrePreferencesUseCase: DemoLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: DemoLoadNovelPreferencesUseCase(),
                loadRegisteredNovelStatsUseCase: DemoLoadRegisteredNovelStatsUseCase(),
                logger: consoleLogger
            )
        case .live:
            makeLiveView()
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    @MainActor
    private func makeLiveView() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        
        let localStorage = UserDefaultsStorage()
        localStorage.set(.userID, 10043)
        
        let profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: localStorage,
            logger: DataLogger(moduleName: "ProfileData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        // 키워드 캐시(keywords.json)가 없으면 fetchKeywords()가 매번 cache error를 낸다 —
        // 실제 App은 아직 startup sync를 안 하므로, Demo가 그 역할을 대신 1회 트리거한다.
        Task { await keywordRepository.syncKeywords() }
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: localStorage,
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        return MypageFactory.makeView(
            loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: profileRepository),
            loadGenrePreferencesUseCase: DefaultLoadGenrePreferencesUseCase(profileRepository: profileRepository),
            loadNovelPreferencesUseCase: DefaultLoadNovelPreferencesUseCase(
                profileRepository: profileRepository,
                keywordRepository: keywordRepository
            ),
            loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(novelRepository: novelRepository),
            logger: consoleLogger
        )
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return Profile(
            nickname: "구리구리스",
            introduction: "백덕수 작가입니다. 반갑습니다.백덕수 작가입니다. 반갑습니다.",
            characterImage: URL(string: "https://i.pinimg.com/736x/d7/18/03/d71803d12d1a305bd0626733ddbacd92.jpg"),
            isPublic: true,
            genrePreferences: []
        )
    }
}

private struct DemoLoadGenrePreferencesUseCase: LoadGenrePreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return [
            GenrePreference(genre: .BL, count: 1003),
            GenrePreference(genre: .fantasy, count: 30),
            GenrePreference(genre: .romance, count: 2),
            GenrePreference(genre: .lightNovel, count: 3),
            GenrePreference(genre: .wuxia, count: 123)
        ]
    }
}

private struct DemoLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return NovelPreference(
            attractivePoints: [.character, .relationship, .material],
            keywords: [
                KeywordPreference(keyword: Keyword(id: KeywordID(1), name: "안녕"), count: 2),
                KeywordPreference(keyword: Keyword(id: KeywordID(2), name: "궁중암투"), count: 5)
            ]
        )
    }
}

private struct DemoLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}
