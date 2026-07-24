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
import Logger
import DesignSystem
import WSSComponent

struct MypageView: View {

    @State private var viewModel: MypageViewModel
    @State private var isGenreListExpanded: Bool = false
    @State private var showEditView: Bool = false
    @State private var showProfileSavedToast: Bool = false

    /// 프로필 편집 화면으로의 내부 네비게이션 조립에만 쓴다(VM은 만들지 않음, `MypageFactory.makeEditView` 재사용).
    private let loadInitialProfileUseCase: LoadInitialProfileUseCase
    private let loadProfileCharacterUseCase: LoadProfileCharacterUseCase
    private let validateNicknameUseCase: ValidateNicknameUseCase
    private let updateProfileUseCase: UpdateProfileUseCase
    private let logger: Logger?

    init(
        viewModel: MypageViewModel,
        loadInitialProfileUseCase: LoadInitialProfileUseCase,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        validateNicknameUseCase: ValidateNicknameUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        logger: Logger? = nil
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.loadInitialProfileUseCase = loadInitialProfileUseCase
        self.loadProfileCharacterUseCase = loadProfileCharacterUseCase
        self.validateNicknameUseCase = validateNicknameUseCase
        self.updateProfileUseCase = updateProfileUseCase
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
                        myLibrarySection

                        divider

                        myCollectionSection

                        divider

                        if !viewModel.hasNoGenrePreferenceData {
                            myGenreSection
                            divider
                        }

                        myNovelPreferenceSection
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
        .toolbar {
            createMypageViewToolBarContent()
        }
        .onAppear {
            viewModel.handle(.load)
        }
        .navigationDestination(isPresented: $showEditView) {
            MypageFactory.makeEditView(
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
    
    // MARK: - 서재
    
    private var myLibrarySection: some View {
        Button {
            //TODO: - 서재 뷰로 이동
            print("서재 뷰로 이동")
        } label: {
            HStack(spacing: 0) {
                myLibraryItem(count: viewModel.state.registeredNovelStats?.interest ?? 0, title: "관심")
                myLibraryItem(count: viewModel.state.registeredNovelStats?.watching ?? 0, title: "보는중")
                myLibraryItem(count: viewModel.state.registeredNovelStats?.watched ?? 0, title: "봤어요")
                myLibraryItem(count: viewModel.state.registeredNovelStats?.quit ?? 0, title: "하차")
            }
            .padding(.vertical, 14.5)
            .background(WSSColor.wssPrimary20.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
    
    private func myLibraryItem(count: Int, title: String) -> some View {
        VStack(spacing: 2) {
            Text(String(count))
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                .lineLimit(1)
            
            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 컬렉션

    private var myCollectionSection: some View {
        VStack(spacing: 0) {
            Button {
                //TODO: - 컬렉션 뷰로 이동
                print("컬렉션 뷰로 이동")
            } label: {
                HStack(spacing: 0) {
                    Text("컬렉션 ")
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    Text("0개")
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)

                    Spacer()

                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                        .frame(width: 24, height: 24)
                }
                .applyWSSFont(.title2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private func collectionItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGrayToast.swiftUIColor)
                    .offset(x: 14)
                    .frame(width: 73, height: 108)

                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGray80.swiftUIColor)
                    .offset(x: 7)
                    .frame(width: 73, height: 108)

                AsyncImage(url: imageURL) {
                    phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                    case .failure:
                        WSSImage.imgLoadingThumbnail.swiftUIImage
                    default:
                        ProgressView()
                    }
                }
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 6.57))
                .frame(width: 73, height: 108)
            }
            .shadow(color: Color.black.opacity(0.1),
                    radius: 12.68,
                    x: 0,
                    y: 1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .lineLimit(1)
        }
        .frame(width: 88)
    }

    // MARK: - 장르 취향
    
    private var myGenreSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("\(viewModel.totalGenreBadgeCount)")
                    .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                Text("개의 장르 뱃지")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                
                Spacer()
            }
            .applyWSSFont(.title2)
            .padding(.vertical, 10)
            
            Spacer().frame(height: 9)
            
            HStack(spacing: 0) {
                ForEach(viewModel.topGenrePreferences, id: \.genre) { preference in
                    representativeGenreItem(preference: preference)
                }
            }
            
            if isGenreListExpanded {
                Spacer().frame(height: 20)
                
                VStack(spacing: 2) {
                    ForEach(viewModel.remainingGenrePreferences, id: \.genre) { preference in
                        genreItemRow(preference: preference)
                    }
                }
                .transition(.opacity)
            }
            
            Spacer().frame(height: 6)
            
            if !viewModel.remainingGenrePreferences.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isGenreListExpanded.toggle()
                    }
                } label: {
                    WSSImage.icDropdownsmall.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(isGenreListExpanded ? 180 : 0))
                        .animation(nil, value: isGenreListExpanded)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func representativeGenreItem(preference: GenrePreference) -> some View {
        VStack(spacing: 0) {
            preference.genre.iconImage
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            
            Spacer().frame(height: 11)
            
            Text(preference.genre.displayName)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
            
            Spacer().frame(height: 2)
            
            Text("\(preference.count)개")
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func genreItemRow(preference: GenrePreference) -> some View {
        HStack(spacing: 0) {
            preference.genre.iconImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            Spacer().frame(width: 21)
            
            Text(preference.genre.displayName)
                .applyWSSFont(.body3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
            
            Spacer()
            
            Text("\(preference.count)개")
                .applyWSSFont(.body3)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
                .padding(.trailing, 20)
        }
        .frame(height: 40)
        .padding(.horizontal, 13)
    }
    
    // MARK: - 작품 취향
    
    private var myNovelPreferenceSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("주로 보는 작품은...")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)

                Spacer()
            }
            .applyWSSFont(.title2)
            .padding(.vertical, 10)

            if viewModel.hasNoPreferenceData {
                preferenceNodataSection
            } else {
                Spacer().frame(height: 20)

                HStack(spacing: 0) {
                    Text(attractivePointsText)
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                    Text("(이)가 매력적인 작품이에요.")
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                }
                .frame(maxWidth: .infinity)
                .applyWSSFont(.title3)
                .padding(.vertical, 14.5)
                .background(WSSColor.wssGray50.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer().frame(height: 20)

                WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    ForEach(viewModel.keywordPreferences, id: \.keyword.id) { item in
                        CountedKeywordChip(keyword: item.keyword.name,
                                           count: item.count)
                    }
                }
            }
        }
        .padding([.horizontal, .bottom], 20)
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
    
    // MARK: - 작품 취향 파악 불가 뷰
    
    private var preferenceNodataSection: some View {
        VStack(spacing: 20) {
            WSSImage.imgEmptyCatQuestionmark.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166)

            Text("작품 취향을 파악할 수 없어요")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
                loadProfileUseCase: PreviewLoadProfileUseCase(),
                loadGenrePreferencesUseCase: PreviewLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: PreviewLoadNovelPreferencesUseCase(),
                loadRegisteredNovelStatsUseCase: PreviewLoadRegisteredNovelStatsUseCase()
            ),
            loadInitialProfileUseCase: PreviewLoadInitialProfileUseCase(),
            loadProfileCharacterUseCase: PreviewLoadProfileCharacterUseCase(),
            validateNicknameUseCase: PreviewValidateNicknameUseCase(),
            updateProfileUseCase: PreviewUpdateProfileUseCase()
        )
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
