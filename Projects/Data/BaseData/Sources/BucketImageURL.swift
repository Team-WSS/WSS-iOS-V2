//
//  BucketImageURL.swift
//  BaseData
//
//  Created by YunhakLee on 7/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서버 이미지 문자열 → `URL` 변환기.
/// 서버는 full URL과 버킷 상대 경로(예: `/platform/naver-series`)를 **섞어** 내려주며,
/// 경로형은 클라이언트가 `{경로}@{스케일}x.png`로 완성하는 규약이다(버킷엔 @2x/@3x 래스터가 있다).
/// ⚠️ 경로형에 SVG는 못 쓴다 — `AsyncImage`(UIImage)는 런타임 다운로드 SVG를 디코딩하지 못한다.
public enum BucketImageURL {

    /// 이미지 요청에 쓸 기기 스케일. **루트 뷰 등 UI 컨텍스트(메인 스레드)에서 1회 설정**한다
    /// (SwiftUI `@Environment(\.displayScale)` 권장). 기기 스케일은 런타임에 변하지 않으므로 1회면 충분하다.
    /// 매퍼는 백그라운드에서 돌 수 있어 `UITraitCollection.current`를 직접 읽으면 0이 나올 수 있다 —
    /// 그래서 값(Int) 주입 방식이다(Data는 UIKit을 모른다).
    /// 기본값 3: 미설정이어도 @3x는 모든 기기에서 다운스케일될 뿐 안전하다.
    public static var displayScale: Int = 3

    /// full URL(`http…`)은 그대로, 버킷 경로는 스케일 규약으로 조립한다.
    /// 빈 문자열·버킷 주소(BUCKET_URL) 미설정 등 조립 불가면 nil —
    /// 이미지 필드는 optional이라 화면에서 placeholder로 자연 강등된다.
    public static func imageURL(from path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        let bucket = NetworkingConfig.bucketURL
        guard !bucket.isEmpty else { return nil }
        // 버킷 주소 끝/경로 앞의 슬래시가 어긋나도 깨지지 않게 정규화한다.
        let base = bucket.hasSuffix("/") ? String(bucket.dropLast()) : bucket
        let relative = path.hasPrefix("/") ? path : "/" + path
        return URL(string: "\(base)\(relative)@\(displayScale)x.png")
    }
}
