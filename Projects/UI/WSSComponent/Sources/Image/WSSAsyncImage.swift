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
/// 인메모리 캐시(`WSSImageCache`)에 두고 렌더 경로(`displayedImage`)에서 동기 조회** →
/// 히트면 첫 프레임부터 실제 이미지를 그린다. (`init`이나 `.task`에서 조회하면 늦는다 — 아래 `displayedImage` 주석 참고.)
///
/// `content`/`placeholder`는 호출자가 정한다(`AsyncImage(url:content:placeholder:)`와 같은 형태).
/// 프레임·클립 등은 바깥에서 얹는다.
public struct WSSAsyncImage<Content: View, Placeholder: View>: View {

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var image: UIImage?
    /// `image`가 **어느 url의** 결과인지. 이게 없으면 url이 바뀐 첫 프레임에 옛 이미지를 그린다.
    @State private var loadedURL: URL?

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    /// 렌더 시점에 **현재 url과 짝이 맞는** 이미지만 그린다.
    /// `@State`는 url이 바뀐 첫 프레임엔 아직 옛 값이고(`.task`는 렌더 *뒤*에 돈다), 초기값도 저장소가
    /// 처음 만들어질 때만 적용된다 → 여기서 캐시를 **동기 조회**해야 캐시 히트가 첫 프레임부터 보인다.
    private var displayedImage: UIImage? {
        guard loadedURL == url else {
            return url.flatMap(WSSImageCache.shared.image(for:))
        }
        return image
    }

    public var body: some View {
        Group {
            if let displayedImage {
                content(Image(uiImage: displayedImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) { await load() }
    }

    /// `url`이 바뀔 때마다 다시 돈다.
    ///
    /// `loadedURL`은 **이미지를 실제로 확보했을 때만** 현재 url로 확정한다. 실패·취소 때 미리 찍어두면
    /// `loadedURL == url && image == nil`로 굳어, 이후 다른 인스턴스가 같은 url을 공유 캐시에 넣어도
    /// `displayedImage`가 캐시를 다시 보지 않고 placeholder에 갇힌다(`.task`는 url이 바뀌어야 재실행).
    private func load() async {
        guard let url else {
            image = nil
            loadedURL = nil
            return
        }
        // 캐시 히트면 네트워크로 안 간다.
        if let cached = WSSImageCache.shared.image(for: url) {
            image = cached
            loadedURL = url
            return
        }
        image = nil  // 옛 url의 이미지를 지우고 placeholder로 되돌린다.
        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let loaded = UIImage(data: data),
            // 취소는 await 재개 뒤에도 확인해야 한다 — 안 그러면 취소된 옛 요청이 새 url의 그림을 덮고,
            // 그 뒤 새 요청까지 막아버린다.
            !Task.isCancelled
        else { return }
        WSSImageCache.shared.insert(loaded, for: url)
        image = loaded
        loadedURL = url
    }
}
