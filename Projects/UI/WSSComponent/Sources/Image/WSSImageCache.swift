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
final class WSSImageCache {

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
