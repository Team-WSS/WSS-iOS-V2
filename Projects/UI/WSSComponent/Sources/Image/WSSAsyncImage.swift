//
//  WSSAsyncImage.swift
//  WSSComponent
//
//  Created by YunhakLee on 7/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import UIKit

/// 캐시하는 비동기 이미지 — 한 번 로드한 이미지는 인메모리 캐시에 두어, 뷰가 재생성돼도
/// placeholder 번쩍임 없이 즉시 다시 그린다.
///
/// SwiftUI `AsyncImage`는 뷰 정체성이 바뀔 때마다 `.empty` phase부터 다시 시작해 **캐시 히트여도**
/// placeholder가 한 프레임 번쩍인다(목록 셀 모드 전환·스크롤 재활용에서 매번 도진다). `URLCache`는
/// **응답 데이터**만 갖고 있어 재디코딩 사이 그 틈이 남는다. 그래서 여기선 **디코딩된 `UIImage`를
/// 인메모리 캐시(`WSSImageCache`)에 두고 `init`에서 동기 조회** → 히트면 첫 프레임부터 실제 이미지를 그린다.
///
/// `content`/`placeholder`는 호출자가 정한다(`AsyncImage(url:content:placeholder:)`와 같은 형태).
/// 프레임·클립 등은 바깥에서 얹는다.
public struct WSSAsyncImage<Content: View, Placeholder: View>: View {

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var image: UIImage?

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        // 인메모리 캐시 동기 조회 — 히트면 image가 채워진 채로 첫 렌더에 실제 이미지가 나온다(번쩍임 없음).
        _image = State(initialValue: url.flatMap(WSSImageCache.shared.image(for:)))
    }

    public var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) { await loadIfNeeded() }
    }

    private func loadIfNeeded() async {
        // 캐시 히트로 이미 그렸으면 네트워크로 안 간다.
        guard image == nil, let url else { return }
        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let loaded = UIImage(data: data)
        else { return }
        WSSImageCache.shared.insert(loaded, for: url)
        image = loaded
    }
}

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
