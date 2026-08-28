//
//  NovelReviewFeatureDemoApp.swift
//  NovelReviewFeatureDemo
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NovelReviewFeature
import BaseDomain
import NovelReviewDomain
import BaseData
import NovelReviewData
import Logger
import Networking
import DesignSystem
// 키워드 탐색 시트(KeywordSearchSheetBuilder)를 여기서 실제로 조립한다(App 역할 대행 — Feature 간
// 직접 의존은 Demo 타깃에서만 허용, NovelReviewFeature Sources는 KeywordFeature를 모른다. #185의
// SearchFeatureDemoApp과 동일 패턴).
import KeywordFeature

@main
struct NovelReviewFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        // 프리뷰는 이 Demo 앱을 호스트로 띄우므로 여기서 등록하면 프리뷰도 함께 해결된다.
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

    private let novelID = NovelID(1)
    private let title = "당신의 이해를 돕기 위하여"

    @State private var dataSource: DataSource = .mock
    @State private var isReviewPresented = false
    /// 열 때마다 증가. reviewView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var reviewOpenCount = 0

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        // 리뷰 화면을 push로 띄우는 랜딩. 뒤로가기(그만하기)가 이 화면으로 정상 팝되는지 검증하기 위함.
        // ⚠️ NavigationLink {} / navigationDestination(isPresented:) 모두 destination 뷰(와 @State VM)를
        //    pop 후 바로 파괴하지 않고 재사용한다 → 재진입 시 이전 편집 상태가 남는다(서버 저장 아님).
        //    reviewOpenCount를 .id로 물려 열 때마다 새 정체성 = 새 ViewModel(깨끗한 로드)로 강제한다.
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("작품 평가 화면 열기") {
                    reviewOpenCount += 1
                    isReviewPresented = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isReviewPresented) {
                reviewView
                    .id(reviewOpenCount)
            }
        }
    }

    @ViewBuilder
    private var reviewView: some View {
        switch dataSource {
        case .mock:
            NovelReviewFeatureFactory.makeView(
                novelID: novelID,
                title: title,
                status: .watching,
                loadUseCase: DemoLoadNovelReviewDraftUseCase(),
                saveUseCase: DemoSaveNovelReviewUseCase(),
                logger: consoleLogger,
                onAuthenticationRequired: handleAuthenticationRequired,
                keywordSearchSheet: keywordSearchSheetBuilder(
                    loadTotalKeywordsUseCase: DemoLoadTotalKeywordsUseCase(),
                    searchKeywordsUseCase: DemoSearchKeywordsUseCase()
                )
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
        let repository = NovelReviewDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "NovelReviewData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        return NovelReviewFeatureFactory.makeView(
            novelID: novelID,
            title: title,
            status: .watched,
            loadUseCase: DefaultLoadNovelReviewDraftUseCase(repository: repository),
            saveUseCase: DefaultSaveNovelReviewUseCase(repository: repository),
            logger: consoleLogger,
            onAuthenticationRequired: handleAuthenticationRequired,
            keywordSearchSheet: keywordSearchSheetBuilder(
                loadTotalKeywordsUseCase: DefaultFetchTotalKeywordsUseCase(keywordRepository: keywordRepository),
                searchKeywordsUseCase: DefaultSearchKeywordUseCase(keywordRepository: keywordRepository)
            )
        )
    }

    /// 키워드 탐색 시트 콘텐츠 조립 — `KeywordFeatureFactory.makeSearchKeywordView`는 자체 액션바가
    /// 없어 그대로 반환한 뒤 `NovelReviewView`가 하단 "완료" 버튼을 얹는다(SearchFeatureDemoApp의 동일 패턴).
    private func keywordSearchSheetBuilder(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase
    ) -> KeywordSearchSheetBuilder {
        { initialKeywords, onSelectionChanged in
            AnyView(
                KeywordFeatureFactory.makeSearchKeywordView(
                    loadTotalKeywordsUseCase: loadTotalKeywordsUseCase,
                    searchKeywordsUseCase: searchKeywordsUseCase,
                    initialSelectedKeywords: initialKeywords,
                    onSelectionChanged: onSelectionChanged,
                    logger: consoleLogger
                )
            )
        }
    }

    /// 인증 만료 콜백(로드/저장 등 서버 호출 공통). 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return NovelReviewDraft(
            novelID: novelID,
            status: .watched,
            attractivePoints: [.character, .vibe]
        )
    }
}

private struct DemoSaveNovelReviewUseCase: SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
    }
}

// MARK: - Demo UseCases (키워드 탐색 시트, 인메모리)
// SearchFeatureDemoApp의 동일 패턴 — 모듈이 달라 공유하지 않고 각자 최소 목록으로 흉내낸다.

private struct DemoLoadTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [KeywordGroup] {
        [
            KeywordGroup(category: .worldview, keywords: ["이세계", "현대", "SF"].demoKeywords(offset: 0)),
            KeywordGroup(category: .material, keywords: ["환생", "빙의", "회귀"].demoKeywords(offset: 10)),
            KeywordGroup(category: .character, keywords: ["먼치킨", "천재", "악당"].demoKeywords(offset: 20)),
            KeywordGroup(category: .relationship, keywords: ["친구", "라이벌", "첫사랑"].demoKeywords(offset: 30)),
            KeywordGroup(category: .vibe, keywords: ["힐링되는", "반전있는", "탄탄한"].demoKeywords(offset: 40))
        ]
    }
}

private struct DemoSearchKeywordsUseCase: SearchKeywordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [Keyword] {
        guard !searchText.isEmpty else { return [] }
        let allGroups = try await DemoLoadTotalKeywordsUseCase().execute()
        return allGroups.flatMap(\.keywords).filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

private extension [String] {
    func demoKeywords(offset: Int) -> [Keyword] {
        enumerated().map { index, name in Keyword(id: KeywordID(offset + index), name: name) }
    }
}
