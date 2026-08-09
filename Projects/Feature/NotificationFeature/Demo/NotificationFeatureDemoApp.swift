//
//  NotificationFeatureDemoApp.swift
//  NotificationFeatureDemo
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NotificationFeature
import BaseDomain
import NotificationDomain
import BaseData
import NotificationData
import Logger
import Networking
import DesignSystem

@main
struct NotificationFeatureDemoApp: App {
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

/// 알림 Mock 시나리오 — **버튼 하나 = 데이터 조건 하나**(NovelDetailFeature Demo 규약).
/// 실서버 모드에선 무시되고 실제 응답을 그린다.
private enum DemoNotificationScenario: String, CaseIterable, Identifiable {
    /// 읽음·미읽음과 딥링크 3종(알림 상세·피드·unknown)이 섞인 한 페이지.
    case filled = "정상"
    /// 여러 페이지 — 마지막 셀까지 내려 커서 페이지네이션을 확인하는 축.
    case paged = "페이지네이션"
    /// 알림 0건 — 빈 상태 축.
    case empty = "빈 데이터"
    case failure = "실패"
    case authExpired = "인증만료"
    var id: String { rawValue }
}

/// 목록 → 상세 전환 경로.
/// ⚠️ `NotificationID`·`FeedID`는 둘 다 `IDWrapper<Int>`의 typealias라 **같은 타입**이다 —
/// `navigationDestination(for:)`를 ID 타입별로 두면 두 경로가 서로를 삼킨다. 반드시 Route enum으로 감싼다.
private enum DemoRoute: Hashable {
    case notificationDetail(NotificationID)
    case feedDetail(FeedID)
    case novelDetail(NovelID)
}

// MARK: - Root: Mock ↔ 실서버 토글

// Demo가 App(DI) 역할을 대행해 UseCase를 조립하고 목록 → 상세 전환도 배선한다.
// Mock = 인메모리(흐름 시연), 실서버 = NetworkingClient + 실제 Repository.
private struct DemoRootView: View {
    private enum DataSource: String, CaseIterable, Identifiable {
        case mock = "Mock"
        case live = "실서버"
        var id: String { rawValue }
    }

    @State private var dataSource: DataSource = .mock
    @State private var scenario: DemoNotificationScenario = .filled
    @State private var path: [DemoRoute] = []
    /// 소스·시나리오 전환 시 화면 정체성을 갈아 새 ViewModel(깨끗한 로드)을 강제한다.
    private var listViewID: String { "\(dataSource.rawValue)-\(scenario.rawValue)" }

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        VStack(spacing: 0) {
            Picker("데이터 소스", selection: $dataSource) {
                ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if dataSource == .mock {
                scenarioRow
            }

            NavigationStack(path: $path) {
                listView
                    .id(listViewID)
                    .navigationDestination(for: DemoRoute.self) { route in
                        destination(for: route)
                    }
            }
        }
    }

