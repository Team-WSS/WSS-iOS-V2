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
    
    @FocusState private var isKeyboardFocused: Bool
    
    public init(viewModel: CreateFeedViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            NavigationStack {
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
                }
                .toolbar {
                    createFeedViewToolBarContent()
                }
                .toolbarBackground(
                    WSSColor.wssWhite.swiftUIColor,
                    for: .navigationBar
                )
                .toolbarBackground(.visible, for: .navigationBar)
                .photosPicker(
                    isPresented: $showPhotosPicker,
                    selection: $pickerItems,
                    maxSelectionCount: max(1, FeedDraft.maxImageCount - viewModel.state.draft.attachedImages.count),
                    matching: .images
                )
                .onChange(of: pickerItems) { _, items in
                    guard !items.isEmpty else { return }
                    Task { await handleSelectedImages(items) }
                }
                .sheet(isPresented: $showLinkNovelSheet) {
                    CreateFeedConnectNovelSheet(
                        searchText: Binding(
                            get: { viewModel.state.connectedNovelSearchText },
                            set: { value in viewModel.handleAction(.updateConnectedNovelSearchText(value)) }
                        ),
                        novels: viewModel.state.searchedNovels,
                        selectedNovelID: viewModel.state.selectedSearchedNovelID,
                        isLoading: viewModel.state.isSearchingNovel,
                        onSearch: {
                            viewModel.handleAction(.searchNovel(viewModel.state.connectedNovelSearchText))
                        },
                        onSelect: { novel in
                            viewModel.handleAction(.selectSearchedNovel(novel.id))
                        },
                        onConfirm: {
                            viewModel.handleAction(.confirmSelectedNovel)
                            showLinkNovelSheet = false
                        },
                        dismissSheet: {
                            viewModel.handleAction(.clearNovelSearch)
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
                                viewModel.handleAction(.dismissToast)
                            }
                        }
                    ),
                    type: viewModel.state.toastType
                )
            }
        }
        .showWSSAlert(isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { _ in viewModel.handleAction(.attemptDismiss) }
        ),
                      type: .stopWritingFeed,
                      buttonActions: [
                        {  },
                        { viewModel.handleAction(.attemptDismiss) }
                      ]
        )
    }
    
    // MARK: - 툴바
    
    @ToolbarContentBuilder
    private func createFeedViewToolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            WSSImage.icNavigateLeft.swiftUIImage
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .onTapGesture {
                    viewModel.handleAction(.attemptDismiss)
                }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Text("완료")
                .applyWSSFont(.title2)
                .foregroundStyle(viewModel.canSubmit ?
                                 WSSColor.wssPrimary100.swiftUIColor : WSSColor.wssGray100.swiftUIColor)
                .onTapGesture {
                    guard viewModel.canSubmit else { return }
                    viewModel.handleAction(.submitFeed)
                }
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
                set: { _ in viewModel.handleAction(.togglePrivate) }
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
                set: { _ in viewModel.handleAction(.toggleSpoiler) }
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
                                set: { value in viewModel.handleAction(.updateContent(value)) }
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
            .contentShape(Rectangle()) // 키보드 터치 영역을 위한 영역 설정
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
                    ForEach(viewModel.state.draft.attachedImages, id: \.self) { url in
                        attachedImageThumbnail(url: url)
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
    
    private func attachedImageThumbnail(url: URL) -> some View {
        Group {
            if let uiImage = UIImage(contentsOfFile: url.path) {
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
                viewModel.handleAction(.removeImage(url))
            } label: {
                WSSImage.icCancel.swiftUIImage
                    .frame(width: 38, height: 38)
            }
        }
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
                if viewModel.state.draft.connectedNovel == nil {
                    showLinkNovelSheet.toggle()
                } else {
                    viewModel.handleAction(.alreadyLinkedNovel)
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
                            viewModel.handleAction(.removeConnectedNovel)
                        }
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(WSSColor.wssPrimary20.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Image picker handling
    
    private func handleSelectedImages(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let url = saveImageToTemporaryDirectory(data) else { continue }
            viewModel.handleAction(.addImage(url))
        }
        pickerItems = []
    }
    
    private func saveImageToTemporaryDirectory(_ data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}


//MARK: - Preview

#Preview {
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

private struct PreviewCreateFeedUseCase: CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) { }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [
            Novel(
                    id: NovelID(1),
                    thumbnailImage: URL(string: "https://i.pinimg.com/736x/58/0a/13/580a13692bdefec82fc37cdc8e87e331.jpg"),
                    title: "회귀한 천재 마법사",
                    authors: ["김작가"],
                    interestCount: 12543,
                    rating: 4.8,
                    ratingCount: 3214
                ),
                Novel(
                    id: NovelID(2),
                    thumbnailImage: URL(string: "https://i.pinimg.com/736x/12/49/04/124904e3933472601d83f8ff771def50.jpg"),
                    title: "멸망한 세계의 검신",
                    authors: ["이판타지"],
                    interestCount: 8932,
                    rating: 4.6,
                    ratingCount: 1875
                ),
                Novel(
                    id: NovelID(3),
                    thumbnailImage: URL(string: "https://i.pinimg.com/736x/fc/11/ed/fc11ed1b94cc32feefc9e40f1b2d8f65.jpg"),
                    title: "재벌집 막내아들",
                    authors: ["산경"],
                    interestCount: 25431,
                    rating: 4.9,
                    ratingCount: 10234
                ),
                Novel(
                    id: NovelID(4),
                    thumbnailImage: URL(string: "https://i.pinimg.com/1200x/b9/94/6e/b9946e9db54c175c490b54dfd40adc41.jpg"),
                    title: "나 혼자만 레벨업",
                    authors: ["추공"],
                    interestCount: 51234,
                    rating: 4.9,
                    ratingCount: 25431
                ),
                Novel(
                    id: NovelID(5),
                    thumbnailImage: URL(string: "https://i.pinimg.com/1200x/d6/49/7a/d6497aefa2800044f63cbf66889fb4df.jpg"),
                    title: "전지적 독자 시점",
                    authors: ["싱숑"],
                    interestCount: 43892,
                    rating: 4.8,
                    ratingCount: 19876
                ),
                Novel(
                    id: NovelID(6),
                    thumbnailImage: URL(string: "https://i.pinimg.com/1200x/20/55/03/20550396102b05d92c4a04f9136352d5.jpg"),
                    title: "아카데미의 천재 검술가",
                    authors: ["홍길동", "김철수"],
                    interestCount: 7234,
                    rating: 4.3,
                    ratingCount: 912
                ),
                Novel(
                    id: NovelID(7),
                    thumbnailImage: URL(string: "https://i.pinimg.com/736x/01/7b/8d/017b8dd944076cb85da607fe2d94237a.jpg"),
                    title: "21세기 대군 부인",
                    authors: ["박작가"],
                    interestCount: 16782,
                    rating: 4.7,
                    ratingCount: 3842
                ),
                Novel(
                    id: NovelID(8),
                    thumbnailImage: URL(string: "https://i.pinimg.com/736x/69/80/22/69802233c6656902b1eedb94f6b338b2.jpg"),
                    title: "망겜의 성기사",
                    authors: ["최작가"],
                    interestCount: 5321,
                    rating: 4.1,
                    ratingCount: 623
                )
            
        ], hasNext: false), 0)
    }
    
    func searchByFilter(_ filter: NovelDomain.SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [], hasNext: false), 0)
    }
}
