//
//  MypageView.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import ProfileDomain
import CollectionDomain
import DesignSystem
import WSSComponent

struct MypageView: View {

    @State private var viewModel: MypageViewModel
    /// 프로필 섹션이 화면 밖으로 스크롤되면(minY < -1) 툴바 principal에 "마이페이지" 타이틀이
    /// 뜬다 — `UserPageFeature`의 스크롤 반응형 네비 타이틀과 동일 패턴(아래 toolbar 주석 참고).
    @State private var isScrolledFromTop = false

    /// 컬렉션 섹션 헤더 행 탭 콜백 — `CollectionFeature`는 서로 import 못 하는 다른 Feature 모듈이라
    /// 실제 화면 전환은 이 화면이 모른다(App 조정 계층 몫).
    private let onCollectionTapped: () -> Void
    /// 컬렉션 미리보기 항목 탭 → 그 컬렉션 상세로 이동. `onCollectionTapped`(헤더 → 목록)와 별개 콜백.
    private let onCollectionItemTapped: (CollectionID) -> Void
    /// 프로필 편집 진입 콜백 — 실제 화면 전환(`MypageFeatureFactory.makeEditView` 조립)은 호출자(App 조정 계층)가
    /// 수행한다. "저장됨" 토스트도 그 화면 전환을 조립하는 쪽(App)이 `onSaved` 시점에 보여준다.
    private let onEditProfileTapped: () -> Void
    /// 우측 상단 톱니바퀴 → 설정 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeView` 조립)은 호출자가 수행한다.
    private let onSettingTapped: () -> Void
    /// 서재 블록 탭 → "서재" 탭으로 전환 콜백. 이 화면 자신을 push하는 게 아니라 탭 자체를 바꾸는
    /// 것이라(`MainTabView`의 `TabView(selection:)`), 화면 전환이 아닌 탭 전환 콜백을 따로 받는다.
    private let onLibraryTapped: () -> Void

    init(
        viewModel: MypageViewModel,
        onCollectionTapped: @escaping () -> Void,
        onCollectionItemTapped: @escaping (CollectionID) -> Void,
        onEditProfileTapped: @escaping () -> Void,
        onSettingTapped: @escaping () -> Void,
        onLibraryTapped: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onCollectionTapped = onCollectionTapped
        self.onCollectionItemTapped = onCollectionItemTapped
        self.onEditProfileTapped = onEditProfileTapped
        self.onSettingTapped = onSettingTapped
        self.onLibraryTapped = onLibraryTapped
    }

    var body: some View {
        Group {
            if viewModel.state.hasLoadError {
                NetworkErrorView {
                    viewModel.handle(.load)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        myProfileSection
                            // 스크롤 반응형 네비 타이틀 — 프로필 섹션 상단이 화면 밖으로 올라가면
                            // (minY < -1) isScrolledFromTop을 켠다.
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onChange(of: proxy.frame(in: .named(mypageScrollCoordinateSpace)).minY,
                                                  initial: true) { _, newY in
                                            isScrolledFromTop = newY < -1
                                        }
                                }
                            )

                        WSSLibrarySection(
                            interest: viewModel.state.registeredNovelStats?.interest ?? 0,
                            watching: viewModel.state.registeredNovelStats?.watching ?? 0,
                            watched: viewModel.state.registeredNovelStats?.watched ?? 0,
                            quit: viewModel.state.registeredNovelStats?.quit ?? 0,
                            action: onLibraryTapped
                        )

                        divider

                        CollectionSection(
                            previews: viewModel.state.collectionPreviews,
                            totalCount: viewModel.state.collectionCount,
                            action: onCollectionTapped,
                            onItemSelected: onCollectionItemTapped
                        )

                        divider

                        if !viewModel.hasNoGenrePreferenceData {
                            GenreSection(genrePreferences: viewModel.state.genrePreferences)
                            divider
                        }

                        myPageKeywordSection
                    }
                }
                .coordinateSpace(name: mypageScrollCoordinateSpace)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .overlay {
                    if viewModel.isInitialLoading {
                        LoadingView()
                    }
                }
            }
        }
        .background(WSSColor.wssWhite.swiftUIColor)
        // 시스템 툴바 대신 커스텀 상단 바를 safeAreaInset로 고정한다(NovelDetail식 몰입형 헤더와 같은 결
        // — 탭 루트라 뒤로가기는 없고, 흰 배경 위 설정 아이콘 + 스크롤 시 타이틀 페이드인).
        .safeAreaInset(edge: .top, spacing: 0) {
            mypageTopBar
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.handle(.load)
        }
    }

    // MARK: - 상단 바 (커스텀)

    /// 뒤로가기 없는 탭 루트라 `WSSNavigationBar` 대신 커스텀 바를 쓴다 — 우측 설정 아이콘은 항상,
    /// 가운데 "마이페이지" 타이틀은 프로필 섹션이 화면 밖으로 스크롤되면(`isScrolledFromTop`) 페이드인.
    private var mypageTopBar: some View {
        ZStack {
            Text("마이페이지")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .opacity(isScrolledFromTop ? 1 : 0)

            HStack(spacing: 0) {
                Spacer()

                Button(action: onSettingTapped) {
                    WSSImage.icSetting.swiftUIImage
                }
                .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(WSSColor.wssWhite.swiftUIColor)
        .animation(.easeInOut(duration: 0.2), value: isScrolledFromTop)
    }
    
    // MARK: - 프로필
    
    private var myProfileSection: some View {
        HStack(alignment: .top, spacing: 24) {
            WSSProfileImage(url: viewModel.state.profile?.characterImage)
                .clipShape(Circle())
                .frame(width: 86, height: 86)
                .overlay(alignment: .bottomTrailing) {
                Button(action: onEditProfileTapped) {
                    WSSImage.icEditProfileMypage.swiftUIImage
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.state.profile?.nickname ?? "")
                    .applyWSSFont(.headline1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Text(viewModel.state.profile?.introduction ?? "")
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.trailing, 19)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var divider: some View {
        Rectangle()
            .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
            .frame(height: 3)
    }
    
    // MARK: - 키워드

    private var myPageKeywordSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("주로 보는 작품은...")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)

                Spacer()
            }
            .applyWSSFont(.title2)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)

            KeywordSection(
                hasNoData: viewModel.hasNoPreferenceData,
                attractivePointsText: attractivePointsText,
                keywordPreferences: viewModel.keywordPreferences
            )
        }
    }

}

