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
        var submitState: SubmitState = .idle
        var validationError: FeedDraft.ValidationError?
        var showToast: Bool = false
        var toastType: WSSToastType = .networkDelay
        var showAlert: Bool = false

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
        
        case addImage(URL)
        case removeImage(URL)

        case submitFeed
        case attemptDismiss

        case updateConnectedNovelSearchText(String)
        case searchNovel(String)
        case selectSearchedNovel(NovelID)
        case confirmSelectedNovel
        case clearNovelSearch

        case dismissToast
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

     func handleAction(_ action: Action) {
        var newState = state
        defer { state = newState }

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
            newState.toastType = .novelAlreadyConnected
            newState.showToast = true
            
        case .addImage(let image):
            mutate(&newState) { try $0.addImage(image) }
            if case .imageOverLimit(let max) = newState.validationError {
                newState.toastType = .limitAddImage(limitCount: max)
                newState.showToast = true
            }

        case .removeImage(let image):
            newState.draft.removeImage(image)

        case .submitFeed:
            Task { await submit() }
            
        case .attemptDismiss:
            newState.showAlert = true
            
        case .updateConnectedNovelSearchText(let text):
            newState.connectedNovelSearchText = text

        case .searchNovel(let query):
            Task { await searchNovel(query) }

        case .selectSearchedNovel(let id):
            newState.selectedSearchedNovelID = id

        case .confirmSelectedNovel:
            guard let id = newState.selectedSearchedNovelID,
                  let picked = newState.searchedNovels.first(where: { $0.id == id }) else { break }
            // TODO: 검색 API에 장르 포함되면 picked 기준으로 교체
            let connected = ConnectedNovel(
                id: picked.id,
                title: picked.title,
                genre: .fantasy,
                rating: picked.rating
            )
            mutate(&newState) { try $0.setConnectedNovel(connected) }
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""

        case .clearNovelSearch:
            newState.selectedSearchedNovelID = nil
            newState.searchedNovels = []
            newState.connectedNovelSearchText = ""

        case .dismissToast:
            newState.showToast = false
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
    
    private func submit() async {
        let draft = state.draft

        guard !draft.content.isEmpty else {
            state.validationError = .emptyContent
            return
        }

        state.submitState = .submitting

        do {
            try await createFeedUseCase.execute(draft, imageDatas: [])
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
