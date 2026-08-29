//
//  WSSImageLoader.swift
//  WSSComponent
//
//  Created by YunhakLee on 8/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UIKit

/// URL → 디코딩된 `UIImage` 로더. `WSSImageCache`(인메모리, 화면 간 공유)를 먼저 보고, 없으면 받아서 넣는다.
///
/// `WSSAsyncImage`의 로딩 경로를 뷰 없이도 쓸 수 있게 뽑은 것(#228) — 공유 시트 미리보기(`SharePreview`)처럼
/// `Image` 값 자체가 필요한 자리는 뷰로는 못 받기 때문. 값으로 받은 URL에서 바이트만 읽을 뿐 앱 네트워킹
/// 스택·인증은 모른다(`UI/CLAUDE.md`의 "URL 기반 이미지 로딩은 표현 인프라" 예외 그대로).
public enum WSSImageLoader {
    /// 캐시 히트면 네트워크로 안 간다. 실패(네트워크·디코딩)는 nil — 호출부가 폴백(미리보기 없이 제목만 등)을 정한다.
    public static func load(_ url: URL) async -> UIImage? {
        if let cached = WSSImageCache.shared.image(for: url) {
            return cached
        }
        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let image = UIImage(data: data)
        else { return nil }
        WSSImageCache.shared.insert(image, for: url)
        return image
    }
}
