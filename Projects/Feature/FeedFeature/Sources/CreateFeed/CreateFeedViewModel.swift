//
//  CreateFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation

import BaseDomain
import FeedDomain

import WSSComponent

@Observable
@MainActor
public final class CreateFeedViewModel {

    // MARK: - State

    public struct State {
        var draft: FeedDraft
        var submitState: SubmitState = .idle
        var validationError: FeedDraft.ValidationError?
        
        var showImagePicker: Bool = false
        var showLinkNovelSheet: Bool = false
        var showToast: Bool = false
        var toastType: WSSToastType = .networkDelay
        var showAlert: Bool = false
    }

    public var canSubmit: Bool {
        !state.draft.content.isEmpty
        && !(state.submitState == .submitting)
    }
    
    public var canLinkNovel: Bool {
        state.draft.connectedNovel == nil
    }

    // MARK: - Action

    enum Action {
        case updateContent(String)

        case toggleSpoiler
        case togglePrivate

        case selectConnectedNovel
        case setConnectedNovel(ConnectedNovel)
        case removeConnectedNovel

        case selectImagePhotoPicker
        case addImage(URL)
        case removeImage(URL)

        case submitFeed
        case attemptDismiss
    }

    // MARK: - Properties

    public private(set) var state: State

    private let createFeedUseCase: CreateFeedUseCase

    // MARK: - Init

    public init(
        createFeedUseCase: CreateFeedUseCase,
        initialDraft: FeedDraft
    ) {
        self.createFeedUseCase = createFeedUseCase
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

        case .selectConnectedNovel:
            if (newState.draft.connectedNovel == nil) {
                newState.showLinkNovelSheet = true
            } else {
                newState.toastType = .novelAlreadyConnected
                newState.showToast = true
            }
            
        case .setConnectedNovel(let novel):
            mutate(&newState) { try $0.setConnectedNovel(novel) }

        case .removeConnectedNovel:
            newState.draft.removeConnectedNovel()
            
        case .selectImagePhotoPicker:
            guard newState.draft.attachedImages.count < FeedDraft.maxImageCount else { return }
            newState.showImagePicker = true

        case .addImage(let image):
            mutate(&newState) { try $0.addImage(image) }

        case .removeImage(let image):
            newState.draft.removeImage(image)

        case .submitFeed:
            Task { await submit() }
            
        case .attemptDismiss:
            newState.showAlert = true
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
}
