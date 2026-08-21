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
import Logger
import DesignSystem
import WSSComponent

struct MypageView: View {

    @State private var viewModel: MypageViewModel
    @State private var showEditView: Bool = false
    @State private var showProfileSavedToast: Bool = false

    /// 프로필 편집 화면으로의 내부 네비게이션 조립에만 쓴다(VM은 만들지 않음, `MypageFeatureFactory.makeEditView` 재사용).
    private let loadInitialProfileUseCase: LoadInitialProfileUseCase
    private let loadProfileCharacterUseCase: LoadProfileCharacterUseCase
    private let validateNicknameUseCase: ValidateNicknameUseCase
    private let updateProfileUseCase: UpdateProfileUseCase
    private let logger: Logger?
    /// 컬렉션 섹션 헤더 행 탭 콜백 — `CollectionFeature`는 서로 import 못 하는 다른 Feature 모듈이라
    /// 실제 화면 전환은 이 화면이 모른다(App 조정 계층 몫). "서재 뷰로 이동"/"설정 뷰로 이동"과 달리
    /// 이번 작업 범위라 콜백까지는 실제로 배선한다.
    private let onCollectionTapped: () -> Void

    init(
        viewModel: MypageViewModel,
        loadInitialProfileUseCase: LoadInitialProfileUseCase,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        validateNicknameUseCase: ValidateNicknameUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        onCollectionTapped: @escaping () -> Void,
        logger: Logger? = nil
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.loadInitialProfileUseCase = loadInitialProfileUseCase
        self.loadProfileCharacterUseCase = loadProfileCharacterUseCase
        self.validateNicknameUseCase = validateNicknameUseCase
        self.updateProfileUseCase = updateProfileUseCase
        self.onCollectionTapped = onCollectionTapped
        self.logger = logger
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

                        LibrarySection(stats: viewModel.state.registeredNovelStats) {
                            //TODO: - 서재 뷰로 이동
                            print("서재 뷰로 이동")
                        }

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
        .navigationDestination(isPresented: $showEditView) {
            MypageFeatureFactory.makeEditView(
                loadInitialProfileUseCase: loadInitialProfileUseCase,
                loadProfileCharacterUseCase: loadProfileCharacterUseCase,
                validateNicknameUseCase: validateNicknameUseCase,
                updateProfileUseCase: updateProfileUseCase,
                onSaved: { showProfileSavedToast = true },
                logger: logger
            )
        }
        .showWSSToast(isPresented: $showProfileSavedToast, type: .editProfile)
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
                Button {
                    showEditView = true
                } label: {
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
            Button {
                //TODO: - 설정 뷰로 이동
                print("설정 뷰로 이동")
            } label: {
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
            loadInitialProfileUseCase: PreviewLoadInitialProfileUseCase(),
            loadProfileCharacterUseCase: PreviewLoadProfileCharacterUseCase(),
            validateNicknameUseCase: PreviewValidateNicknameUseCase(),
            updateProfileUseCase: PreviewUpdateProfileUseCase(),
            onCollectionTapped: { print("컬렉션 뷰로 이동") }
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

private struct PreviewLoadInitialProfileUseCase: LoadInitialProfileUseCase {
    func execute() async throws(RepositoryError) -> ProfileDraft {
        ProfileDraft(
            characterID: 1,
            nickname: "구리구리스",
            introduction: "백덕수 작가입니다. 반갑습니다.",
            genrePreferences: [GenrePreference(genre: .romance, count: 12)]
        )
    }
}

private struct PreviewValidateNicknameUseCase: ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool { true }
}

private struct PreviewUpdateProfileUseCase: UpdateProfileUseCase {
    func execute(_ draft: ProfileDraft) async throws(RepositoryError) {}
}

private struct PreviewLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    func execute() async throws(RepositoryError) -> [ProfileCharacter] {
        (1...20).map { index in
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
