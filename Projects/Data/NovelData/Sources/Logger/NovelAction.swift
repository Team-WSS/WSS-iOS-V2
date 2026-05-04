//
//  NovelLogger.swift
//  NovelData
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Logger

public enum NovelAction {
    case fetchNovel
    case addInterest
    case removeInterest
    case searchByText(query: String)
    case searchByFilter
    case fetchMyLibrary
    case fetchUserLibrary
    case fetchRegisteredStats
    
    public var text: String {
        switch self {
        case .fetchNovel:                       return "작품 정보 조회"
        case .addInterest:                      return "작품 관심 등록"
        case .removeInterest:                   return "작품 관심 해제"
        case .searchByText(let query):          return "'\(query)' 텍스트 검색"
        case .searchByFilter:                   return "필터 검색"
        case .fetchMyLibrary:                   return "내 서재 조회"
        case .fetchUserLibrary:                 return "유저 서재 조회"
        case .fetchRegisteredStats:             return "등록 작품 통계 조회"
        }
    }
}
