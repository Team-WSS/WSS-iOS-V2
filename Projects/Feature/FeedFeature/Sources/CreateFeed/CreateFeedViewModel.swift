//
//  CreateFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation

import BaseDomain
import FeedDomain

@Observable
@MainActor
public final class CreateFeedViewModel {

    // MARK: - State

    public struct State {
        public var draft: FeedDraft
        public var submitState: SubmitState = .idle
        public var validationError: FeedDraft.ValidationError?
    }

    public enum SubmitState: Equatable {
        case idle
        case submitting
        case submitted
        case failed(RepositoryError)
    }

    // MARK: - Action

    public enum Action {
        case contentChanged(String)
        case spoilerToggled
        case privateToggled
        case setConnectedNovel(ConnectedNovel)
        case removeConnectecNovel
        case addImage(URL)
        case removeImage(URL)
        case submitted(imageDatas: [Data])
    }

    // MARK: - Properties

    public private(set) var state: State
    private let createFeedUseCase: CreateFeedUseCase

    // MARK: - Derived

    public var contentCount: Int { state.draft.content.count }
    public var isSubmitting: Bool { state.submitState == .submitting }
    public var canSubmit: Bool {
        !state.draft.content.isEmpty
        && !isSubmitting
    }

    // MARK: - Init

    public init(
        createFeedUseCase: CreateFeedUseCase,
        initialDraft: FeedDraft
    ) {
        self.createFeedUseCase = createFeedUseCase
        self.state = State(draft: initialDraft)
    }

    // MARK: - Send

    public func send(_ action: Action) async {
        state.validationError = nil

        switch action {
        case .contentChanged(let value):
            mutate { try $0.updateContent(value) }

        case .spoilerToggled:
            state.draft.toggleSpoiler()

        case .privateToggled:
            state.draft.togglePrivate()

        case .setConnectedNovel(let novel):
            mutate { try $0.setConnectedNovel(novel) }

        case .removeConnectecNovel:
            state.draft.removeConnectedNovel()

        case .addImage(let image):
            mutate { try $0.addImage(image) }

        case .removeImage(let image):
            state.draft.removeImage(image)

        case .submitted(let imageDatas):
            await submit(imageDatas: imageDatas)
        }
    }

    // MARK: - Private

    /// `FeedDraft`의 throwing mutating 메서드를 안전하게 실행하고 ValidationError를 state에 기록한다.
    private func mutate(_ change: (inout FeedDraft) throws -> Void) {
        do {
            try change(&state.draft)
        } catch let error as FeedDraft.ValidationError {
            state.validationError = error
        } catch {
            assertionFailure("FeedDraft API는 ValidationError만 던져야 함: \(error)")
        }
    }

    private func submit(imageDatas: [Data]) async {
        guard !state.draft.content.isEmpty else {
            state.validationError = .emptyContent
            return
        }
        
        state.submitState = .submitting
        
        do {
            try await createFeedUseCase.execute(state.draft, imageDatas: imageDatas)
            state.submitState = .submitted
        } catch {
            state.submitState = .failed(error)
        }
    }
}
