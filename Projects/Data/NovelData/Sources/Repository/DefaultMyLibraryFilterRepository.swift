//
//  DefaultMyLibraryFilterRepository.swift
//  NovelData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain
import BaseData

/// 내 서재 필터·정렬을 `UserDefaults`(`AppStorage`)에 JSON 스냅샷으로 영속화한다(#221).
///
/// 네트워크가 없어 `NovelService`가 필요 없다 — `appStorage`와 로거만 의존한다.
/// 저장/복원 모두 best-effort: 인코딩·디코딩 실패는 로그만 남기고 삼킨다(복원 실패 → nil → 기본 필터).
struct DefaultMyLibraryFilterRepository: MyLibraryFilterRepository {

    private let appStorage: AppStorage
    private let logger: DataLogger?

    init(appStorage: AppStorage, logger: DataLogger?) {
        self.appStorage = appStorage
        self.logger = logger
    }

    func loadFilter() -> MyLibraryFilter? {
        guard let data = appStorage.get(.myLibraryFilter) else { return nil }
        do {
            let snapshot = try JSONDecoder().decode(MyLibraryFilterSnapshot.self, from: data)
            return MyLibraryFilterSnapshotMapper.filter(from: snapshot)
        } catch {
            // 저장 포맷이 바뀌었거나 손상된 경우 — 기본 필터로 떨어진다(화면을 막지 않는다).
            logger?.logUnknownError(action: NovelAction.loadMyLibraryFilter.text, error: error)
            return nil
        }
    }

    func saveFilter(_ filter: MyLibraryFilter) {
        let snapshot = MyLibraryFilterSnapshotMapper.snapshot(from: filter)
        do {
            let data = try JSONEncoder().encode(snapshot)
            appStorage.set(.myLibraryFilter, data)
        } catch {
            logger?.logUnknownError(action: NovelAction.saveMyLibraryFilter.text, error: error)
        }
    }
}
