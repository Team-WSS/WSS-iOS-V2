//
//  DetailSearchQuery.swift
//  SearchData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DetailSearchQuery: QueryItemConvertible {
    let genres: [String]
    let platformNames: [String]
    /// 연재상태 미선택은 nil로 둬 파라미터 자체를 생략한다(QueryItemConvertible이 NSNull 제외).
    /// non-optional Bool이면 미선택도 false로 나가 서버가 "연재중만"으로 해석 → 완결작 누락(회귀).
    let isCompleted: Bool?
    let novelRatingStart: Float
    let novelRatingEnd: Float
    let keywordIds: [Int]
    let page: Int
    let size: Int
}
