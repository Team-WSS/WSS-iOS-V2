//
//  MyPageEditView.swift
//  MypageFeature
//
//  Created by Seoyeon Choi on 7/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent
import BaseDomain
import ProfileDomain
import Logger

struct MyPageEditView: View {

    @State private var viewModel: MyPageEditViewModel
    @State private var showCharacterEditSheet: Bool = false

    @FocusState private var isKeyboardFocused: Bool

    @Environment(\.dismiss) private var dismiss

    /// 캐릭터 선택 시트를 열 때마다 독립된 ViewModel을 새로 만들기 위한 의존성.
    private let loadProfileCharacterUseCase: LoadProfileCharacterUseCase
    private let logger: Logger?
    /// 저장 성공으로 닫힐 때 호출. "저장됨" 토스트는 이 화면이 아니라 복귀할 부모가 보여준다
    /// (dismiss와 동시에 보이도록 — 이 화면에서 sleep으로 노출 시간을 벌면 닫힘이 부자연스럽게 지연된다).
    private let onSaved: () -> Void

    init(
        viewModel: MyPageEditViewModel,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        logger: Logger? = nil,
        onSaved: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.loadProfileCharacterUseCase = loadProfileCharacterUseCase
        self.logger = logger
        self.onSaved = onSaved
    }

    var body: some View {
        content
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.state.loadFailed {
                    NetworkErrorView { viewModel.handle(.load) }
                }
            }
            .background(WSSColor.wssWhite.swiftUIColor)
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                viewModel.handle(.load)
            }
            .sheet(isPresented: $showCharacterEditSheet) {
                MypageCharacterEditSheet(
                    viewModel: MypageCharacterEditSheetViewModel(
                        selectedCharacterID: viewModel.state.draft.characterID,
                        loadProfileCharacterUseCase: loadProfileCharacterUseCase,
                        logger: logger
                    ),
                    nickname: viewModel.state.draft.nickname.text,
                    onApply: { characterID in
                        viewModel.handle(.selectCharacter(characterID))
                    }
                )
            }
            .showWSSToast(isPresented: toastBinding, type: .unknownError)
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                guard shouldDismiss else { return }
                onSaved()
                dismiss()
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 38)
                
                profileImageSection
                
                Spacer().frame(height: 29)
                
                nicknameSection
                
                Spacer().frame(height: 20)
                
                divider
                
                Spacer().frame(height: 15)
                
                descriptionSection
                
                Spacer().frame(height: 20)
                
                divider
                
                Spacer().frame(height: 15)
                
                preferenceGenreSection
                
                Spacer()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentShape(Rectangle())
        .onTapGesture {
            isKeyboardFocused = false
        }
    }

    private var profileImageSection: some View {
        VStack(spacing: 0) {
            AsyncImage(url: viewModel.selectedCharacterImage) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    WSSImage.imgEmptyCover.swiftUIImage
                        .resizable()
                        .scaledToFit()
                default:
                    ProgressView()
                }
            }
            .clipShape(Circle())
            .frame(width: 94, height: 94)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showCharacterEditSheet.toggle()
                } label: {
                    WSSImage.icPlusMyPage.swiftUIImage
                        .resizable()
                        .frame(width: 25, height: 25)
                }
            }
        }
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("닉네임")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 7)

            HStack(spacing: 7) {
                HStack(spacing: 0) {
                    TextField("", text: nicknameTextBinding)
                        .padding(.vertical, 10.5)
                        .padding(.leading, 12)
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                        .tint(WSSColor.wssBlack.swiftUIColor)
                        .focused($isKeyboardFocused)

                    if !viewModel.state.draft.nickname.text.isEmpty {
                        Button(action: { viewModel.handle(.updateNickname("")) }) {
                            WSSImage.icCancel.swiftUIImage
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .background(WSSColor.wssGray50.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(nicknameBorderColor ?? .clear, lineWidth: 1)
                )

                Button {
                    viewModel.handle(.checkNicknameDuplication)
                } label: {
                    Group {
                        if viewModel.state.isCheckingNickname {
                            ProgressView()
                        } else {
                            Text("중복확인")
                                .applyWSSFont(.body2)
                                .foregroundStyle(
                                    isDuplicationCheckEnabled
                                        ? WSSColor.wssPrimary100.swiftUIColor
                                        : WSSColor.wssGray200.swiftUIColor
                                )
                        }
                    }
                    .frame(width: 88, height: 44)
                    .background(
                        isDuplicationCheckEnabled
                            ? WSSColor.wssPrimary50.swiftUIColor
                            : WSSColor.wssGray70.swiftUIColor
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isDuplicationCheckEnabled)
            }

            Spacer().frame(height: 4)

            HStack(spacing: 0) {
                if let caption = nicknameValidationCaption {
                    Text(caption.text)
                        .applyWSSFont(.body4)
                        .foregroundStyle(caption.color)
                }
                
                Spacer()
                
                Text("\(viewModel.state.draft.nickname.text.count)")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                Text(" / \(NicknameDraft.maxLength)")
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            .applyWSSFont(.body4)
        }
        .padding(.horizontal, 20)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("소개")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 7)

            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if viewModel.state.draft.introduction.isEmpty {
                        HStack(spacing: 0) {
                            Text("소개글을 적어보세요!")
                                .applyWSSFont(.body2)
                                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                                .multilineTextAlignment(.leading)
                                .allowsHitTesting(false)
                            Spacer()
                        }
                    }

                    TextField("", text: introductionTextBinding, axis: .vertical)
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                        .tint(WSSColor.wssBlack.swiftUIColor)
                        .focused($isKeyboardFocused)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(height: 75)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isKeyboardFocused = true
            }
            .background(WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer().frame(height: 4)

            HStack(spacing: 0) {
                Spacer()
                Text("\(viewModel.state.draft.introduction.count)")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                Text(" / \(ProfileDraft.maxIntroductionLength)")
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            .applyWSSFont(.body4)
        }
        .padding(.horizontal, 20)
    }

    private var preferenceGenreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("선호장르")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 6)

            Text("선택한 장르에 맞춰 작품을 추천해 드려요")
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

            Spacer().frame(height: 14)

            WSSFlowLayout(
                horizontalSpacing: 6,
                verticalSpacing: 14)
            {
                ForEach(NovelGenre.profileEditGenre, id: \.self) { genre in
                    let isSelected = viewModel.state.draft.genrePreferences.contains { $0.genre == genre }
                    CapsuleSelectableKeywordChip(
                        keyword: genre.displayName,
                        isSelected: isSelected,
                        action: { viewModel.handle(.toggleGenrePreference(genre)) }
                    )
                }
            }
            
            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 20)
    }
}

