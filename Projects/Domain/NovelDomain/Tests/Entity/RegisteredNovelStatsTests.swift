//
//  RegisteredNovelStatsTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct RegisteredNovelStatsTests {

    @Test("RegisteredNovelStats를 정상적으로 생성한다")
    func createStats() {
        let stats = makeStats()

        #expect(stats.interest == 10)
        #expect(stats.watching == 20)
        #expect(stats.watched == 30)
        #expect(stats.quit == 5)
    }

    @Test("모든 카운트가 0인 경우에도 생성된다")
    func createStatsWithZeroCounts() {
        let stats = makeStats(interest: 0, watching: 0, watched: 0, quit: 0)

        #expect(stats.interest == 0)
        #expect(stats.watching == 0)
        #expect(stats.watched == 0)
        #expect(stats.quit == 0)
    }
}

extension RegisteredNovelStatsTests {

    private func makeStats(
        interest: Int = 10,
        watching: Int = 20,
        watched: Int = 30,
        quit: Int = 5
    ) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: interest, watching: watching, watched: watched, quit: quit)
    }
}
