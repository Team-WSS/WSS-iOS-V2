//
//  CollectionFeatureDemoApp.swift
//  CollectionFeatureDemo
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionFeature
import BaseDomain
import CollectionDomain
import BaseData
import CollectionData
import Logger
import Networking
import DesignSystem

@main
struct CollectionFeatureDemoApp: App {
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

    @State private var dataSource: DataSource = .mock
    @State private var isCreatePresented = false
    /// 열 때마다 증가. createView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var createOpenCount = 0

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("컬렉션 생성 화면 열기") {
                    createOpenCount += 1
                    isCreatePresented = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isCreatePresented) {
                createView
                    .id(createOpenCount)
            }
        }
    }

    @ViewBuilder
    private var createView: some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeCreateCollectionView(
                createCollectionUseCase: DemoCreateCollectionUseCase(),
                logger: consoleLogger,
                onAddNovelTapped: handleAddNovelTapped,
                onAuthenticationRequired: handleAuthenticationRequired
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
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeCreateCollectionView(
            createCollectionUseCase: DefaultCreateCollectionUseCase(collectionRepository: repository),
            logger: consoleLogger,
            onAddNovelTapped: handleAddNovelTapped,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    /// "작품 추가"/"작품 수정" 타일 탭 콜백. 작품 검색 화면은 후속 이슈 — Demo는 로그만.
    private func handleAddNovelTapped() {
        consoleLogger.info("작품 추가 화면 진입 요청(미구현)")
    }

    /// 인증 만료 콜백. 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }
}

// MARK: - Demo UseCase (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoCreateCollectionUseCase: CreateCollectionUseCase {
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CollectionID(1)
    }
}