    private var scenarioRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DemoNotificationScenario.allCases) { item in
                    Button(item.rawValue) { scenario = item }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(scenario == item ? .accentColor : .gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    // MARK: - 조립

    @ViewBuilder
    private var listView: some View {
        switch dataSource {
        case .mock:
            makeListView(
                loadPagedNotificationsUseCase: DemoLoadPagedNotificationsUseCase(scenario: scenario),
                markNotificationAsReadUseCase: DemoMarkNotificationAsReadUseCase(scenario: scenario)
            )
        case .live:
            makeLiveListView()
        }
    }

    @ViewBuilder
    private func destination(for route: DemoRoute) -> some View {
        switch route {
        case .notificationDetail(let id):
            switch dataSource {
            case .mock:
                makeDetailView(
                    notificationID: id,
                    loadNotificationDetailUseCase: DemoLoadNotificationDetailUseCase(scenario: scenario)
                )
            case .live:
                makeLiveDetailView(notificationID: id)
            }
        case .feedDetail(let id):
            // 피드 상세는 다른 모듈(FeedFeature) 화면이라 Demo에선 진입 사실만 보여준다.
            Text("피드 상세 진입 요청: \(id.value)")
        case .novelDetail(let id):
            // 작품 상세도 다른 모듈(NovelDetailFeature) 화면 — 실서버에선 아직 이 경로가 열리지 않는다.
            Text("작품 상세 진입 요청: \(id.value)")
        }
    }

    @MainActor
    private func makeListView(
        loadPagedNotificationsUseCase: LoadPagedNotificationsUseCase,
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase
    ) -> some View {
        NotificationFactory.makeNotificationListView(
            loadPagedNotificationsUseCase: loadPagedNotificationsUseCase,
            markNotificationAsReadUseCase: markNotificationAsReadUseCase,
            logger: consoleLogger,
            onNotificationSelected: { path.append(.notificationDetail($0)) },
            onFeedSelected: { path.append(.feedDetail($0)) },
            onNovelSelected: { path.append(.novelDetail($0)) },
            onAuthenticationRequired: { consoleLogger.info("인증 만료 → 로그인 진입 요청") }
        )
    }

    @MainActor
    private func makeDetailView(
        notificationID: NotificationID,
        loadNotificationDetailUseCase: LoadNotificationDetailUseCase
    ) -> some View {
        NotificationFactory.makeNotificationDetailView(
            notificationID: notificationID,
            loadNotificationDetailUseCase: loadNotificationDetailUseCase,
            logger: consoleLogger,
            onAuthenticationRequired: { consoleLogger.info("인증 만료 → 로그인 진입 요청") }
        )
    }

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    @MainActor
    private func makeLiveListView() -> some View {
        let repository = makeLiveRepository()
        return makeListView(
            loadPagedNotificationsUseCase: DefaultLoadPagedNotificationsUseCase(repository: repository),
            markNotificationAsReadUseCase: DefaultMarkNotificationAsReadUseCase(repository: repository)
        )
    }

    @MainActor
    private func makeLiveDetailView(notificationID: NotificationID) -> some View {
        makeDetailView(
            notificationID: notificationID,
            loadNotificationDetailUseCase: DefaultLoadNotificationDetailUseCase(
                repository: makeLiveRepository()
            )
        )
    }

    private func makeLiveRepository() -> NotificationRepository {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        return NotificationDataFactory.makeNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: consoleLogger)
        )
    }
}

// MARK: - Demo UseCases (Mock)

private struct DemoLoadPagedNotificationsUseCase: LoadPagedNotificationsUseCase {

    let scenario: DemoNotificationScenario

    func execute(lastNotificationID: NotificationID?, size: Int) async throws(RepositoryError) -> PagedNotifications {
        try? await Task.sleep(nanoseconds: 500_000_000)

        switch scenario {
        case .failure:      throw .networkUnavailable
        case .authExpired:  throw .authenticationRequired
        case .empty:        return PagedNotifications(items: [], isLoadable: false)
        case .filled:       return PagedNotifications(items: DemoNotificationData.firstPage, isLoadable: false)
        case .paged:
            // 3페이지까지만 준다 — 마지막 페이지에서 isLoadable=false로 무한 스크롤이 멈추는지 확인한다.
            let page = DemoNotificationData.pagedItems(after: lastNotificationID, size: size)
            return PagedNotifications(items: page.items, isLoadable: page.isLoadable)
        }
    }
}

private struct DemoMarkNotificationAsReadUseCase: MarkNotificationAsReadUseCase {

    let scenario: DemoNotificationScenario

    // UseCase 프로토콜이 Sendable이라 non-Sendable인 ConsoleLogger를 들 수 없다 → mock은 print로 남긴다.
    func execute(id: NotificationID) async throws(RepositoryError) {
        if scenario == .authExpired { throw .authenticationRequired }
        print("읽음 처리 요청: \(id.value)")
    }
}

private struct DemoLoadNotificationDetailUseCase: LoadNotificationDetailUseCase {

    let scenario: DemoNotificationScenario

    func execute(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        try? await Task.sleep(nanoseconds: 500_000_000)

        switch scenario {
        case .failure:      throw .networkUnavailable
        case .authExpired:  throw .authenticationRequired
        default:
            return NotificationDetail(
                title: "웹소소 이용약관 개정 안내",
                createdAtText: "2026.08.05",
                body: "안녕하세요, 웹소소입니다.\n\n서비스 이용약관이 아래와 같이 개정되어 안내드립니다. "
                    + "개정된 약관은 2026년 8월 20일부터 적용되며, 자세한 내용은 앱 내 설정 > 약관에서 확인하실 수 있습니다.\n\n"
                    + "앞으로도 더 나은 서비스로 보답하겠습니다. 감사합니다."
            )
        }
    }
}

