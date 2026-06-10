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
import DesignSystem
import WSSComponent

public struct CreateFeedView: View {
    
    @State private var viewModel: CreateFeedViewModel
    @State private var pickerItems: [PhotosPickerItem] = []
   
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
                    isPresented: Binding(
                        get: { viewModel.state.showImagePicker },
                        set: { _ in viewModel.handleAction(.selectImagePhotoPicker) }
                    ),
                    selection: $pickerItems,
                    maxSelectionCount: max(1, FeedDraft.maxImageCount - viewModel.state.draft.attachedImages.count),
                    matching: .images
                )
                .onChange(of: pickerItems) { _, items in
                    guard !items.isEmpty else { return }
                    Task { await handleSelectedImages(items) }
                }
                .sheet(isPresented: Binding(
                    get: { viewModel.state.showLinkNovelSheet },
                    set: { _ in viewModel.handleAction(.selectConnectedNovel) }
                )) {
                    //TODO: - 작품 연결 뷰 추가
                    Text("작품 연결")
                }
                .showWSSToast(isPresented: Binding(
                    get: { viewModel.state.showToast },
                    set: { _ in viewModel.handleAction(.selectConnectedNovel) }
                ),
                              type: viewModel.state.toastType)
                
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
    
    // 툴바
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
            Text("잠깐, 스포일러가 있나요?")
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
            .onTapGesture {
                isKeyboardFocused.toggle()
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                WSSImage.icImage.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        viewModel.handleAction(.selectImagePhotoPicker)
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
                viewModel.handleAction(.selectConnectedNovel)
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

#Preview {
    CreateFeedView(
        viewModel: CreateFeedViewModel(
            createFeedUseCase: PreviewCreateFeedUseCase(),
            initialDraft: FeedDraft(
                content: "",
                isSpoiler: false,
                isPrivate: false,
                connectedNovel: ConnectedNovel(
                    id: NovelID(1),
                    title: "괴담에 떨어져도 출근을 해야 하는구나",
                    genre: .modernFantasy,
                    rating: 4.32
                ),
                attachedImages: []
            )
        )
    )
}

private struct PreviewCreateFeedUseCase: CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) { }
}