extension MyPageEditView {
    private var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
    }
}

extension MyPageEditView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("프로필 편집")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.handle(.save)
            } label: {
                if viewModel.state.isSaving {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(
                            viewModel.state.draft.isSubmittable
                                ? WSSColor.wssPrimary100.swiftUIColor
                                : WSSColor.wssGray200.swiftUIColor
                        )
                }
            }
            .disabled(!viewModel.state.draft.isSubmittable || viewModel.state.isSaving)
        }
    }
}

// MARK: - Presentation

private extension MyPageEditView {
    var nicknameTextBinding: Binding<String> {
        Binding(
            get: { viewModel.state.draft.nickname.text },
            set: { viewModel.handle(.updateNickname($0)) }
        )
    }

    var introductionTextBinding: Binding<String> {
        Binding(
            get: { viewModel.state.draft.introduction },
            set: { viewModel.handle(.updateIntroduction($0)) }
        )
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// 닉네임 검증 상태(의미값) → 캡션 문구/색(표현). `notStarted`·`needDuplicatedCheck`·`notChanged`는
    /// 사용자가 아직 조치할 게 없거나 조치가 필요없는 상태라 캡션을 띄우지 않는다.
    var nicknameValidationCaption: (text: String, color: Color)? {
        switch viewModel.state.draft.nickname.validationState {
        case .notStarted, .needDuplicatedCheck, .notAvailable(.notChanged):
            return nil
        case .notAvailable(.whiteSpaceIncluded):
            return ("공백은 사용할 수 없어요", WSSColor.wssSecondary100.swiftUIColor)
        case .notAvailable(.invalidCharacterOrLimitExceeded):
            return ("2~10자의 한글, 영문, 숫자만 사용할 수 있어요", WSSColor.wssSecondary100.swiftUIColor)
        case .notAvailable(.duplicated):
            return ("이미 사용 중인 닉네임이에요", WSSColor.wssSecondary100.swiftUIColor)
        case .available:
            return ("사용할 수 있는 닉네임이에요", WSSColor.wssPrimary100.swiftUIColor)
        }
    }

    /// 형식 오류·공백·중복 등 사용자가 고쳐야 하는 상태만 에러로 취급한다("변경 없음"은 에러가 아니다).
    var isNicknameError: Bool {
        switch viewModel.state.draft.nickname.validationState {
        case .notAvailable(.whiteSpaceIncluded), .notAvailable(.invalidCharacterOrLimitExceeded), .notAvailable(.duplicated):
            return true
        default:
            return false
        }
    }

    /// 닉네임 필드 테두리 색 — 에러=secondary100, 사용 가능=primary100, 그 외(입력 전·미변경·확인 대기)엔 테두리 없음.
    var nicknameBorderColor: Color? {
        if isNicknameError {
            return WSSColor.wssSecondary100.swiftUIColor
        }
        if viewModel.state.draft.nickname.validationState == .available {
            return WSSColor.wssPrimary100.swiftUIColor
        }
        return nil
    }

    /// 중복확인 버튼은 "새 닉네임을 입력했고, 아직 에러 없이 확인이 필요한" 상태에서만 primary로 활성화된다.
    var isDuplicationCheckEnabled: Bool {
        viewModel.state.draft.nickname.validationState == .needDuplicatedCheck
    }
}

#Preview {
    NavigationStack {
        MyPageEditView(
            viewModel: MyPageEditViewModel(
                loadInitialProfileUseCase: PreviewLoadInitialProfileUseCase(),
                loadProfileCharacterUseCase: PreviewLoadProfileCharacterUseCase(),
                validateNicknameUseCase: PreviewValidateNicknameUseCase(),
                updateProfileUseCase: PreviewUpdateProfileUseCase()
            ),
            loadProfileCharacterUseCase: PreviewLoadProfileCharacterUseCase(),
            onSaved: { print("저장됨") }
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
