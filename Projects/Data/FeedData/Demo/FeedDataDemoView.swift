//
//  FeedDataDemoView.swift
//  FeedDataDemo
//
//  Created by WonsunLee on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import PhotosUI
import UIKit
import FeedData
import FeedDomain
import BaseDomain
import Networking
import BaseData
import Logger

struct FeedDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var isLoading: Bool = false
    @State private var selectedTab: Int = 0

    // Feed CRUD
    @State private var feedIDText: String = ""
    @State private var contentText: String = "테스트 피드 내용입니다."
    @State private var isSpoiler: Bool = false
    @State private var isPrivate: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageDatas: [Data] = []

    // Feed Lists
    @State private var lastFeedIDText: String = "0"
    @State private var userIDText: String = ""
    @State private var novelIDText: String = ""
    @State private var sosoOption: SosoFeedOption = .all
    @State private var visibilityType: VisibilityType = .all

    private let repository: FeedRepository

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let logger = DataLogger(moduleName: "FeedData", underlying: OSLogger.feed)
        self.repository = FeedDataFactory.makeFeedRepository(client: client, logger: logger)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("탭", selection: $selectedTab) {
                    Text("CRUD").tag(0)
                    Text("Detail & Like").tag(1)
                    Text("Lists").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: feedCRUDSection
                        case 1: feedDetailSection
                        default: feedListSection
                        }
                    }
                    .padding(.bottom, 16)
                }

                logSection
            }
            .navigationTitle("Feed Demo")
        }
    }

    // MARK: - Tab: CRUD

    private var feedCRUDSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("피드 작성 (장르: romance 고정)").font(.headline).padding(.horizontal)
                TextField("내용", text: $contentText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                HStack {
                    Toggle("스포일러", isOn: $isSpoiler)
                    Toggle("비공개", isOn: $isPrivate)
                }
                .padding(.horizontal)
                imageAttachmentRow
                demoButton("작성", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await submitFeed() }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("피드 수정 / 삭제").font(.headline).padding(.horizontal)
                TextField("피드 ID", text: $feedIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                HStack(spacing: 8) {
                    demoButton("수정", bg: Color(red: 0.92, green: 0.90, blue: 0.99), fg: .indigo) {
                        Task { await editFeed() }
                    }
                    demoButton("삭제", bg: Color(red: 1.0, green: 0.92, blue: 0.92), fg: .red) {
                        Task { await deleteFeed() }
                    }
                }
                .padding(.horizontal)
            }
        }
        .disabled(isLoading)
    }

    // MARK: - Tab: Detail & Like

    private var feedDetailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("피드 ID 입력").font(.headline).padding(.horizontal)
            TextField("피드 ID", text: $feedIDText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .padding(.horizontal)

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("상세 조회").font(.headline).padding(.horizontal)
                demoButton("상세 조회", bg: Color(red: 0.88, green: 0.94, blue: 1.0), fg: Color(red: 0.2, green: 0.4, blue: 0.9)) {
                    Task { await fetchFeedDetail() }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("좋아요").font(.headline).padding(.horizontal)
                HStack(spacing: 8) {
                    demoButton("좋아요", bg: Color(red: 1.0, green: 0.94, blue: 0.88), fg: .orange) {
                        Task { await addLike() }
                    }
                    demoButton("좋아요 취소", bg: Color(red: 0.99, green: 0.90, blue: 0.95), fg: .pink) {
                        Task { await deleteLike() }
                    }
                }
                .padding(.horizontal)
            }
        }
        .disabled(isLoading)
    }

    // MARK: - Tab: Lists

    private var feedListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("lastFeedID").font(.caption).foregroundColor(.secondary)
                TextField("0", text: $lastFeedIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
            }
            .padding(.horizontal)

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("소소 피드").font(.headline).padding(.horizontal)
                Picker("옵션", selection: $sosoOption) {
                    Text("전체").tag(SosoFeedOption.all)
                    Text("추천").tag(SosoFeedOption.recommended)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                demoButton("소소 피드 조회", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await fetchSosoFeeds() }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("유저 피드").font(.headline).padding(.horizontal)
                TextField("유저 ID", text: $userIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                demoButton("유저 피드 조회", bg: Color(red: 0.92, green: 0.88, blue: 1.0), fg: Color(red: 0.45, green: 0.2, blue: 0.85)) {
                    Task { await fetchUserFeeds() }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("내 피드").font(.headline).padding(.horizontal)
                Picker("공개여부", selection: $visibilityType) {
                    Text("전체").tag(VisibilityType.all)
                    Text("공개").tag(VisibilityType.publicOnly)
                    Text("비공개").tag(VisibilityType.privateOnly)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                demoButton("내 피드 조회", bg: Color(red: 0.95, green: 0.95, blue: 0.88), fg: Color(red: 0.55, green: 0.5, blue: 0.1)) {
                    Task { await fetchMyFeeds() }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("소설 피드").font(.headline).padding(.horizontal)
                TextField("소설 ID", text: $novelIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                demoButton("소설 피드 조회", bg: Color(red: 0.88, green: 0.94, blue: 1.0), fg: Color(red: 0.2, green: 0.4, blue: 0.9)) {
                    Task { await fetchNovelFeeds() }
                }
                .padding(.horizontal)
            }
        }
        .disabled(isLoading)
    }

    // MARK: - Image Attachment

    private var imageAttachmentRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Label("이미지 첨부 (\(selectedImageDatas.count)/5)", systemImage: "photo")
                        .font(.subheadline)
                }
                Spacer()
                if !selectedImageDatas.isEmpty {
                    Button("초기화") {
                        selectedItems = []
                        selectedImageDatas = []
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .onChange(of: selectedItems) { _, items in
                Task { await loadSelectedImages(items) }
            }

            if !selectedImageDatas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(selectedImageDatas.enumerated()), id: \.offset) { _, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        var datas: [Data] = []
        for item in items {
            guard let raw = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: raw),
                  let jpeg = image.jpegData(compressionQuality: 0.8) else { continue }
            datas.append(jpeg)
        }
        selectedImageDatas = datas
    }

    // MARK: - Shared Log

    private var logSection: some View {
        ScrollView {
            Text(log)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
    }

    // MARK: - demoButton

    private func demoButton(
        _ title: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(fg)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var feedID: FeedID? {
        guard let v = Int(feedIDText) else { return nil }
        return FeedID(v)
    }

    private var lastFeedID: FeedID {
        FeedID(Int(lastFeedIDText) ?? 0)
    }

    // MARK: - Actions: CRUD

    private func submitFeed() async {
        let draft = FeedDraft(
            content: contentText,
            genre: [.romance],
            isSpoiler: isSpoiler,
            isPrivate: isPrivate,
            attachedImages: []
        )
        let imageDatas = selectedImageDatas
        let url = "/feeds"
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.submitFeed(draft, imageDatas: imageDatas)
            log = "endpoint: .postFeed\n[POST] \(url)\n\n작성 성공\n내용: \(contentText.prefix(50))\n스포일러: \(isSpoiler) | 비공개: \(isPrivate)\n이미지: \(imageDatas.count)장"
            selectedItems = []
            selectedImageDatas = []
        } catch {
            log = "endpoint: .postFeed\n[POST] \(url)\n\n작성 실패\n\(error)"
        }
    }

    private func editFeed() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        let draft = FeedDraft(
            content: contentText,
            genre: [.romance],
            isSpoiler: isSpoiler,
            isPrivate: isPrivate,
            attachedImages: []
        )
        let imageDatas = selectedImageDatas
        let url = "/feeds/\(feedID.value)"
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.editFeed(id: feedID, draft: draft, imageDatas: imageDatas)
            log = "endpoint: .patchFeed(feedID: \(feedID.value))\n[PUT] \(url)\n\n수정 성공\n내용: \(contentText.prefix(50))\n이미지: \(imageDatas.count)장"
            selectedItems = []
            selectedImageDatas = []
        } catch {
            log = "endpoint: .patchFeed(feedID: \(feedID.value))\n[PUT] \(url)\n\n수정 실패\n\(error)"
        }
    }

    private func deleteFeed() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        let url = "/feeds/\(feedID.value)"
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.deleteFeed(id: feedID)
            log = "endpoint: .deleteFeed(feedID: \(feedID.value))\n[DELETE] \(url)\n\n삭제 성공"
        } catch {
            log = "endpoint: .deleteFeed(feedID: \(feedID.value))\n[DELETE] \(url)\n\n삭제 실패\n\(error)"
        }
    }

    // MARK: - Actions: Detail & Like

    private func fetchFeedDetail() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        let url = "/feeds/\(feedID.value)"
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            let detail = try await repository.fetchFeedDetail(id: feedID)
            log = "endpoint: .getFeedDetail(feedID: \(feedID.value))\n[GET] \(url)\n\n\(formatFeedDetail(detail))"
        } catch {
            log = "endpoint: .getFeedDetail(feedID: \(feedID.value))\n[GET] \(url)\n\n상세 조회 실패\n\(error)"
        }
    }

    private func addLike() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        let url = "/feeds/\(feedID.value)/likes"
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.addLike(id: feedID)
            log = "endpoint: .postLike(feedID: \(feedID.value))\n[POST] \(url)\n\n좋아요 성공"
        } catch {
            log = "endpoint: .postLike(feedID: \(feedID.value))\n[POST] \(url)\n\n좋아요 실패\n\(error)"
        }
    }

    private func deleteLike() async {
        guard let feedID else { log = "피드 ID를 입력해주세요."; return }
        let url = "/feeds/\(feedID.value)/likes"
        feedIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.deleteLike(id: feedID)
            log = "endpoint: .deleteLike(feedID: \(feedID.value))\n[DELETE] \(url)\n\n좋아요 취소 성공"
        } catch {
            log = "endpoint: .deleteLike(feedID: \(feedID.value))\n[DELETE] \(url)\n\n좋아요 취소 실패\n\(error)"
        }
    }

    // MARK: - Actions: Lists

    private func fetchSosoFeeds() async {
        let url = "/feeds"
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await repository.fetchSosoFeeds(option: sosoOption, lastFeedID: lastFeedID)
            log = "endpoint: .getSosoFeeds\n[GET] \(url)\n파라미터: feedsOption=\(sosoOption.rawValue), lastFeedId=\(lastFeedID.value)\n\n\(formatFeeds(result))"
        } catch {
            log = "endpoint: .getSosoFeeds\n[GET] \(url)\n\n소소 피드 조회 실패\n\(error)"
        }
    }

    private func fetchUserFeeds() async {
        guard let userIDValue = Int(userIDText) else { log = "유저 ID를 입력해주세요."; return }
        let url = "/users/\(userIDValue)/feeds"
        userIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await repository.fetchUserFeeds(id: UserID(userIDValue), lastFeedID: lastFeedID)
            log = "endpoint: .getUserFeeds(userID: \(userIDValue))\n[GET] \(url)\n파라미터: lastFeedId=\(lastFeedID.value)\n\n\(formatFeeds(result))"
        } catch {
            log = "endpoint: .getUserFeeds(userID: \(userIDValue))\n[GET] \(url)\n\n유저 피드 조회 실패\n\(error)"
        }
    }

    private func fetchMyFeeds() async {
        let myUserID = UserDefaultsStorage().get(.userID) ?? 0
        let option = MyFeedOption(genres: [], visibilityType: visibilityType, sortType: .recent)
        let url = "/users/\(myUserID)/feeds"
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await repository.fetchMyFeeds(option: option, lastFeedID: lastFeedID)
            log = "endpoint: .getMyFeeds(userID: \(myUserID))\n[GET] \(url)\n파라미터: visibility=\(visibilityLabel), lastFeedId=\(lastFeedID.value)\n\n\(formatFeeds(result))"
        } catch {
            log = "endpoint: .getMyFeeds(userID: \(myUserID))\n[GET] \(url)\n\n내 피드 조회 실패\n\(error)"
        }
    }

    private func fetchNovelFeeds() async {
        guard let novelIDValue = Int(novelIDText) else { log = "소설 ID를 입력해주세요."; return }
        let url = "/novels/\(novelIDValue)/feeds"
        novelIDText = ""
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await repository.fetchNovelFeeds(id: NovelID(novelIDValue), lastFeedID: lastFeedID)
            log = "endpoint: .getNovelFeeds(novelID: \(novelIDValue))\n[GET] \(url)\n파라미터: lastFeedId=\(lastFeedID.value)\n\n\(formatFeeds(result))"
        } catch {
            log = "endpoint: .getNovelFeeds(novelID: \(novelIDValue))\n[GET] \(url)\n\n소설 피드 조회 실패\n\(error)"
        }
    }

    // MARK: - Formatters

    private var visibilityLabel: String {
        switch visibilityType {
        case .all: return "전체"
        case .publicOnly: return "공개"
        case .privateOnly: return "비공개"
        }
    }

    private func formatFeeds(_ result: Paginated<TotalFeed>) -> String {
        let feeds = result.items
        if feeds.isEmpty { return "피드 없음" }
        var text = "피드 \(feeds.count)개 (hasNext: \(result.hasNext))\n\n"
        for f in feeds.prefix(3) {
            text += "[\(f.feedId.value)] \(f.author.nickname): \(f.content.prefix(30))...\n"
        }
        return text
    }

    private func formatFeedDetail(_ detail: FeedDetail) -> String {
        """
        feedID: \(detail.id.value)
        작성자: \(detail.author.nickname)
        내용: \(detail.feedContent.prefix(50))
        좋아요: \(detail.likeCount) | 댓글: \(detail.commentCount)
        연결 소설: \(detail.connectedNovel?.basicInfo.title ?? "없음")
        """
    }
}