private enum DemoNotificationData {

    /// 읽음·미읽음, 딥링크 3종(알림 상세·피드·unknown), 아이콘 없음까지 한 화면에서 확인한다.
    static let firstPage: [NotificationItem] = [
        NotificationItem(
            id: NotificationID(101),
            iconURL: URL(string: "https://picsum.photos/seed/noti1/96/96"),
            title: "웹소소 이용약관 개정 안내",
            body: "서비스 이용약관이 개정되어 안내드립니다. 개정된 약관은 2026년 8월 20일부터 적용됩니다.",
            createdAtText: "방금 전",
            isRead: false,
            deeplink: .notificationDetail(id: NotificationID(101))
        ),
        NotificationItem(
            id: NotificationID(102),
            iconURL: URL(string: "https://picsum.photos/seed/noti2/96/96"),
            title: "천마님이 회원님의 글을 좋아합니다",
            body: "이름이 나여주입니다ㅋㅋㅋ읽던 소설이 세계멸망엔딩나서 댓글달았다가 그 세계의 본인에게 빙의하게 되었는데",
            createdAtText: "3시간 전",
            isRead: false,
            deeplink: .feedDetail(id: FeedID(7))
        ),
        NotificationItem(
            id: NotificationID(103),
            iconURL: nil,
            title: "‘여주가 세계를 구함 이 구역의 최강자다’ 라는 아주 긴 제목",
            body: "아이콘이 없고 제목이 아주 긴 알림 — 아이콘 폴백 자리와 제목 1줄 말줄임을 함께 확인하는 축이다."
                + " 본문도 길어서 두 줄에서 잘린다.",
            createdAtText: "어제",
            isRead: true,
            deeplink: .unknown
        ),
        NotificationItem(
            id: NotificationID(105),
            iconURL: URL(string: "https://picsum.photos/seed/noti5/96/96"),
            title: "완결 알림",
            body: "<당신의 이해를 돕기 위하여> 작품이 완결났어요.",
            // ⚠️ 실서버에선 이 알림이 `.unknown`으로 온다(응답에 novelId가 없음).
            // Demo에서만 `.novelDetail`을 넣어 서버 보강 후의 전환 경로를 미리 확인한다.
            createdAtText: "2026.07.31",
            isRead: false,
            deeplink: .novelDetail(id: NovelID(4217))
        ),
        NotificationItem(
            id: NotificationID(104),
            iconURL: URL(string: "https://picsum.photos/seed/noti4/96/96"),
            title: "읽은 알림",
            body: "짧은 본문.",
            createdAtText: "2026.07.30",
            isRead: true,
            deeplink: .notificationDetail(id: NotificationID(104))
        )
    ]

    /// 커서 페이지네이션 mock — `lastNotificationID` 다음부터 `size`개씩, 총 3페이지를 준다.
    static func pagedItems(
        after lastNotificationID: NotificationID?,
        size: Int
    ) -> (items: [NotificationItem], isLoadable: Bool) {
        let totalCount = 50
        // 커서는 **exclusive**다 — "마지막으로 받은 ID"의 *다음*부터 준다. `+1`을 빼먹으면 그 항목이 다음 페이지에
        // 다시 실려 `ForEach(id:)`가 중복 ID를 만나고, 목록에 셀 하나 크기의 빈 공간이 뚫린다(#181에서 실측).
        let startIndex = lastNotificationID.map { totalCount - $0.value + 1 } ?? 0
        let endIndex = min(startIndex + size, totalCount)
        guard startIndex < endIndex else { return ([], false) }

        // ID는 최신순(내림차순)으로 내려간다 — 서버 커서가 "마지막으로 받은 ID"인 것과 같은 형태.
        let items = (startIndex..<endIndex).map { index in
            NotificationItem(
                id: NotificationID(totalCount - index),
                iconURL: URL(string: "https://picsum.photos/seed/paged\(index)/96/96"),
                title: "알림 \(index + 1)번째",
                body: "커서 페이지네이션 확인용 알림입니다.",
                createdAtText: "\(index + 1)일 전",
                isRead: index.isMultiple(of: 3),
                deeplink: .notificationDetail(id: NotificationID(totalCount - index))
            )
        }
        return (items, endIndex < totalCount)
    }
}
