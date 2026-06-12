//
//  CreateFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation

import BaseDomain
import FeedDomain
import NovelDomain

import WSSComponent

@Observable
@MainActor
public final class CreateFeedViewModel {

    // MARK: - State

    public struct State {
        var draft: FeedDraft
        
        var attachedImageDatas: [AttachedImageID: Data] = [:]
        var submitState: SubmitState = .idle
        var validationError: FeedDraft.ValidationError?
        
        // 토스트
        var showToast: Bool = false
        var toastType: WSSToastType = .networkDelay

        // 작품 연결 시트
        var connectedNovelSearchText: String = ""
        var searchedNovels: [Novel] = []
        var selectedSearchedNovelID: NovelID?
        var isSearchingNovel: Bool = false
    }

    public var canSubmit: Bool {
        !state.draft.content.isEmpty
        && !(state.submitState == .submitting)
    }

    // MARK: - Action

    enum Action {
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
        case selectSearchedNovel(NovelID)
        case confirmSelectedNovel
        case dismissLinkNovelSheet
    }

    // MARK: - Properties

    public private(set) var state: State

    private let createFeedUseCase: CreateFeedUseCase
    private let searchNovelUseCase: SearchNovelUseCase

    // MARK: - Init

    public init(
        createFeedUseCase: CreateFeedUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        initialDraft: FeedDraft
    ) {
        self.createFeedUseCase = createFeedUseCase
        self.searchNovelUseCase = searchNovelUseCase
        self.state = State(draft: initialDraft)
    }

    // MARK: - Action

    func handle(_ action: Action) {
        var newState = state
        newState.validationError = nil
        defer {
            presentValidationError(&newState)
            state = newState
        }

        switch action {

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
            
        case .searchNovel(let query):
            Task { await searchNovel(query) }
            
        case .selectSearchedNovel(let id):
            newState.selectedSearchedNovelID = id
            
        case .confirmSelectedNovel:
            guard let id = newState.selectedSearchedNovelID,
                  let selected = newState.searchedNovels.first(where: { $0.id == id }) else { break }

            let connected = ConnectedNovel(
                id: selected.id,
                title: selected.title,
                genre: .fantasy,
                rating: selected.rating
            )
            mutate(&newState) { try $0.setConnectedNovel(connected) }
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""
            
        case .dismissLinkNovelSheet:
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""
        }
    }

    //MARK: - Custom Method

    private func mutate(
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

    /// `state.validationError`를 화면 피드백으로 매핑하는 단일 진입점.
    /// 매 액션 종료 시 호출된다.
    private func presentValidationError(_ state: inout State) {
        guard let error = state.validationError else { return }
        switch error {
        case .contentOverLimit:
            break
        case .imageOverLimit(let max):
            state.toastType = .limitAddImage(limitCount: max)
            state.showToast = true
        case .connectedNovelOverLimit:
            state.toastType = .novelAlreadyConnected
            state.showToast = true
        case .emptyContent:
            break
        }
    }
    
    private func submit() async {
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
            try await createFeedUseCase.execute(draft, imageDatas: imageDatas)
            state.submitState = .submitted
        } catch let error {
            state.submitState = .failed(error)
        }
    }
    
    private func searchNovel(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state.searchedNovels = []
            return
        }

        state.isSearchingNovel = true
        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(trimmed)
            state.searchedNovels = paginated.items
        } catch {
            state.searchedNovels = []
        }
        state.isSearchingNovel = false
    }
}
