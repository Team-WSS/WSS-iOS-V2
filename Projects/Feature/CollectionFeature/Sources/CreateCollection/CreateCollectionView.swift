//
//  CreateCollectionView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import SearchDomain
import DesignSystem
import WSSComponent

// 컬렉션 생성 화면. "얇은 ViewModel" 원칙: 카피·포맷·색 등 표기는 전부 View가 결정한다.
// 화면 동작 계약(뒤로가기·대표 배지·완료 활성화 등)은 CollectionFeature/CLAUDE.md 참고.
struct CreateCollectionView: View {

    @State private var viewModel: CreateCollectionViewModel
    /// 글자수 clamp 트랩(로컬 버퍼 → 확정값 반영 2단계, `Feature/CLAUDE.md` 참고) 전용 필드 버퍼.
    /// VM 상태에 TextField를 직접 물리지 않는다.
    @State private var nameFieldText: String
    @State private var descriptionFieldText: String
    /// "작품 추가" 화면 push 여부 — `ReadingPeriodSheet`류 로컬 값 선택기와 같은 위상이라(다만 sheet가
    /// 아니라 push) 이 화면이 직접 소유한다. App/Factory는 몰라도 된다.
    @State private var isAddNovelPresented = false
    /// 이름·설명 필드는 각자 독립된 `@FocusState`를 쓴다 — 하나로 공유하면 빈 곳 탭으로 둘 다 내릴 때
    /// 어느 필드가 포커스인지 구분이 안 된다(`UserPageFeature`의 `MyPageEditView` 동일 패턴).
    @FocusState private var isNameFieldFocused: Bool
    /// "컬렉션 설명" 박스는 padding·배경까지 포함한 전체 영역이 탭 타깃이다(아래 `descriptionSection`).
    @FocusState private var isDescriptionFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// "작품 추가" 화면이 검색에 쓸 UseCase — `FeedFeature`의 연결 작품 검색과 같은 이유로 이 모듈이
    /// `SearchDomain`을 안다.
    private let searchNovelUseCase: SearchNovelUseCase
    /// 인증 만료 시 로그인 화면 진입 콜백. 화면 전환은 호출자(App)가 수행. "작품 추가" 화면도 같은
    /// 콜백을 공유한다(둘 다 결국 이 화면의 하위 화면).
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: CreateCollectionViewModel,
        searchNovelUseCase: SearchNovelUseCase,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self._nameFieldText = State(initialValue: viewModel.state.draft.name)
        self._descriptionFieldText = State(initialValue: viewModel.state.draft.description)
        self.searchNovelUseCase = searchNovelUseCase
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            // 알럿 버튼은 자동으로 닫히지 않으므로(버튼 액션만 호출), 각 액션이 직접 isPresented를 내린다.
            .showWSSAlert(
                isPresented: stopAlertBinding,
                type: .stopWritingCollection,
                buttonActions: [
                    { viewModel.handle(.confirmStop) },  // "그만하기" → 화면 닫기
                    { viewModel.handle(.keepWriting) }   // "계속 작성" → 머무름
                ]
            )
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                guard shouldDismiss else { return }
                dismiss()
            }
            // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
            .navigationDestination(isPresented: $isAddNovelPresented) {
                AddNovelView(
                    viewModel: AddNovelViewModel(
                        initialSelection: viewModel.state.draft.novelIDs.compactMap { viewModel.state.novelDisplayInfo[$0] },
                        searchNovelUseCase: searchNovelUseCase
                    ),
                    onConfirm: { novels in viewModel.handle(.setNovels(novels)) },
                    onAuthenticationRequired: onAuthenticationRequired
                )
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                privateSection

                Spacer().frame(height: 20)

                VStack(spacing: 0) {
                    nameSection

                    Spacer().frame(height: 30)

                    descriptionSection

                    Spacer().frame(height: 30)

                    novelListSection
                }
                .padding(.horizontal, 16)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        // 필드 자체(nameSection·descriptionSection)의 onTapGesture가 각자 포커스를 켜고, 그 바깥
        // 빈 공간을 탭하면 여기로 흘러와 둘 다 내린다 — 안쪽 제스처가 먼저 소비하므로 서로 충돌하지
        // 않는다(`FeedFeature`의 `CreateFeedView` 동일 패턴).
        .contentShape(Rectangle())
        .onTapGesture {
            isNameFieldFocused = false
            isDescriptionFieldFocused = false
        }
    }
}

// MARK: - Toolbar

private extension CreateCollectionView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.handle(.requestClose)
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssBlack)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                viewModel.handle(.submit)
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(viewModel.canSubmit ? Color.wssPrimary100 : Color.wssGray100)
                }
            }
            .disabled(!viewModel.canSubmit)
        }
    }
}

// MARK: - Sections

