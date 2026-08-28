//
//  CreateFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import SearchDomain

@MainActor
@Observable
final class CreateFeedViewModel {

    /// 작성/수정 모드. 수정이면 대상 피드의 `FeedID`를 들고 있다.
    public enum Mode {
        case create
        case edit(FeedID)
    }

    // MARK: - State

    public struct State {
        var draft: FeedDraft

        var attachedImageDatas: [AttachedImageID: Data] = [:]
        var submitState: SubmitState = .idle
        var validationError: FeedDraft.ValidationError?
        /// 수정 모드 진입 직후, 대상 피드의 내용을 불러오는 중 — 화면은 바로 뜨고(빠른 전환) 이 값이
        /// true인 동안만 내용이 비어 보인다. 이미지 없는 글은 거의 즉시 사라진다.
        var isLoadingForEdit: Bool = false

        // 토스트
        var showToast: Bool = false

        // 작품 연결 시트
        var connectedNovelSearchText: String = ""
        var searchedNovels: [Novel] = []
        var selectedSearchedNovelID: NovelID?
        var isSearchingNovel: Bool = false
        /// 현재 `connectedNovelSearchText`로 검색이 **실제로 완료**됐는지. 타이핑마다(`updateConnectedNovelSearchText`)
        /// 꺼지고, 검색이 응답을 받아야만 켜진다 — 검색 실행 전(타이핑 도중)이거나 결과를 받은 뒤 다시
        /// 타이핑하는 도중, 또는 x 버튼으로 텍스트를 비웠을 때 결과 영역이 흰 배경만 보이게 한다
        /// (`CollectionFeature.AddNovelViewModel`과 동일 패턴).
        var hasSearchedNovel: Bool = false
        var hasNextNovelPage: Bool = false
        var isLoadingMoreNovels: Bool = false
    }

    // MARK: - Derived

    public var canSubmit: Bool {
        !state.draft.content.isEmpty
        && !(state.submitState == .submitting)
        && hasChanges
    }

    /// 수정 모드 진입 시 불러온(또는 작성 모드의 빈) 초기 draft와 지금 draft가 다른지 — 수정 모드에서
    /// 아무것도 안 바꾼 채로는 "완료"가 활성화되면 안 된다(사용자 확정). 작성 모드는 `originalDraft`가
    /// 빈 draft라 내용을 입력하는 순간 자연히 true가 되므로 별도 분기가 필요 없다.
    private var hasChanges: Bool {
        state.draft != originalDraft
    }

    public var isSubmitting: Bool {
        state.submitState == .submitting
    }

    /// 수정 모드 여부. View의 상단 타이틀("피드 작성"/"피드 수정") 분기에 사용.
    public var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Action

    enum Action {
        /// 생명주기 액션 — 수정 모드면 대상 피드를 불러와 `draft`/`attachedImageDatas`를 채운다.
        /// 작성 모드에선 아무 일도 하지 않는다(빈 draft로 시작하는 게 정상).
        case load

        case updateContent(String)

        case toggleSpoiler
        case togglePrivate

        case setConnectedNovel(ConnectedNovel)
        case removeConnectedNovel
        case alreadyLinkedNovel

        case addImage(id: AttachedImageID, data: Data)
        case removeImage(AttachedImageID)

        case submitFeed

        case dismissToast

        // 작품 연결 시트
        case updateConnectedNovelSearchText(String)
        case searchNovel(String)
        case loadMoreSearchedNovels
        case selectSearchedNovel(NovelID)
        case confirmSelectedNovel
        case dismissLinkNovelSheet
    }

    // MARK: - Output

    public private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var searchNovelTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreNovelsTask: Task<Void, Never>?
    /// 다음에 요청할 페이지 번호(0부터) — 첫 검색 성공 시 1로, 다음 페이지 성공마다 +1
    /// (`SearchFeature.NormalSearchViewModel`/`CollectionFeature.AddNovelViewModel`과 동일 관례).
    @ObservationIgnored private var nextNovelSearchPage = 0

    // MARK: - Dependency

    private let mode: Mode
    private let createFeedUseCase: CreateFeedUseCase?
    private let editFeedUseCase: EditFeedUseCase?
    private let searchNovelUseCase: SearchNovelUseCase
    /// 수정 모드 진입 시 대상 피드 상세를 불러오는 용도(`.load`) — 작성 모드에선 쓰지 않는다.
    private let loadFeedDetailUseCase: LoadFeedDetailUseCase?

    /// 수정 모드 로드는 한 번만 — `.onAppear`가 재진입마다 불려도 재요청하지 않는다.
    private var hasLoadedForEdit = false

    /// "변경 없음" 판단 기준 — 작성 모드는 빈 draft로 고정, 수정 모드는 `loadForEdit` 완료 시 갱신된다
    /// (그 전까진 placeholder 빈 draft라 `state.draft`와 항상 같음 → 로드 중엔 자연히 `hasChanges == false`).
    private var originalDraft: FeedDraft

