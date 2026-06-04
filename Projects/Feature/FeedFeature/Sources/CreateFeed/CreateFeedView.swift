//
//  CreateFeedView.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import BaseDomain
import FeedDomain

public struct CreateFeedView: View {

    @State private var viewModel: CreateFeedViewModel

    public init(viewModel: CreateFeedViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                contentSection
                Divider()
                togglesSection
                Divider()
                connectedNovelSection
                Divider()
                imagesSection
                Divider()
                submitSection
                Divider()
                debugSection
            }
            .padding()
        }
        .navigationTitle("피드 작성")
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내용").font(.headline)
            TextField("내용을 입력하세요", text: contentBinding, axis: .vertical)
                .lineLimit(3...10)
                .textFieldStyle(.roundedBorder)
            HStack {
                Text("\(viewModel.contentCount)자")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("스포일러", isOn: spoilerBinding)
            Toggle("비공개", isOn: privateBinding)
        }
    }

    // MARK: - Connected Novel

    private var connectedNovelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연결 작품").font(.headline)
            if let novel = viewModel.state.draft.connectedNovel {
                HStack {
                    Text(novel.title)
                    Spacer()
                    Button("해제") {
                        Task { await viewModel.send(.removeConnectecNovel) }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button("샘플 작품 연결") {
                    Task { await viewModel.send(.setConnectedNovel(Self.sampleNovel)) }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Images

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("이미지 \(viewModel.state.draft.attachedImages.count)/5").font(.headline)
                Spacer()
                Button("샘플 이미지 추가") {
                    let url = URL(filePath: "/tmp/sample_\(UUID().uuidString).jpg")
                    Task { await viewModel.send(.addImage(url)) }
                }
                .buttonStyle(.bordered)
            }
            ForEach(viewModel.state.draft.attachedImages, id: \.self) { url in
                HStack {
                    Text(url.lastPathComponent).font(.caption).lineLimit(1)
                    Spacer()
                    Button("삭제") {
                        Task { await viewModel.send(.removeImage(url)) }
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Submit

    private var submitSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.send(.submitted(imageDatas: [])) }
            } label: {
                HStack {
                    if viewModel.isSubmitting { ProgressView() }
                    Text(viewModel.isSubmitting ? "제출 중..." : "제출")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit)
        }
    }

    // MARK: - Debug

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("디버그").font(.headline)
            label("canSubmit", "\(viewModel.canSubmit)")
            label("submitState", "\(viewModel.state.submitState)")
            label("validationError", "\(viewModel.state.validationError.map(String.init(describing:)) ?? "nil")")
        }
        .font(.system(.caption, design: .monospaced))
    }

    @ViewBuilder
    private func label(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key).foregroundStyle(.secondary)
            Text(value)
            Spacer()
        }
    }

    // MARK: - Bindings

    private var contentBinding: Binding<String> {
        Binding(
            get: { viewModel.state.draft.content },
            set: { value in Task { await viewModel.send(.contentChanged(value)) } }
        )
    }

    private var spoilerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.draft.isSpoiler },
            set: { _ in Task { await viewModel.send(.spoilerToggled) } }
        )
    }

    private var privateBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.draft.isPrivate },
            set: { _ in Task { await viewModel.send(.privateToggled) } }
        )
    }

    // MARK: - Samples

    private static let sampleNovel = ConnectedNovel(
        id: NovelID(1),
        title: "괴담에 떨어져도 출근을 해야 하는구나",
        genre: .modernFantasy,
        rating: 4.32
    )
}
