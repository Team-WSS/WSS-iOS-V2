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
    @State private var isCharacterSheetPresented = false

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()
    /// Mock 데이터 소스의 "서버" 역할 — 편집 화면에서 저장한 값을 마이페이지 조회가 그대로 돌려받도록
    /// 인메모리로 들고 있는다. 없으면 Mock 모드에서 완료를 눌러도 항상 하드코딩된 초기값만 보인다.
    private let demoProfileStore = DemoProfileStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                Button("캐릭터 선택 시트 열기") {
                    isCharacterSheetPresented = true
                }
                .padding(.bottom, 12)

                Text("프로필 편집은 아래 마이페이지의 연필 아이콘으로 진입")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                mypageView
                    // 데이터 소스를 바꾸면 새 정체성(= 새 ViewModel)으로 깨끗하게 다시 로드한다.
                    .id(dataSource)
            }
            .sheet(isPresented: $isCharacterSheetPresented) {
                characterEditSheet
            }
        }
    }

    @ViewBuilder
    private var characterEditSheet: some View {
        switch dataSource {
        case .mock:
            MypageFactory.makeCharacterEditSheet(
                selectedCharacterID: 3,
                nickname: "구리구리스",
                loadProfileCharacterUseCase: DemoLoadProfileCharacterUseCase(),
                onApply: { characterID in
                    consoleLogger.info("선택된 캐릭터 ID: \(characterID)")
                    demoProfileStore.characterID = characterID
                },
                logger: consoleLogger
            )
        case .live:
            makeLiveCharacterEditSheet()
        }
    }

    @MainActor
    private func makeLiveCharacterEditSheet() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let localStorage = UserDefaultsStorage()
        localStorage.set(.userID, 10045)
        let profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: localStorage,
            logger: DataLogger(moduleName: "ProfileData", underlying: consoleLogger)
        )
        return MypageFactory.makeCharacterEditSheet(
            selectedCharacterID: 3,
            nickname: "구리구리스",
            loadProfileCharacterUseCase: DefaultLoadProfileCharacterUseCase(profileRepository: profileRepository),
            onApply: { characterID in
                consoleLogger.info("선택된 캐릭터 ID: \(characterID)")
            },
            logger: consoleLogger
        )
    }

    @ViewBuilder
    private var mypageView: some View {
        switch dataSource {
        case .mock:
            MypageFactory.makeView(
                loadProfileUseCase: DemoLoadProfileUseCase(store: demoProfileStore),
                loadGenrePreferencesUseCase: DemoLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: DemoLoadNovelPreferencesUseCase(),
                loadRegisteredNovelStatsUseCase: DemoLoadRegisteredNovelStatsUseCase(),
                loadInitialProfileUseCase: DemoLoadInitialProfileUseCase(store: demoProfileStore),
                loadProfileCharacterUseCase: DemoLoadProfileCharacterUseCase(),
                validateNicknameUseCase: DemoValidateNicknameUseCase(),
                updateProfileUseCase: DemoUpdateProfileUseCase(store: demoProfileStore),
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
        localStorage.set(.userID, 10045)
        
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
            loadInitialProfileUseCase: DefaultLoadProfileDraftUseCase(profileRepository: profileRepository),
            loadProfileCharacterUseCase: DefaultLoadProfileCharacterUseCase(profileRepository: profileRepository),
            validateNicknameUseCase: DefaultValidateNicknameUseCase(repository: profileRepository),
            updateProfileUseCase: DefaultUpdateProfileUseCase(profileRepository: profileRepository),
            logger: consoleLogger
        )
    }
}

// MARK: - Demo In-Memory "서버" (Mock)

/// Mock 데이터 소스의 상태를 화면 간에 공유하는 인메모리 저장소.
/// 이게 없으면 편집 화면에서 완료를 눌러도 마이페이지 조회 Mock은 항상 하드코딩된 초기값만 돌려준다.
private final class DemoProfileStore {
    var characterID = 1
    var nickname = "구리구리스"
    var introduction = "백덕수 작가입니다. 반갑습니다."
    var genrePreferences: [GenrePreference] = [
        GenrePreference(genre: .romance, count: 2),
        GenrePreference(genre: .BL, count: 1003)
    ]

    static let characters: [ProfileCharacter] = (1...20).map { index in
        ProfileCharacter(
            id: index,
            name: "팬텀 \(index)",
            line: "만나서 반가워요, %s",
            representativeImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
            thumbnailImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
            isRepresentative: index == 1
        )
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoLoadProfileUseCase: LoadProfileUseCase {
    let store: DemoProfileStore

    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return Profile(
            nickname: store.nickname,
            introduction: store.introduction,
            characterImage: DemoProfileStore.characters.first { $0.id == store.characterID }?.representativeImage,
            isPublic: true,
            genrePreferences: []
        )
    }
}

private struct DemoLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    func execute() async throws(RepositoryError) -> [ProfileCharacter] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return DemoProfileStore.characters
    }
}

private struct DemoLoadInitialProfileUseCase: LoadInitialProfileUseCase {
    let store: DemoProfileStore

    func execute() async throws(RepositoryError) -> ProfileDraft {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return ProfileDraft(
            characterID: store.characterID,
            nickname: store.nickname,
            introduction: store.introduction,
            genrePreferences: store.genrePreferences
        )
    }
}

private struct DemoValidateNicknameUseCase: ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return nickname != "중복닉네임"
    }
}

private struct DemoUpdateProfileUseCase: UpdateProfileUseCase {
    let store: DemoProfileStore

    func execute(_ draft: ProfileDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        store.characterID = draft.characterID
        store.nickname = draft.nickname.text
        store.introduction = draft.introduction
        store.genrePreferences = draft.genrePreferences
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
