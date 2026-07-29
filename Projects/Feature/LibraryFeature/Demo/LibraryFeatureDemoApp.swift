//
//  LibraryFeatureDemoApp.swift
//  LibraryFeatureDemo
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import LibraryFeature
import BaseDomain
import NovelDomain
import BaseData
import NovelData
import Logger
import Networking
import DesignSystem

@main
struct LibraryFeatureDemoApp: App {
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
    /// 소스 전환 시 화면 정체성을 갈아 새 ViewModel(깨끗한 로드)을 강제한다.
    private var libraryViewID: String { dataSource.rawValue }

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                libraryView
                    .id(libraryViewID)
            }
        }
    }

    @ViewBuilder
    private var libraryView: some View {
        switch dataSource {
        case .mock:
            LibraryFactory.makeView(
                loadMyLibraryUseCase: DemoLoadMyLibraryUseCase(),
                loadMyLibraryKeywordsUseCase: DemoLoadMyLibraryKeywordsUseCase(),
                logger: consoleLogger,
                onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
                onSearchTapped: { consoleLogger.info("웹소설 찾기(검색) 진입 요청") },
                onRegisterTapped: { consoleLogger.info("작품 등록 진입 요청") },
                onNotificationTapped: { consoleLogger.info("알림 관리 진입 요청") },
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveView()
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    // 내 서재 조회는 저장된 userID를 쓰므로 Demo가 직접 세팅한다(NovelData Demo와 동일 값).
    @MainActor
    private func makeLiveView() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let userDefaults = UserDefaultsStorage()
        userDefaults.set(.userID, 10041)
        let repository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: userDefaults,
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        return LibraryFactory.makeView(
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(novelRepository: repository),
            loadMyLibraryKeywordsUseCase: DefaultLoadMyLibraryKeywordsUseCase(novelRepository: repository),
            logger: consoleLogger,
            onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
            onSearchTapped: { consoleLogger.info("웹소설 찾기(검색) 진입 요청") },
            onRegisterTapped: { consoleLogger.info("작품 등록 진입 요청") },
            onNotificationTapped: { consoleLogger.info("알림 관리 진입 요청") },
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    /// 인증 만료 콜백. 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요). 페이지 크기 20, 총 25개 → 2페이지.

private struct DemoLoadMyLibraryUseCase: LoadMyLibraryUseCase {

    func execute(filter: MyLibraryFilter, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        try? await Task.sleep(nanoseconds: 500_000_000)

        let all = Self.novels
        let pageSize = 20
        let start = cursor.flatMap(Int.init) ?? 0
        let end = min(start + pageSize, all.count)
        guard start < end else {
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), all.count)
        }

        let hasNext = end < all.count
        let page = CursorPaginated(
            items: Array(all[start..<end]),
            hasNext: hasNext,
            nextCursor: hasNext ? "\(end)" : nil
        )
        return (page, all.count)
    }

    private static let demoKeywordNames = ["빙의", "후회", "궁중암투", "웹툰화"]

    /// 셀이 값 조합에 따라 어떻게 보이는지 한 화면에서 확인하려고 축을 서로 다른 주기로 돌린다 —
    /// 제목 줄 수(2) · 표지 유무(5) · 읽기 상태(3) · 별점 유무(4) · 기간 유무(4) · 매력포인트 수(4) · 키워드 수(5).
    /// 그리드 행이 어긋나거나 특정 조합이 깨지면 여기서 바로 드러난다.
    private static let novels: [LibraryNovel] = (1...25).map { index in
        let isLongTitle = index.isMultiple(of: 2)
        let hasRating = index % 4 != 0
        let hasPeriod = index % 4 != 1

        let status = ReadingStatus.allCases[index % ReadingStatus.allCases.count]

        // 기간은 상태별로 채워지는 날짜가 다르다(보는 중=시작, 봤어요=시작+종료, 하차=종료).
        // 그 규칙은 도메인이 강제하므로 Mock이 흉내내지 말고 normalized(for:)를 태운다.
        let rawStart = Date(timeIntervalSince1970: 1_700_000_000 + Double(index) * 86_400 * 10)
        let period = hasPeriod
            ? (try? ReadingPeriod(start: rawStart, end: rawStart.addingTimeInterval(86_400 * 60)))?
                .normalized(for: status)
            : nil

        let review: UserNovelReview? = index % 5 == 0
            ? nil
            : UserNovelReview(
                readingStatus: status,
                rating: hasRating ? try? Rating(Double(index % 9 + 1) * 0.5) : nil,
                attractivePoint: Array(AttractivePoint.allCases.prefix(index % 4)),
                period: period,
                keywords: (0..<(index % 5)).map {
                    Keyword(id: KeywordID($0 + 1), name: demoKeywordNames[$0])
                }
            )

        return LibraryNovel(
            id: NovelID(index),
            title: isLongTitle ? "데모 작품 \(index) — 당신의 이해를 돕기 위하여" : "데모 작품 \(index)",
            // 표지 비율(108:160)의 실제 이미지. 5번째마다 nil로 둬 WSS 빈 표지 폴백도 함께 확인한다.
            thumbnailImage: index.isMultiple(of: 5)
                ? nil
                : URL(string: "https://picsum.photos/seed/wss\(index)/216/320"),
            rating: 4.2,
            isInterested: index.isMultiple(of: 3),
            userReview: review,
            writtenFeeds: []
        )
    }
}

private struct DemoLoadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [Keyword] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            Keyword(id: KeywordID(1), name: "빙의"),
            Keyword(id: KeywordID(2), name: "후회"),
            Keyword(id: KeywordID(3), name: "궁중암투"),
            Keyword(id: KeywordID(4), name: "웹툰화")
        ]
    }
}
