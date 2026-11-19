//
//  NovelKeywordLookupTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 11/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain
import BaseDomainTesting
import NovelDomain
import NovelDomainTesting

// 서버는 작품의 키워드를 이름으로만 준다. 앱은 전체 키워드 목록에서 같은 이름을 찾아 키워드로 바꾸므로,
// 불러오는 UseCase는 모든 카테고리의 키워드를 넘겨야 한다.
// 카테고리를 둘로 나눠 둬서, 한 카테고리의 키워드만 넘기면 저장소가 답을 찾지 못한다.
private let keywordGroups = [
    KeywordGroup(category: .material, keywords: [
        Keyword(id: KeywordID(11), name: "회귀")
    ]),
    KeywordGroup(category: .character, keywords: [
        Keyword(id: KeywordID(21), name: "먼치킨"),
        Keyword(id: KeywordID(22), name: "사이다")
    ])
]
private let allKeywords = Set(keywordGroups.flatMap(\.keywords))
private let emptyPage = CursorPaginated<LibraryNovel>(items: [], hasNext: false, nextCursor: nil)

@Suite("작품의 키워드 알아보기")
struct NovelKeywordLookupTests {

    @Suite("작품 상세")
    struct NovelDetail {

        @Test("작품 상세를 불러올 때 모든 카테고리의 키워드를 넘긴다")
        func passesKeywordsOfAllCategories() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.novelsByCachedKeywords = [allKeywords: makeNovelInformation(feedCount: 7)]
            let useCase = DefaultLoadNovelUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .success(keywordGroups))
            )

            let information = try await useCase.execute(id: NovelID(1))

            #expect(information.feedCount == 7)
        }

        @Test("전체 키워드를 못 불러와도 작품 상세는 불러온다")
        func loadsWithoutKeywords() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.novelsByCachedKeywords = [[]: makeNovelInformation(feedCount: 7)]
            let useCase = DefaultLoadNovelUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .failure(.networkUnavailable))
            )

            let information = try await useCase.execute(id: NovelID(1))

            #expect(information.feedCount == 7)
        }
    }

    @Suite("내 서재")
    struct MyLibrary {

        @Test("내 서재를 불러올 때 모든 카테고리의 키워드를 넘긴다")
        func passesKeywordsOfAllCategories() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.myLibraryByCachedKeywords = [allKeywords: (emptyPage, 37)]
            let useCase = DefaultLoadMyLibraryUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .success(keywordGroups))
            )

            let (_, totalCount) = try await useCase.execute(filter: MyLibraryFilter(), cursor: nil, size: 15)

            #expect(totalCount == 37)
        }

        @Test("전체 키워드를 못 불러와도 내 서재 목록은 불러온다")
        func loadsWithoutKeywords() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.myLibraryByCachedKeywords = [[]: (emptyPage, 37)]
            let useCase = DefaultLoadMyLibraryUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .failure(.networkUnavailable))
            )

            let (_, totalCount) = try await useCase.execute(filter: MyLibraryFilter(), cursor: nil, size: 15)

            #expect(totalCount == 37)
        }
    }

    @Suite("다른 사람 서재")
    struct UserLibrary {

        @Test("다른 사람 서재를 불러올 때 모든 카테고리의 키워드를 넘긴다")
        func passesKeywordsOfAllCategories() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.userLibraryByCachedKeywords = [allKeywords: (emptyPage, 37)]
            let useCase = DefaultLoadUserLibraryUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .success(keywordGroups))
            )

            let (_, totalCount) = try await useCase.execute(id: UserID(3), filter: LibraryFilter(), cursor: nil)

            #expect(totalCount == 37)
        }

        @Test("전체 키워드를 못 불러와도 다른 사람 서재 목록은 불러온다")
        func loadsWithoutKeywords() async throws {
            let novelRepository = MockNovelRepository()
            novelRepository.userLibraryByCachedKeywords = [[]: (emptyPage, 37)]
            let useCase = DefaultLoadUserLibraryUseCase(
                novelRepository: novelRepository,
                loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .failure(.networkUnavailable))
            )

            let (_, totalCount) = try await useCase.execute(id: UserID(3), filter: LibraryFilter(), cursor: nil)

            #expect(totalCount == 37)
        }
    }
}

private func makeNovelInformation(feedCount: Int) -> NovelInformation {
    NovelInformation(
        novel: Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "전지적 독자 시점",
            authors: ["싱숑"],
            genres: [.fantasy],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: nil
        ),
        feedCount: feedCount,
        publicationStatus: .completed,
        userReview: nil,
        description: "재밌는 소설입니다.",
        platforms: [],
        attractivePoints: [],
        keywords: [],
        readingStatusCount: [:]
    )
}