private enum Metric {
    /// 작품 그리드 제목 영역의 고정 높이(`.body4` 2줄 기준) — `WSSFontViewModifier`의 line-spacing/padding
    /// 보정 덕에 텍스트 블록 총 높이는 항상 "줄 수 × (fontSize × lineHeight)"와 같다: 2 × (13 × 1.45) = 37.7
    /// → 반올림 38. `novelGridCell`/`addNovelTile` 둘 다 이 상수로 제목 줄 수와 무관하게 높이를 맞춘다
    /// (`WSSNovelGridCell`의 `Metric.infoHeight`와 같은 패턴, `WSSComponent/CLAUDE.md` 참고).
    static let novelTitleHeight: CGFloat = 38
}

private extension CreateCollectionView {

    var privateSection: some View {
        WSSPrivateToggleRow(
            label: "나만 보는 컬렉션",
            isOn: Binding(
                get: { viewModel.state.draft.isPrivate },
                set: { _ in viewModel.handle(.togglePrivate) }
            )
        )
    }

    var nameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("컬렉션 이름")
                    .foregroundStyle(Color.wssBlack)
                Text(" *")
                    .foregroundStyle(Color.wssPrimary100)
            }
            .applyWSSFont(.title2)

            Spacer().frame(height: 10)

            HStack(spacing: 0) {
                TextField("컬렉션 이름을 입력해주세요", text: $nameFieldText)
                    .applyWSSFont(.body2)
                    .focused($isNameFieldFocused)

                Text("(\(nameFieldText.count)/\(CollectionDraft.maxNameCount))")
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray200)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: nameFieldText) { _, newValue in
            let clamped = String(newValue.prefix(CollectionDraft.maxNameCount))
            if clamped != newValue {
                nameFieldText = clamped
                return
            }
            viewModel.handle(.updateName(clamped))
        }
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("컬렉션 설명")
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 10)

            ZStack(alignment: .topLeading) {
                if descriptionFieldText.isEmpty {
                    Text("컬렉션에 관련한 설명을 간단하게 작성해주세요")
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssGray100)
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                TextField("", text: $descriptionFieldText, axis: .vertical)
                    .applyWSSFont(.body2)
                    .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
                    .focused($isDescriptionFieldFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            // 박스 안 빈 여백(padding·아래쪽 남는 공간)을 눌러도 포커스되도록 블록 전체를 탭 타깃으로 넓힌다
            // — 안 그러면 TextField 자신의 프레임 밖은 탭이 안 먹는다(Feature/CLAUDE.md 공통 주의).
            .contentShape(Rectangle())
            .onTapGesture { isDescriptionFieldFocused = true }
            .overlay(alignment: .bottomTrailing) {
                Text("(\(descriptionFieldText.count)/\(CollectionDraft.maxDescriptionCount))")
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray200)
                    .padding(.trailing, 16)
                    .padding(.bottom, 18)
            }
        }
        .onChange(of: descriptionFieldText) { _, newValue in
            let clamped = String(newValue.prefix(CollectionDraft.maxDescriptionCount))
            if clamped != newValue {
                descriptionFieldText = clamped
                return
            }
            viewModel.handle(.updateDescription(clamped))
        }
    }

    var novelListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                HStack(spacing: 0) {
                    Text("작품 리스트")
                        .foregroundStyle(Color.wssBlack)
                    Text(" *")
                        .foregroundStyle(Color.wssPrimary100)
                }
                .applyWSSFont(.title2)

                Text("(\(viewModel.state.draft.novelIDs.count)/\(CollectionDraft.maxNovelCount))")
                    .applyWSSFont(.body3)
                    .foregroundStyle(Color.wssGray200)
            }

            Spacer().frame(height: 12)

            novelGrid
        }
    }

    var novelGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 12
        ) {
            addNovelTile

            ForEach(viewModel.state.draft.novelIDs, id: \.self) { novelID in
                if let novel = viewModel.state.novelDisplayInfo[novelID] {
                    novelGridCell(novel)
                }
            }
        }
    }

    /// 다른 작품 셀(`novelGridCell`)과 같은 골격(커버 박스 + 제목 줄 자리)을 맞춘다 — 이 타일만 제목이
    /// 없다고 커버 높이를 고정값(156)으로 박아두면, 제목이 있는 이웃 셀과 총 높이가 달라져 그리드 행이
    /// 어긋나 보인다(#199 리뷰 피드백). 커버는 `novelGridCell`과 동일하게 `aspectRatio`로 폭에 맞춰
    /// 늘어나게 하고, 제목 자리는 `Metric.novelTitleHeight`만큼 고정 높이로 예약한다.
    var addNovelTile: some View {
        Button {
            isAddNovelPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // ⚠️ `.aspectRatio`를 VStack에 직접 걸면 VStack이 제 내용물(텍스트+아이콘, ~41pt)의
                // 자연 크기로 쪼그라든다 — 그 결과로 채워지지 않는다(실측: 그리드 칸을 안 채우고
                // 왼쪽 위에 작게 뜸). `WSSNovelCoverImage`가 쓰는 것과 같은 방식으로 `Color.clear`가
                // 비율만 잡고 실제 콘텐츠는 `.overlay`로 그 위에 얹어야 박스 전체가 채워진다
                // (`WSSComponent/CLAUDE.md`의 표지 비율 항목 참고).
                Color.clear
                    .aspectRatio(novelCoverAspectRatio, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 4) {
                            Text(viewModel.state.draft.novelIDs.isEmpty ? "작품 추가" : "작품 수정")
                                .applyWSSFont(.title4)
                                .foregroundStyle(Color.wssGray200)

                            WSSImage.icBookRegister.swiftUIImage
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.wssGray200)
                        }
                    }
                    .background(Color.wssGray50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // novelGridCell 제목 영역과 같은 고정 높이만 예약 — 제목이 없는 타일이라 폰트를 맞출 필요는 없다.
                Spacer()
                    .frame(height: Metric.novelTitleHeight)
            }
        }
        // ⚠️ .buttonStyle(.plain)을 걸지 않는다 — 아이콘·텍스트만 있는 버튼에 걸면 기본 눌림 피드백까지
        // 사라진다(WSSComponent/CLAUDE.md·Feature/CLAUDE.md 공통 주의). 색은 이미 명시적이라 accent 틴트
        // 우려도 없다.
    }

    /// 커버 셀 전체가 대표 지정 탭 영역이다(사용자 확정, #199 — 처음엔 우상단 배지만 탭 대상이었으나
    /// 셀 자체를 탭해도 바뀌도록 넓힘). 배지는 이제 순수 표시용이라 별도 `Button`으로 중첩하지 않는다
    /// (중첩 Button은 안쪽 제스처가 불안정해진다 — `WSSComponent/CLAUDE.md` 공통 주의).
    func novelGridCell(_ novel: CollectionNovel) -> some View {
        let isRepresentative = novel.id == viewModel.representativeNovelID

        return VStack(alignment: .leading, spacing: 6) {
            Button {
                viewModel.handle(.selectRepresentativeNovel(novel.id))
            } label: {
                ZStack(alignment: .topTrailing) {
                    WSSNovelCoverImage(url: novel.thumbnailImage, aspectRatio: novelCoverAspectRatio)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            if isRepresentative {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.wssPrimary100, lineWidth: 2)
                            }
                        }
                        .animation(.easeInOut(duration: 0.1), value: isRepresentative)

                    Text(isRepresentative ? "✓ 대표" : "대표")
                        .applyWSSFont(.label2)
                        .foregroundStyle(Color.wssWhite)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(isRepresentative ? Color.wssPrimary100 : Color.wssGray100)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        // 미설정 시 기본 크로스페이드가 느리게 번진다(Feature/CLAUDE.md 공통 주의).
                        .animation(.easeInOut(duration: 0.1), value: isRepresentative)
                        .padding(8)
                }
            }
            .buttonStyle(.plain)

            Text(novel.title)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(2)
                .frame(height: Metric.novelTitleHeight, alignment: .top)
        }
    }

    /// 그리드 커버 비율(Figma 108×156) — `addNovelTile`/`novelGridCell` 양쪽이 공유해야 두 셀의
    /// 커버 높이가 폭 변화(기기별)에도 항상 같이 움직인다.
    var novelCoverAspectRatio: CGFloat { 108.0 / 156.0 }
}

