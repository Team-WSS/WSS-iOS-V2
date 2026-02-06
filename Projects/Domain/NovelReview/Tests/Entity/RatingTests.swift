//
//  RatingTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import NovelReviewDomain

@Suite("Rating")
struct RatingTests {

    @Test("accepts all valid values from 0.5 to 5.0 in 0.5 steps")
    func acceptsValidValues() throws {
        // 0.5, 1.0, 1.5, ..., 5.0
        let validValues = stride(from: 0.5, through: 5.0, by: 0.5)
        for v in validValues {
            let rating = try Rating(v)
            #expect(rating.value == v)
        }
    }

    @Test("accepts boundary values 0.5 and 5.0")
    func acceptsBoundaries() throws {
        let low = try Rating(0.5)
        #expect(low.value == 0.5)

        let high = try Rating(5.0)
        #expect(high.value == 5.0)
    }

    @Test("rejects out-of-range values")
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

    @Test("rejects values not on 0.5-step (invalidStep)")
    func rejectsInvalidStep() {
        #expect(throws: Rating.ValidationError.invalidStep) {
            _ = try Rating(4.7)
        }
        #expect(throws: Rating.ValidationError.invalidStep) {
            _ = try Rating(1.25)
        }
    }

    @Test("equatable compares by value")
    func equatableByValue() throws {
        let a = try Rating(3.5)
        let b = try Rating(3.5)
        let c = try Rating(4.0)

        #expect(a == b)
        #expect(a != c)
    }
}
