//
//  WSSImageCache.swift
//  WSSComponent
//
//  Created by YunhakLee on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UIKit

/// 인메모리 이미지 캐시 — **디코딩된** `UIImage`를 URL 기준으로 보관한다.
/// URLCache(응답 데이터)와 별개로 디코딩 결과를 들고 있어야 동기 조회로 번쩍임 없이 그릴 수 있다.
/// `NSCache`는 스레드 세이프하고 메모리 압박 시 자동 축출한다. `WSSAsyncImage`를 쓰는 모든 화면이 공유한다.
///
/// `@unchecked Sendable`: 유일한 저장 상태가 `NSCache`(그 자체로 스레드 세이프)라 `static let shared`를
/// 여러 스레드에서 안전하게 공유한다. 컴파일러는 NSCache의 스레드 안전성을 모르므로 unchecked로 명시한다.
final class WSSImageCache: @unchecked Sendable {

    static let shared = WSSImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 300  // 표지·프로필 수백 장 수준 — 목록 화면 규모에 충분.
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
