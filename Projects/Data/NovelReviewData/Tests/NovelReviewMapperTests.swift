//
//  NovelReviewMapperTests.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Testing
@testable import NovelReviewData
import NovelReviewDomain
import BaseDomain
import BaseData

@Suite("NovelReviewMapper")
struct NovelReviewMapperTests {
    
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
    
    private func makeDraft(
        novelID: NovelID = NovelID(1),
        status: ReadingStatus = .watching,
        period: ReadingPeriod? = try? ReadingPeriod(
            start: DateParser.date(from: "2024-06-14"),
            end: DateParser.date(from: "2024-06-20")
        ),
        rating: Rating? = try? Rating(4.5),
        attractivePoints: [AttractivePoint] = [.worldview, .character],
        keywords: [Keyword] = [
            Keyword(id: KeywordID(1), name: "재밌는"),
            Keyword(id: KeywordID(2), name: "몰입감")
        ]
    ) -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: novelID,
            status: status,
            period: period,
            rating: rating,
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }
    
    // MARK: - Small conversions
    
    // MARK: - ReadStatus
    
    @Test("status를 ReadStatus로 적절히 변환한다")
    func mapsStatusCorrectly() throws {
        let cases: [(input: String, expected: ReadingStatus)] = [
            ("WATCHING", .watching),
            ("WATCHED", .watched),
            ("QUIT", .quit)
        ]
        
        for (input, expected) in cases {
            let response = makeResponse(
                status: input,
                startDate: nil,
                endDate: nil,
                userNovelRating: 0,
                attractivePoints: [],
                keywords: []
            )
            
            let draft = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
            
            #expect(draft?.status == expected)
        }
    }
    
    @Test("status가 nil이면 리뷰가 없는 것으로 간주하여 Draft를 nil로 반환한다")
    func returnsNilWhenStatusIsNil() throws {
        let response = makeResponse(
            status: nil,
            startDate: nil,
            endDate: nil,
            userNovelRating: 0,
            attractivePoints: [],
            keywords: []
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft == nil)
    }
    
    @Test("status 문자열이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenStatusIsInvalid() async {
        let response = makeResponse(
            status: "INVALID",
            startDate: nil,
            endDate: nil,
            userNovelRating: 0,
            attractivePoints: [],
            keywords: []
        )
        
        await #expect(throws: MappingError.invalidConversion(type: "ReadingStatus", value: "INVALID")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    // MARK: - Rating
    
    @Test("rating이 0이면 nil로 변환된다")
    func mapsZeroRatingToNil() throws {
        let response = makeResponse(
            userNovelRating: 0
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft?.rating == nil)
    }
    
    @Test("rating이 0이 아니면 Rating으로 변환된다")
    func mapsRatingToDomainRating() throws {
        let response = makeResponse(
            userNovelRating: 3.5
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft?.rating?.value == 3.5)
    }
    
    @Test("rating이 범위를 벗어나면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenRatingIsOutOfRange() async {
        let response = makeResponse(
            userNovelRating: 5.5
        )

        await #expect(throws: MappingError.invalidConversion(type: "Rating", value: "5.5")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }

    @Test("rating이 0.5 단위가 아니면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenRatingStepIsInvalid() async {
        let response = makeResponse(
            userNovelRating: 3.7
        )

        await #expect(throws: MappingError.invalidConversion(type: "Rating", value: "3.700000047683716")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    // MARK: - ReadingPeriod
    
    @Test("시작일과 종료일이 모두 nil이면 period는 nil이다")
    func mapsNilDatesToNilPeriod() throws {
        let response = makeResponse(
            startDate: nil,
            endDate: nil
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft?.period == nil)
    }
    
    @Test("시작일이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenStartDateIsInvalid() async {
        let response = makeResponse(
            startDate: "2024-99-99",
            endDate: nil
        )
        
        await #expect(throws: MappingError.invalidConversion(type: "StartDate", value: "2024-99-99")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    @Test("종료일이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenEndDateIsInvalid() async {
        let response = makeResponse(
            startDate: nil,
            endDate: "2024-99-99"
        )
        
        await #expect(throws: MappingError.invalidConversion(type: "EndDate", value: "2024-99-99")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    // MARK: - AttractivePoint
    
    @Test("attractivePoint 문자열이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenAttractivePointIsInvalid() async {
        let response = makeResponse(
            attractivePoints: ["invalid-point"]
        )
        
        await #expect(throws: MappingError.invalidConversion(type: "AttractivePoint", value: "invalid-point")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    @Test("attractivePoint 문자열들을 AttractivePoint 배열로 변환한다")
    func mapsAttractivePoints() throws {
        let cases: [(input: [String], expected: [AttractivePoint])] = [
            (["worldview", "material", "character"], [.worldview, .material, .character]),
            (["relationship", "vibe", "writingskill"], [.relationship, .vibe, .writingSkill])
        ]
        
        for (input, expected) in cases {
            let response = makeResponse(
                attractivePoints: input
            )
            
            let draft = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
            
            #expect(draft?.attractivePoints == expected)
        }
    }
    
    @Test("중복된 attractivePoint가 있으면 invalidPayload 에러를 던진다")
    func throwsInvalidPayloadWhenAttractivePointsAreDuplicated() async {
        let response = makeResponse(
            attractivePoints: ["worldview", "worldview"]
        )
        
        #expect(throws: MappingError.invalidPayload(reason: "duplicated attractivePoints")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    @Test("attractivePoint 개수가 최대 개수를 초과하면 invalidPayload 에러를 던진다")
    func throwsInvalidPayloadWhenTooManyAttractivePoints() async {
        let response = makeResponse(
            attractivePoints: ["worldview", "material", "character", "vibe"]
        )
        
        #expect(throws: MappingError.invalidPayload(reason: "too many attractivePoints")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    // MARK: - Keyword
    
    @Test("keyword 응답을 Keyword 배열로 변환한다")
    func mapsKeywords() throws {
        let response = makeResponse(
            keywords: [
                makeKeywordResponse(id: 10, name: "감성적인"),
                makeKeywordResponse(id: 20, name: "몰입감")
            ]
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft?.keywords == [
            Keyword(id: KeywordID(10), name: "감성적인"),
            Keyword(id: KeywordID(20), name: "몰입감")
        ])
    }

    @Test("중복된 keyword가 있으면 invalidPayload 에러를 던진다")
    func throwsInvalidPayloadWhenKeywordsAreDuplicated() async {
        let duplicated = makeKeywordResponse(id: 1, name: "중복")
        let response = makeResponse(
            keywords: [duplicated, duplicated]
        )
        
        #expect(throws: MappingError.invalidPayload(reason: "duplicated keywords")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    @Test("keyword 개수가 최대 개수를 초과하면 invalidPayload 에러를 던진다")
    func throwsInvalidPayloadWhenTooManyKeywords() async {
        let keywords = (1...21).map {
            makeKeywordResponse(id: $0, name: "키워드\($0)")
        }
        let response = makeResponse(keywords: keywords)
        
        #expect(throws: MappingError.invalidPayload(reason: "too many keywords")) {
            _ = try NovelReviewMapper.novelReviewDraft(
                from: response,
                novelID: novelID
            )
        }
    }
    
    // MARK: - Large conversions
    
    @Test("정상 응답을 NovelReviewDraft로 변환한다")
    func mapsResponseToNovelReviewDraft() throws {
        let response = makeResponse(
            status: "WATCHED",
            startDate: "2024-06-14",
            endDate: "2024-06-20",
            userNovelRating: 4.0,
            attractivePoints: ["worldview", "vibe"],
            keywords: [
                makeKeywordResponse(id: 1, name: "재밌는"),
                makeKeywordResponse(id: 2, name: "감성적인")
            ]
        )
        
        let draft = try NovelReviewMapper.novelReviewDraft(
            from: response,
            novelID: novelID
        )
        
        #expect(draft?.novelID == novelID)
        #expect(draft?.status == .watched)
        #expect(draft?.rating?.value == 4.0)
        #expect(draft?.attractivePoints == [.worldview, .vibe])
        #expect(draft?.keywords == [
            Keyword(id: KeywordID(1), name: "재밌는"),
            Keyword(id: KeywordID(2), name: "감성적인")
        ])
        #expect(draft?.period != nil)
    }
    
    @Test("NovelReviewDraft를 PostNovelReviewRequest로 변환한다")
    func mapsDraftToPostNovelReviewRequest() throws {
        let draft = makeDraft(
            status: .watching,
            rating: try Rating(4.5),
            attractivePoints: [.worldview, .writingSkill],
            keywords: [
                Keyword(id: KeywordID(1), name: "재밌는"),
                Keyword(id: KeywordID(2), name: "몰입감")
            ]
        )
        
        let request = NovelReviewMapper.postNovelReviewRequest(from: draft)
        
        #expect(request.novelId == 1)
        #expect(request.userNovelRating == 4.5)
        #expect(request.status == "WATCHING")
        #expect(request.startDate == "2024-06-14")
        #expect(request.endDate == nil)
        #expect(request.attractivePoints == ["worldview", "writingskill"])
        #expect(request.keywordIds == [1, 2])
    }
    
    @Test("NovelReviewDraft를 PutNovelReviewRequest로 변환한다")
    func mapsDraftToPutNovelReviewRequest() throws {
        let draft = makeDraft(
            status: .quit,
            rating: try Rating(3.0),
            attractivePoints: [.material, .relationship],
            keywords: [
                Keyword(id: KeywordID(11), name: "어두운"),
                Keyword(id: KeywordID(22), name: "긴장감")
            ]
        )
        
        let request = NovelReviewMapper.putNovelReviewRequest(from: draft)
        
        #expect(request.userNovelRating == 3.0)
        #expect(request.status == "QUIT")
        #expect(request.startDate == nil)
        #expect(request.endDate == "2024-06-20")
        #expect(request.attractivePoints == ["material", "relationship"])
        #expect(request.keywordIds == [11, 22])
    }
    
    @Test("rating이 nil인 draft는 요청으로 변환할 때 0으로 매핑된다")
    func mapsNilRatingToZeroInRequest() {
        let draft = makeDraft(
            rating: nil
        )
        
        let postRequest = NovelReviewMapper.postNovelReviewRequest(from: draft)
        let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)
        
        #expect(postRequest.userNovelRating == 0.0)
        #expect(putRequest.userNovelRating == 0.0)
    }
    
    @Test("이미 리뷰가 존재하는 에러 코드는 true를 반환한다")
    func returnsTrueWhenCodeMeansAlreadyReviewed() {
        #expect(NovelReviewMapper.isAlreadyReviewed(code: "USER_NOVEL-001") == true)
    }
    
    @Test("이미 리뷰가 존재하는 에러 코드가 아니면 false를 반환한다")
    func returnsFalseWhenCodeDoesNotMeanAlreadyReviewed() {
        #expect(NovelReviewMapper.isAlreadyReviewed(code: nil) == false)
        #expect(NovelReviewMapper.isAlreadyReviewed(code: "SOMETHING-ELSE") == false)
    }
}
