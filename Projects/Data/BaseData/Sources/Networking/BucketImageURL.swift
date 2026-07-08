//
//  BucketImageURL.swift
//  BaseData
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import UIKit

/// 서버에서 받은 이미지 path를 버킷 호스트 + 디스플레이 스케일을 붙여 풀 URL로 변환한다.
///
/// 디스플레이 스케일은 UIKit 격리 타입(`UITraitCollection.current`)에서 읽어야 하므로,
/// 매퍼가 off-main에서 호출돼도 안전하도록 **앱 시작 시 `configure()`로 1회 캐시**해 사용한다.
/// 호출하지 않은 경우 `3`(요즘 디바이스 다수가 @3x)으로 폴백한다.
public enum BucketImageURL {

    private static let storage = Storage()

    /// 캐시된 디스플레이 스케일. configure 미호출 시 3 폴백.
    public static var displayScale: Int { storage.displayScale }

    /// 앱 시작 시점 main-actor에서 1회 호출해 디스플레이 스케일을 캐시한다.
    @MainActor
    public static func configure() {
        storage.displayScale = Int(UITraitCollection.current.displayScale)
    }

    /// 서버 path(`/users/123/profile`) → 풀 이미지
    public static func make(path: String) -> URL? {
        URL(string: "\(NetworkingConfig.bucketURL)\(path)@\(displayScale)x.png")
    }

    private final class Storage: @unchecked Sendable {
        var displayScale: Int = 3
    }
}
