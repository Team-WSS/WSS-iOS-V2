//
//  CollectionRoutes.swift
//  CollectionFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import CollectionDomain

// 컬렉션 모듈의 화면별 화면 전환 의도(#253) — 실제 화면 조립·push는 호출자(App 조정 계층)가
// exhaustive switch로 수행한다. 화면 수가 많아 한 파일에 모은다(케이스 소속은 enum 이름이 말해준다).
// 확정 결과 콜백(`onConfirm` — pop은 App 몫)과 결과 반환 Binding(`pendingNovelSelection`)은 화면
// 전환 "의도"가 아니라 여기 없다.

/// 컬렉션 생성/수정(`CreateCollectionView` — 두 모드가 화면을 공유).
public enum CreateCollectionRoute {
    /// "작품 추가" 타일 탭 — 현재 선택된 작품 목록을 실어 올린다(그 화면이 이미 담긴 작품도 선택된
    /// 채로 보여주는 편집 화면이라서). 결과는 `pendingNovelSelection` Binding으로 돌아온다.
    case addNovel([CollectionNovel])
}

/// "작품 추가"(검색 다중선택, `CollectionSearchNovelView`).
public enum CollectionSearchNovelRoute {
    /// "서재에서 추가" 탭 — 현재까지 선택된 목록을 실어 올린다.
    case myLibrarySelect([CollectionNovel])
}

/// 컬렉션 목록(`CollectionListView`).
public enum CollectionListRoute {
    /// "컬렉션 만들기" 버튼 탭.
    case createCollection
    /// 카드 탭 → 컬렉션 상세.
    case collectionDetail(CollectionID)
}

/// 컬렉션 상세(`CollectionDetailView`).
public enum CollectionDetailRoute {
    /// 작품 그리드 셀 탭 → 작품 상세.
    case novelDetail(NovelID)
    /// 더보기 "컬렉션 수정" 탭 — 수정 화면이 `id`로 대상을 스스로 다시 불러오므로 payload가 없다.
    case editCollection
}