    // MARK: - Init

    public init(
        mode: Mode = .create,
        createFeedUseCase: CreateFeedUseCase? = nil,
        editFeedUseCase: EditFeedUseCase? = nil,
        searchNovelUseCase: SearchNovelUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase? = nil,
        initialDraft: FeedDraft
    ) {
        self.mode = mode
        self.createFeedUseCase = createFeedUseCase
        self.editFeedUseCase = editFeedUseCase
        self.searchNovelUseCase = searchNovelUseCase
        self.loadFeedDetailUseCase = loadFeedDetailUseCase
        self.originalDraft = initialDraft
        self.state = State(draft: initialDraft)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        var newState = state
        newState.validationError = nil
        defer {
            presentValidationError(&newState)
            state = newState
        }

        switch action {

        case .load:
            guard case .edit(let feedID) = mode, !hasLoadedForEdit, let loadFeedDetailUseCase else { break }
            hasLoadedForEdit = true
            newState.isLoadingForEdit = true
            Task { [weak self] in
                guard let self else { return }
                await loadForEdit(feedID: feedID, using: loadFeedDetailUseCase)
            }

        case .updateContent(let content):
            mutate(&newState) { try $0.updateContent(content) }

        case .toggleSpoiler:
            newState.draft.toggleSpoiler()

        case .togglePrivate:
            newState.draft.togglePrivate()

        case .setConnectedNovel(let novel):
            mutate(&newState) { try $0.setConnectedNovel(novel) }

        case .removeConnectedNovel:
            newState.draft.removeConnectedNovel()

        case .alreadyLinkedNovel:
            newState.validationError = .connectedNovelOverLimit

        case .addImage(let id, let data):
            mutate(&newState) { try $0.addImage(id) }
            if newState.draft.attachedImages.last == id {
                newState.attachedImageDatas[id] = data
            }

        case .removeImage(let id):
            newState.draft.removeImage(id)
            newState.attachedImageDatas[id] = nil

        case .submitFeed:
            Task { await submit() }

        case .dismissToast:
            newState.showToast = false

        case .updateConnectedNovelSearchText(let text):
            newState.connectedNovelSearchText = text
            newState.hasSearchedNovel = false

        case .searchNovel(let query):
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            searchNovelTask?.cancel()
            loadMoreNovelsTask?.cancel()
            loadMoreNovelsTask = nil
            newState.isLoadingMoreNovels = false
            newState.hasNextNovelPage = false
            if trimmed.isEmpty {
                newState.searchedNovels = []
                newState.hasSearchedNovel = false
            } else {
                searchNovelTask = Task { await fetchSearchedNovels(trimmed) }
            }

        case .loadMoreSearchedNovels:
            // 다음 페이지가 없거나 이미 검색/로딩 중이면 무시(무한스크롤 중복 요청 방지).
            guard state.hasSearchedNovel,
                  state.hasNextNovelPage,
                  searchNovelTask == nil,
                  loadMoreNovelsTask == nil else { break }
            newState.isLoadingMoreNovels = true
            let query = state.connectedNovelSearchText.trimmingCharacters(in: .whitespaces)
            loadMoreNovelsTask = Task { await fetchMoreSearchedNovels(query) }

        case .selectSearchedNovel(let id):
            newState.selectedSearchedNovelID = id

        case .confirmSelectedNovel:
            guard let id = newState.selectedSearchedNovelID,
                  let selected = newState.searchedNovels.first(where: { $0.id == id }) else { break }

            let connected = ConnectedNovel(
                id: selected.id,
                title: selected.title,
                genre: selected.genres.first,
                rating: selected.rating
            )
            mutate(&newState) { try $0.setConnectedNovel(connected) }
            searchNovelTask?.cancel()
            loadMoreNovelsTask?.cancel()
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""
            newState.hasSearchedNovel = false
            newState.hasNextNovelPage = false
            newState.isLoadingMoreNovels = false

        case .dismissLinkNovelSheet:
            searchNovelTask?.cancel()
            loadMoreNovelsTask?.cancel()
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""
            newState.hasSearchedNovel = false
            newState.hasNextNovelPage = false
            newState.isLoadingMoreNovels = false
        }
    }
}

// MARK: - UseCase Handling

private extension CreateFeedViewModel {

