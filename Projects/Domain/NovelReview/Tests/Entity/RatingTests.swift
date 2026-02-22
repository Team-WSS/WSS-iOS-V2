//
//  RatingTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import NovelReviewDomain
import NovelReviewDomainTesting

@Suite("Rating")
struct RatingTests {

    @Test("평점은 0.5부터 5.0까지 0.5 단위로만 허용된다")
    func acceptsValidValues() throws {
        // 0.5, 1.0, 1.5, ..., 5.0
        let validValues = stride(from: 0.5, through: 5.0, by: 0.5)
        for v in validValues {
            let rating = try Rating(v)
            #expect(rating.value == v)
        }
    }

    @Test("평점은 최소값 0.5와 최대값 5.0을 허용한다")
    func acceptsBoundaries() throws {
        let low = try Rating(0.5)
        #expect(low.value == 0.5)

        let high = try Rating(5.0)
        #expect(high.value == 5.0)
    }

    @Test("평점이 허용 범위를 벗어나면 예외가 발생한다")
    func rejectsOutOfRange() {
        #expect(throws: Rating.ValidationError.outOfRange) {
            _ = try Rating(0.0)
        }
        #expect(throws: Rating.ValidationError.outOfRange) {
            _ = try Rating(5.5)
        }
        #expect(throws: Rating.ValidationError.outOfRange) {
            _ = try Rating(-1.0)
        }
        #expect(throws: Rating.ValidationError.outOfRange) {
            _ = try Rating(999.0)
        }
    }

    @Test("평점이 0.5 단위가 아니면 예외가 발생한다")
    func rejectsInvalidStep() {
        #expect(throws: Rating.ValidationError.invalidStep) {
            _ = try Rating(4.7)
        }
        #expect(throws: Rating.ValidationError.invalidStep) {
            _ = try Rating(1.25)
        }
    }

    @Test("같은 값의 평점은 서로 동등하다")
    func equatableByValue() throws {
        let a = try Rating(3.5)
        let b = try Rating(3.5)
        let c = try Rating(4.0)

        #expect(a == b)
        #expect(a != c)
    }
}