/// `MypageView`의 스크롤 좌표공간 이름 — `GeometryReader`가 프로필 섹션의 화면상 위치를 재는 기준.
private let mypageScrollCoordinateSpace = "MypageScroll"

// MARK: - Presentation

private extension MypageView {
    var attractivePointsText: String {
        let points = viewModel.state.novelPreference?.attractivePoints ?? []
        return points.map(\.displayName).joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MypageView(
            viewModel: MypageViewModel(
                userID: UserID(10041),
                loadProfileUseCase: PreviewLoadProfileUseCase(),
                loadGenrePreferencesUseCase: PreviewLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: PreviewLoadNovelPreferencesUseCase(),
                loadRegisteredNovelStatsUseCase: PreviewLoadRegisteredNovelStatsUseCase(),
                loadCollectionPreviewsUseCase: PreviewLoadCollectionPreviewsUseCase()
            ),
            onCollectionTapped: { print("컬렉션 뷰로 이동") },
            onCollectionItemTapped: { print("컬렉션 상세로 이동: \($0)") },
            onEditProfileTapped: { print("프로필 편집 진입") },
            onSettingTapped: { print("설정 진입") },
            onLibraryTapped: { print("서재 탭으로 전환") }
        )
    }
}

private struct PreviewLoadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase {
    func execute(userID: UserID, size: Int) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        let previews = (1...size).map { index in
            CollectionPreview(
                id: CollectionID(index),
                name: "미리보기 컬렉션 \(index)",
                representativeNovel: CollectionNovel(id: NovelID(index), title: "작품 \(index)", author: "작가 \(index)", thumbnailImage: nil)
            )
        }
        return (previews, previews.count)
    }
}

private struct PreviewLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(
            nickname: "구리구리스",
            introduction: "백덕수 작가입니다. 반갑습니다.백덕수 작가입니다. 반갑습니다.",
            characterImage: URL(string: "https://i.pinimg.com/736x/d7/18/03/d71803d12d1a305bd0626733ddbacd92.jpg"),
            isPublic: true,
            genrePreferences: []
        )
    }
}

private struct PreviewLoadGenrePreferencesUseCase: LoadGenrePreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        [
            GenrePreference(genre: .BL, count: 1003),
            GenrePreference(genre: .fantasy, count: 30),
            GenrePreference(genre: .romance, count: 2),
            GenrePreference(genre: .lightNovel, count: 3),
            GenrePreference(genre: .wuxia, count: 123)
        ]
    }
}

private struct PreviewLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        NovelPreference(
            attractivePoints: [.character, .relationship, .material],
            keywords: [KeywordPreference(keyword: Keyword(id: KeywordID(1), name: "안녕"), count: 2)]
        )
    }
}

private struct PreviewLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}
