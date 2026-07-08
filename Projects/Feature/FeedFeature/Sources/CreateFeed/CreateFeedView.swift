//
//  CreateFeedView.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI
import PhotosUI

import BaseDomain
import FeedDomain
import NovelDomain
import DesignSystem
import WSSComponent

public struct CreateFeedView: View {
    
    @State private var viewModel: CreateFeedViewModel
    
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPhotosPicker: Bool = false
    @State private var showLinkNovelSheet: Bool = false
    @State private var showDismissAlert: Bool = false
    
    @FocusState private var isKeyboardFocused: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: CreateFeedViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
                VStack(spacing: 0) {
                    privateSection
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            
                            Spacer().frame(height: 30)
                            
                            contentSection
                            
                            Spacer().frame(height: 13)
                            
                            spoilerSection
                            
                            if !viewModel.state.draft.attachedImages.isEmpty {
                                Spacer().frame(height: 14)
                                
                                attachedImagesSection
                            }
                            
                            Spacer().frame(height: 30)
                            
                            connectedNovelSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isKeyboardFocused = false
                }
                // 업로드 중엔 draft를 더 이상 바꿀 수 없어야 해서 hit-testing 자체를 막는다.
                // 대부분의 행이 Button이 아니라 onTapGesture라 .disabled()만으론 막히지 않는다.
                .allowsHitTesting(!viewModel.isSubmitting)
                .opacity(viewModel.isSubmitting ? 0.5 : 1)
                .toolbar {
                    createFeedViewToolBarContent()
                }
                .toolbarBackground(
                    WSSColor.wssWhite.swiftUIColor,
                    for: .navigationBar
                )
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .photosPicker(
                    isPresented: $showPhotosPicker,
                    selection: $pickerItems,
                    maxSelectionCount: max(1, FeedDraft.maxImageCount - viewModel.state.draft.attachedImages.count),
                    matching: .images
                )
                .onChange(of: pickerItems) { _, items in
                    guard !items.isEmpty else { return }
                    Task { await dispatchPickedItems(items) }
                }
                .sheet(isPresented: $showLinkNovelSheet) {
                    CreateFeedConnectNovelSheet(
                        searchText: Binding(
                            get: { viewModel.state.connectedNovelSearchText },
                            set: { value in viewModel.handle(.updateConnectedNovelSearchText(value)) }
                        ),
                        novels: viewModel.state.searchedNovels,
                        selectedNovelID: viewModel.state.selectedSearchedNovelID,
                        isLoading: viewModel.state.isSearchingNovel,
                        onSearch: {
                            viewModel.handle(.searchNovel(viewModel.state.connectedNovelSearchText))
                        },
                        onSelect: { novel in
                            viewModel.handle(.selectSearchedNovel(novel.id))
                        },
                        onConfirm: {
                            viewModel.handle(.confirmSelectedNovel)
                            showLinkNovelSheet = false
                        },
                        inquiryNovelAction: { },
                        dismissSheet: {
                            viewModel.handle(.dismissLinkNovelSheet)
                            showLinkNovelSheet = false
                        }
                    )
                    .interactiveDismissDisabled()
                }
                .showWSSToast(
                    isPresented: Binding(
                        get: { viewModel.state.showToast },
                        set: { newValue in
                            if !newValue {
                                viewModel.handle(.dismissToast)
                            }
                        }
                    ),
                    type: toastType
                )
        }
        .showWSSAlert(
            isPresented: $showDismissAlert,
            type: .stopWritingFeed,
            buttonActions: [
                { dismiss() },
                { showDismissAlert = false }
            ]
        )
    }
    
    // MARK: - Presentation

    /// `state.validationError`를 화면에 노출할 `WSSToastType`으로 매핑한다.
    /// 어떤 종류를 토스트로 띄울지(`showToast`)는 ViewModel이, 어떤 문구/스타일로 보여줄지는 View가 결정한다.
    private var toastType: WSSToastType {
        switch viewModel.state.validationError {
        case .imageOverLimit(let max):
            return .limitAddImage(limitCount: max)
        case .connectedNovelOverLimit:
            return .novelAlreadyConnected
        case .contentOverLimit, .emptyContent, nil:
            return .networkDelay
        }
    }

    // MARK: - 툴바
    
    @ToolbarContentBuilder
    private func createFeedViewToolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            WSSImage.icNavigateLeft.swiftUIImage
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .frame(width: 24, height: 24)
                .onTapGesture {
                    showDismissAlert = true
                }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.handle(.submitFeed)
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(viewModel.canSubmit ?
                                         WSSColor.wssPrimary100.swiftUIColor : WSSColor.wssGray100.swiftUIColor)
                }
            }
            .disabled(!viewModel.canSubmit)
        }
    }

    private var privateSection: some View {
        HStack(spacing: 0) {
            WSSImage.icLock.swiftUIImage
                .frame(width: 18, height: 18)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
            
            Spacer().frame(width: 4)
            
            Text("나만 보는 기록")
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
            
            Spacer()
            
            WSSToggleButton(isOn: Binding(
                get: { viewModel.state.draft.isPrivate },
                set: { _ in viewModel.handle(.togglePrivate) }
            ))
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(WSSColor.wssGray300.swiftUIColor)
    }
    
    private var spoilerSection: some View {
        HStack(spacing: 0) {
            Group {
                Text("잠깐, ")
                Text("스포일러")
                    .fontWeight(.semibold)
                Text("가 있나요?")
            }
            .applyWSSFont(.body3)
            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            
            Spacer()
            
            WSSToggleButton(isOn: Binding(
                get: { viewModel.state.draft.isSpoiler },
                set: { _ in viewModel.handle(.toggleSpoiler) }
            ))
        }
        .padding(.horizontal, 20)
        .frame(height: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(WSSColor.wssGray70.swiftUIColor,
                        lineWidth: 1)
        )
    }
    
    private var contentSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                    if viewModel.state.draft.content.isEmpty {
                        Text("웹소설과 관련된 글을 자유롭게 남겨보세요\n\n • 작품에 대한 한줄평\n • 여운이 남는 명장면, 명대사\n • 수다 떨고 싶은 작품 이야기\n • 다른 독자들과 공유하고 싶은 작품 정보 등")
                            .applyWSSFont(.body2)
                            .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .allowsHitTesting(false)
                    }
                    
                    TextField("",
                              text: Binding(
                                get: { viewModel.state.draft.content },
                                set: { value in viewModel.handle(.updateContent(value)) }
                              ),
                              axis: .vertical)
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .focused($isKeyboardFocused)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
               
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isKeyboardFocused = true
            }
            
            HStack(spacing: 0) {
                WSSImage.icImage.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        showPhotosPicker.toggle()
                    }
                
                Spacer()
                
                Text("(\(String(viewModel.state.draft.content.count))/\(String(FeedDraft.maxContentCount)))")
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(height: 360)
        .background(WSSColor.wssGray50.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var attachedImagesSection: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal,
                       showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.state.draft.attachedImages, id: \.self) { id in
                        attachedImageThumbnail(id: id)
                    }
                }
            }
            
            Spacer().frame(height: 12)
            
            HStack(spacing: 0) {
                Text("\(viewModel.state.draft.attachedImages.count)")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                
                Text("/\(FeedDraft.maxImageCount)")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                
                Spacer()
            }
            
        }
    }
    
    private func attachedImageThumbnail(id: AttachedImageID) -> some View {
        Group {
            if let data = viewModel.state.attachedImageDatas[id],
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                WSSColor.wssGray50.swiftUIColor
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.handle(.removeImage(id))
            } label: {
                WSSImage.icCancel.swiftUIImage
                    .frame(width: 38, height: 38)
            }
        }
    }

    // MARK: - Image handling

    /// PhotosPicker 결과를 Data로 통역해 ViewModel에 전달한다.
    /// 도메인 등록/한계 검증/저장은 모두 ViewModel이 담당.
    private func dispatchPickedItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            viewModel.handle(.addImage(id: AttachedImageID(), data: data))
        }
        pickerItems = []
    }
    
    private var connectedNovelSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("작품 연결")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer()
            }
            
            Spacer().frame(height: 17)
            
            HStack(spacing: 0) {
                Text("작품 제목, 작가 검색")
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                
                Spacer()
                
                WSSImage.icSearch.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    .frame(width: 36, height: 36)
            }
            .padding(.vertical, 3)
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .background(WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture {
                //TODO: - ViewModel로 로직빼기 + 알럿 띄우는 bool변수도 viewModel에 포함될 수 있도록 한다.
                if viewModel.state.draft.connectedNovel == nil {
                    showLinkNovelSheet.toggle()
                } else {
                    viewModel.handle(.alreadyLinkedNovel)
                }
            }
            
            if (viewModel.state.draft.connectedNovel != nil) {
                Spacer().frame(height: 12)
                
                HStack(spacing: 0) {
                    WSSImage.icGenreLink.swiftUIImage
                        .renderingMode(.template)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                        .padding(.trailing, 6)
                    
                    Text(viewModel.state.draft.connectedNovel?.title ?? "웹소소도 소설이다")
                        .applyWSSFont(.title3)
                        .foregroundStyle(Color.wssBlack)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    WSSImage.icCancel.swiftUIImage
                        .onTapGesture {
                            viewModel.handle(.removeConnectedNovel)
                        }
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(WSSColor.wssPrimary20.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}


//MARK: - Preview

#Preview {
    NavigationStack {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                createFeedUseCase: PreviewCreateFeedUseCase(),
                searchNovelUseCase: PreviewSearchNovelUseCase(),
                initialDraft: FeedDraft(
                    content: "",
                    isSpoiler: false,
                    isPrivate: false,
                    attachedImages: []
                )
            )
        )
    }
}

private struct PreviewCreateFeedUseCase: CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) { }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: stubNovels, hasNext: false), 0)
    }
    
    func searchByFilter(_ filter: NovelDomain.SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [], hasNext: false), 0)
    }
}
