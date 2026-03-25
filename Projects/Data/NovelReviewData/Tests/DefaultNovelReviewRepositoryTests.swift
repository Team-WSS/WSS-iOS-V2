//
//  DefaultNovelReviewRepositoryTests.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  DefaultNovelReviewRepositoryTests.swift
//  NovelReviewDataTests
//

import Foundation
import Testing
@testable import NovelReviewData
import NovelReviewDomain
import BaseDomain
import Networking
@testable import NovelReviewDataTesting

@Suite("DefaultNovelReviewRepository")
struct DefaultNovelReviewRepositoryTests {

    // MARK: - Helpers

    private let novelID = NovelID(1)

    private func makeKeywordResponse(
        id: Int = 1,
        name: String = "키워드"
    ) -> KeywordResponse {
        KeywordResponse(
            keywordId: id,
            keywordName: name
        )
    }

    private func makeResponse(
        status: String? = "WATCHING",
        startDate: String? = "2024-06-14",
        endDate: String? = "2024-06-20",
        userNovelRating: Float = 4.5,
        attractivePoints: [String] = ["worldview", "character"],
        keywords: [KeywordResponse] = [
            KeywordResponse(keywordId: 1, keywordName: "재밌는"),
            KeywordResponse(keywordId: 2, keywordName: "몰입감")
        ]
    ) -> NovelReviewResponse {
        NovelReviewResponse(
            novelTitle: "Test",
            status: status,
            startDate: startDate,
            endDate: endDate,
            userNovelRating: userNovelRating,
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }

    private func makeDraft() -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: novelID,
            status: .watching,
            period: try? ReadingPeriod(
                start: DateParser.date(from: "2024-06-14"),
                end: DateParser.date(from: "2024-06-20")
            ),
            rating: try? Rating(4.5),
            attractivePoints: [.worldview, .character],
            keywords: [
                Keyword(id: KeywordID(1), name: "재밌는"),
                Keyword(id: KeywordID(2), name: "몰입감")
            ]
        )
    }

    private func makeRepository(
        service: MockNovelReviewService,
        logger: MockNovelReviewLogger? = nil
    ) -> DefaultNovelReviewRepository {
        DefaultNovelReviewRepository(
            novelReviewService: service,
            logger: logger
        )
    }

    // MARK: - loadNovelReviewDraft

    @Test("리뷰 조회에 성공하면 NovelReviewDraft를 반환한다")
    func loadsNovelReviewDraftSuccessfully() async throws {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        service.getReviewResult = .success(makeResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.loadNovelReviewDraft(novelID: novelID)

        #expect(service.requestedNovelID == 1)
        #expect(result?.novelID == novelID)
        #expect(result?.status == .watching)
        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("리뷰 조회 시 mapper 실패가 발생하면 invalidData 에러를 던지고 mapping 로그를 남긴다")
    func throwsInvalidDataWhenMappingFailsOnLoad() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        service.getReviewResult = .success(
            makeResponse(status: "INVALID_STATUS")
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.invalidData) {
            _ = try await sut.loadNovelReviewDraft(novelID: novelID)
        }

        #expect(service.requestedNovelID == 1)
        #expect(logger.loggedErrors == [
            .init(type: .mapping, action: .load)
        ])
    }

    @Test("리뷰 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnLoad() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()

        service.getReviewResult = .failure(
            NetworkingError.responseFailure(code: 404, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await sut.loadNovelReviewDraft(novelID: novelID)
        }

        #expect(logger.loggedErrors == [
            .init(type: .network, action: .load)
        ])
    }

    @Test("리뷰 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenUnknownErrorOccursOnLoad() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()

        service.getReviewResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.loadNovelReviewDraft(novelID: novelID)
        }

        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .load)
        ])
    }

    // MARK: - save

    @Test("리뷰 저장 시 post에 성공하면 put을 호출하지 않는다")
    func savesReviewWithPostOnlyWhenPostSucceeds() async throws {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        service.postReviewResult = .success(())
        service.putReviewResult = .success(())

        let sut = makeRepository(service: service, logger: logger)

        try await sut.save(draft: draft)

        #expect(service.postedRequest != nil)
        #expect(service.putRequest == nil)
        #expect(service.putNovelID == nil)
        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("post 시 이미 리뷰가 존재하는 에러가 발생하면 put으로 fallback 한다")
    func fallsBackToPutWhenAlreadyReviewedErrorOccurs() async throws {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        let body = ErrorResponse(code: "USER_NOVEL-001", message: "이미 리뷰가 존재합니다.")
        service.postReviewResult = .failure(
            NetworkingError.responseFailure(code: 400, body: body)
        )
        service.putReviewResult = .success(())

        let sut = makeRepository(service: service, logger: logger)

        try await sut.save(draft: draft)

        #expect(service.postedRequest != nil)
        #expect(service.putNovelID == 1)
        #expect(service.putRequest != nil)
        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("post 시 일반 networking 에러가 발생하면 RepositoryError로 변환하고 post network 로그를 남긴다")
    func translatesNetworkingErrorWhenPostFailsWithoutFallback() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        service.postReviewResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.save(draft: draft)
        }

        #expect(service.postedRequest != nil)
        #expect(service.putRequest == nil)
        #expect(logger.loggedErrors == [
            .init(type: .network, action: .post)
        ])
    }

    @Test("post 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 post unknown 로그를 남긴다")
    func throwsUnknownWhenPostFailsWithUnknownError() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        service.postReviewResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.save(draft: draft)
        }

        #expect(service.postedRequest != nil)
        #expect(service.putRequest == nil)
        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .post)
        ])
    }

    @Test("put fallback 중 networking 에러가 발생하면 RepositoryError로 변환하고 put network 로그를 남긴다")
    func translatesNetworkingErrorWhenPutFallbackFails() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        let body = ErrorResponse(code: "USER_NOVEL-001", message: "이미 리뷰가 존재합니다.")
        service.postReviewResult = .failure(
            NetworkingError.responseFailure(code: 400, body: body)
        )
        service.putReviewResult = .failure(
            NetworkingError.responseFailure(code: 404, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.notFound) {
            try await sut.save(draft: draft)
        }

        #expect(service.postedRequest != nil)
        #expect(service.putRequest != nil)
        #expect(logger.loggedErrors == [
            .init(type: .network, action: .put)
        ])
    }

    @Test("put fallback 중 알 수 없는 에러가 발생하면 unknown 에러를 던지고 put unknown 로그를 남긴다")
    func throwsUnknownWhenPutFallbackFailsWithUnknownError() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()
        let draft = makeDraft()

        let body = ErrorResponse(code: "USER_NOVEL-001", message: "이미 리뷰가 존재합니다.")
        service.postReviewResult = .failure(
            NetworkingError.responseFailure(code: 400, body: body)
        )
        service.putReviewResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.save(draft: draft)
        }

        #expect(service.postedRequest != nil)
        #expect(service.putRequest != nil)
        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .put)
        ])
    }

    // MARK: - deleteNovelReview

    @Test("리뷰 삭제에 성공하면 service의 deleteReview를 호출한다")
    func deletesNovelReviewSuccessfully() async throws {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()

        service.deleteReviewResult = .success(())

        let sut = makeRepository(service: service, logger: logger)

        try await sut.deleteNovelReview(novelID: novelID)

        #expect(service.deletedNovelID == 1)
        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("리뷰 삭제 시 networking 에러가 발생하면 RepositoryError로 변환하고 delete network 로그를 남긴다")
    func translatesNetworkingErrorOnDelete() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()

        service.deleteReviewResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.deleteNovelReview(novelID: novelID)
        }

        #expect(service.deletedNovelID == 1)
        #expect(logger.loggedErrors == [
            .init(type: .network, action: .delete)
        ])
    }

    @Test("리뷰 삭제 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 delete unknown 로그를 남긴다")
    func throwsUnknownWhenDeleteFailsWithUnknownError() async {
        let service = MockNovelReviewService()
        let logger = MockNovelReviewLogger()

        service.deleteReviewResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.deleteNovelReview(novelID: novelID)
        }

        #expect(service.deletedNovelID == 1)
        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .delete)
        ])
    }
}
