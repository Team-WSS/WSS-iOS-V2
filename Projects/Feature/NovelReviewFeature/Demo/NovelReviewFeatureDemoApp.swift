//
//  NovelReviewFeatureDemoApp.swift
//  NovelReviewFeatureDemo
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseData
import BaseDomain
import DesignSystem
import Networking
import NovelReviewData
import NovelReviewDomain
import NovelReviewFeature

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                reviewView
                    // 소스 전환 시 화면(ViewModel)을 새로 만들어 깨끗한 상태로 로드한다.
                    .id(dataSource)
            }
        }
    }

    @ViewBuilder
    private var reviewView: some View {
        switch dataSource {
        case .mock:
            NovelReviewFactory.makeView(
                novelID: novelID,
                title: title,
                status: .watching,
                loadUseCase: DemoLoadNovelReviewDraftUseCase(),
                saveUseCase: DemoSaveNovelReviewUseCase()
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
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let repository = NovelReviewDataFactory.makeRepository(client: client)
        return NovelReviewFactory.makeView(
            novelID: novelID,
            title: title,
            status: .watched,
            loadUseCase: DefaultLoadNovelReviewDraftUseCase(repository: repository),
            saveUseCase: DefaultSaveNovelReviewUseCase(repository: repository)
        )
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