    func submit() async {
        let draft = state.draft

        guard canSubmit else { return }

        guard !draft.content.isEmpty else {
            state.validationError = .emptyContent
            presentValidationError(&state)
            return
        }

        state.submitState = .submitting

        let imageDatas = draft.attachedImages.compactMap { state.attachedImageDatas[$0] }

        do {
            switch mode {
            case .create:
                // UseCase 미주입은 Factory 조립 오류라 정상 경로에선 발생하지 않지만,
                // 여기서 조용히 return하면 submitState가 .submitting에 고착된다 — 실패로 귀결시킨다.
                guard let createFeedUseCase else {
                    state.submitState = .failed(.unknown)
                    return
                }
                try await createFeedUseCase.execute(draft, imageDatas: imageDatas)
            case .edit(let feedID):
                guard let editFeedUseCase else {
                    state.submitState = .failed(.unknown)
                    return
                }
                try await editFeedUseCase.execute(feedID: feedID, editedFeed: draft, imageDatas: imageDatas)
            }
            state.submitState = .submitted
        } catch let error {
            state.submitState = .failed(error)
        }
    }

    /// 수정 모드 진입 직후 대상 피드를 불러와 `draft`/`attachedImageDatas`를 채운다. 첨부 이미지는
    /// URL만 있어(서버가 바이트를 안 돌려줌) 여기서 URLSession으로 미리 받아둬야 한다 — 그대로 저장해도
    /// 서버 수정 API(PATCH, 전체 교체 방식)가 보낸 이미지만 반영해 기존 이미지가 사라지는 걸 막기
    /// 위함(사용자 확정, `FeedDomain/CLAUDE.md`의 `EditFeedUseCase` 항목 참고). `URLSession.shared`가
    /// URLCache를 공유해 직전 화면이 이미 표시 중이던 이미지면 재다운로드 없이 캐시에서 온다.
    func loadForEdit(feedID: FeedID, using loadFeedDetailUseCase: LoadFeedDetailUseCase) async {
        defer { state.isLoadingForEdit = false }

        guard let detail = try? await loadFeedDetailUseCase.execute(feedID: feedID) else { return }

        var draft = FeedDraft(
            content: detail.feedContent,
            isSpoiler: detail.isSpoiler,
            isPrivate: !detail.isPublic,
            connectedNovel: detail.connectedNovel?.basicInfo,
            attachedImages: []
        )

        var attachedImageDatas: [AttachedImageID: Data] = [:]
        for url in detail.feedImageURLs.compactMap({ $0 }) {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { continue }
            let id = AttachedImageID()
            attachedImageDatas[id] = data
            try? draft.addImage(id)
        }

        state.draft = draft
        state.attachedImageDatas = attachedImageDatas
        originalDraft = draft
    }

    func fetchSearchedNovels(_ query: String) async {
        state.isSearchingNovel = true
        // ⚠️ `searchNovelTask`를 여기서 반드시 nil로 되돌려야 한다 — 안 그러면 `loadMoreSearchedNovels`의
        // `searchNovelTask == nil` 가드가 첫 검색 이후 영원히 막힌다(`CollectionFeature.AddNovelViewModel`에서
        // 실제로 겪은 버그와 동일).
        defer {
            searchNovelTask = nil
            state.isSearchingNovel = false
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state.searchedNovels = []
            return
        }

        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(trimmed, page: 0)
            guard !Task.isCancelled else { return }
            state.searchedNovels = paginated.items
            state.hasSearchedNovel = true
            state.hasNextNovelPage = paginated.hasNext
            nextNovelSearchPage = 1
        } catch {
            guard !Task.isCancelled else { return }
            state.searchedNovels = []
            state.hasSearchedNovel = true
        }
    }

    func fetchMoreSearchedNovels(_ query: String) async {
        defer {
            loadMoreNovelsTask = nil
            state.isLoadingMoreNovels = false
        }

        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(query, page: nextNovelSearchPage)
            guard !Task.isCancelled else { return }
            state.searchedNovels.append(contentsOf: paginated.items)
            state.hasNextNovelPage = paginated.hasNext
            nextNovelSearchPage += 1
        } catch {
            // 다음 페이지 실패는 이미 보이는 결과를 건드리지 않고 조용히 무시한다(이 VM엔 로거가 없음).
        }
    }
}

// MARK: - Error Mapping

private extension CreateFeedViewModel {

    func mutate(
        _ state: inout State,
        _ change: (inout FeedDraft) throws -> Void
    ) {
        do {
            try change(&state.draft)
        } catch let error as FeedDraft.ValidationError {
            state.validationError = error
        } catch {
            assertionFailure(
                "FeedDraft API는 ValidationError만 던져야 함: \(error)"
            )
        }
    }

    /// `state.validationError` 중 토스트로 노출해야 하는 종류를 판단하는 단일 진입점.
    /// 어떤 `WSSToastType`으로 표현할지는 View가 결정한다.
    /// 매 액션 종료 시 호출된다.
    func presentValidationError(_ state: inout State) {
        guard let error = state.validationError else { return }
        switch error {
        case .contentOverLimit, .emptyContent:
            break
        case .imageOverLimit, .connectedNovelOverLimit:
            state.showToast = true
        }
    }
}
