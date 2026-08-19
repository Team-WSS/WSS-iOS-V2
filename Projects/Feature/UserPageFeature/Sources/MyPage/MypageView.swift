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

    /// 컬렉션 섹션 헤더 행 탭 콜백 — `CollectionFeature`는 서로 import 못 하는 다른 Feature 모듈이라
    /// 실제 화면 전환은 이 화면이 모른다(App 조정 계층 몫).
    private let onCollectionTapped: () -> Void
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
        onEditProfileTapped: @escaping () -> Void,
        onSettingTapped: @escaping () -> Void,
        onLibraryTapped: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onCollectionTapped = onCollectionTapped
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
                            action: onCollectionTapped
                        )

                        divider

                        if !viewModel.hasNoGenrePreferenceData {
                            GenreSection(genrePreferences: viewModel.state.genrePreferences)
                            divider
                        }

                        myPageKeywordSection
                    }
                }
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
        .toolbar {
            createMypageViewToolBarContent()
        }
        .onAppear {
            viewModel.handle(.load)
        }
    }
    
    // MARK: - 프로필
    
    private var myProfileSection: some View {
        HStack(alignment: .top, spacing: 24) {
            AsyncImage(url: viewModel.state.profile?.characterImage) {
                phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                case .failure:
                    WSSImage.imgLoadingThumbnail.swiftUIImage
                        .resizable()
                default:
                    ProgressView()
                }
            }
            .scaledToFill()
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

    @ToolbarContentBuilder
    private func createMypageViewToolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onSettingTapped) {
                WSSImage.icSetting.swiftUIImage
            }
        }
    }
}

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
