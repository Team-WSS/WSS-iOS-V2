//
//  NovelLogger.swift
//  NovelData
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Logger

enum NovelAction {
    case fetchNovel
    case addInterest
    case removeInterest
    case fetchMyLibrary
    case fetchMyLibraryKeywords
    case fetchUserLibrary
    case fetchRegisteredStats
    case fetchUserRegisteredStats
    case loadMyLibraryFilter
    case saveMyLibraryFilter

    public var text: String {
        switch self {
        case .fetchNovel:                       return "작품 정보 조회"
        case .addInterest:                      return "작품 관심 등록"
        case .removeInterest:                   return "작품 관심 해제"
        case .fetchMyLibrary:                   return "내 서재 조회"
        case .fetchMyLibraryKeywords:           return "서재 등록 키워드 조회"
        case .fetchUserLibrary:                 return "유저 서재 조회"
        case .fetchRegisteredStats:             return "등록 작품 통계 조회"
        case .fetchUserRegisteredStats:         return "유저 등록 작품 통계 조회"
        case .loadMyLibraryFilter:              return "내 서재 필터 복원"
        case .saveMyLibraryFilter:              return "내 서재 필터 저장"
        }
    }
}
