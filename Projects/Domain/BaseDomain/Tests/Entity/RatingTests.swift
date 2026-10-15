//
//  RatingTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain

@Suite("평점")
struct RatingTests {

    @Test(
        "0.5부터 5.0까지 반 점 단위면 평점이 된다",
        arguments: [
            0.5,  // 가장 낮은 평점
            3.0,  // 중간의 정수 평점
            5.0   // 가장 높은 평점
        ]
    )
    func halfStepsWithinRangeAreRatings(value: Double) throws {
        let rating = try Rating(value)

        #expect(rating.value == value)
    }

    @Test(
        "범위 밖이면 평점이 아니다",
        arguments: [
            0.0,  // 가장 낮은 평점보다 반 점 작다
            5.5   // 가장 높은 평점보다 반 점 크다
        ]
    )
    func outOfRangeIsNotRating(value: Double) {
        #expect(throws: Rating.ValidationError.outOfRange) {
            try Rating(value)
        }
    }

    @Test(
        "반 점 단위가 아니면 평점이 아니다",
        arguments: [
            4.7,   // 소수 첫째 자리가 반 점이 아니다
            1.25   // 반 점보다 잘게 나눴다
        ]
    )
    func nonHalfStepIsNotRating(value: Double) {
        #expect(throws: Rating.ValidationError.invalidStep) {
            try Rating(value)
        }
    }
}