// MARK: - Presentation

private extension CreateCollectionView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// 작성 중단 알럿 표시 여부. 실제 닫기 판단은 ViewModel이 하고, View는 표시 상태만 바인딩한다.
    var stopAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isStopAlertPresented },
            set: { if !$0 { viewModel.handle(.keepWriting) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .unknown, .none:
            .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateCollectionView(
            viewModel: CreateCollectionViewModel(
                createCollectionUseCase: PreviewCreateCollectionUseCase()
            ),
            searchNovelUseCase: PreviewSearchNovelUseCase(),
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

#Preview("작품 포함") {
    // 제목 길이를 일부러 섞는다(1줄로 끝나는 제목 + 2줄까지 차는 제목) — 그리드 셀 높이가 제목 줄
    // 수와 무관하게 맞는지(Metric.novelTitleHeight) 이 프리뷰만으로 육안 확인할 수 있어야 한다.
    let titles = ["짧은 제목", "샘플 작품 제목 두 줄까지 길게 늘어지는 경우", "또 다른 짧은 제목",
                  "이것도 두 줄로 넘어갈 만큼 충분히 긴 작품 제목입니다", "제목"]
    let novels = titles.enumerated().map { index, title in
        CollectionNovel(id: NovelID(index + 1), title: title, author: "작가 \(index + 1)", thumbnailImage: nil)
    }
    let draft = CollectionDraft(
        name: "인생 회귀물 모음집",
        description: "다시 읽어도 재밌는 회귀물만 모았어요",
        novelIDs: novels.map(\.id)
    )
    return NavigationStack {
        CreateCollectionView(
            viewModel: CreateCollectionViewModel(
                previewDraft: draft,
                previewNovelDisplayInfo: Dictionary(uniqueKeysWithValues: novels.map { ($0.id, $0) }),
                createCollectionUseCase: PreviewCreateCollectionUseCase()
            ),
            searchNovelUseCase: PreviewSearchNovelUseCase(),
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
}

private struct PreviewCreateCollectionUseCase: CreateCollectionUseCase {
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        print("생성됨!")
        return CollectionID(1)
    }
}
