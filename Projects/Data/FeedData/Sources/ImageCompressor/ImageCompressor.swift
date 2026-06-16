//
//  ImageCompressor.swift
//  FeedData
//
//  Created by Lee Wonsun on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 피드 업로드용 이미지 압축 정책입니다.
///
/// 서버 스펙(이미지당 최대 용량)을 충족시키기 위해 다운샘플과 JPEG 품질을 조정합니다.
public struct ImageCompressionPolicy: Sendable {
    /// 이미지 한 장의 목표 최대 바이트 수입니다. (서버 스펙 기준)
    public let maxByteSize: Int
    /// 긴 변의 최대 픽셀 수입니다. 이보다 크면 다운샘플합니다.
    public let maxPixelSize: CGFloat
    /// JPEG 품질 하한선입니다. 이진 탐색이 이 값 아래로는 내려가지 않습니다.
    public let minQuality: CGFloat

    public init(maxByteSize: Int, maxPixelSize: CGFloat, minQuality: CGFloat) {
        self.maxByteSize = maxByteSize
        self.maxPixelSize = maxPixelSize
        self.minQuality = minQuality
    }

    /// 피드 기본 정책입니다. `maxByteSize`는 V1 서버 스펙(512 * 512 = 256KB)을 그대로 사용합니다.
    public static let feedDefault = ImageCompressionPolicy(
        maxByteSize: 512 * 512,
        maxPixelSize: 1920,
        minQuality: 0.1
    )
}

/// `Data → Data` 이미지 압축기입니다.
///
/// `UIImage` 디코딩 없이 ImageIO로 직접 처리하여 메모리 사용을 최소화합니다.
/// 처리 순서는 ① 다운샘플 1회 → ② JPEG 품질 이진 탐색입니다.
public struct ImageCompressor: Sendable {
    private let policy: ImageCompressionPolicy

    public init(policy: ImageCompressionPolicy = .feedDefault) {
        self.policy = policy
    }

    /// 여러 이미지를 병렬로 압축합니다. 입력 순서를 보존합니다.
    ///
    /// 압축에 실패한 이미지는 원본 데이터를 그대로 반환합니다.
    public func compress(_ imageDatas: [Data]) async -> [Data] {
        await withTaskGroup(of: (Int, Data).self) { group in
            for (index, data) in imageDatas.enumerated() {
                group.addTask {
                    (index, self.compress(data))
                }
            }

            var results = [Data?](repeating: nil, count: imageDatas.count)
            for await (index, data) in group {
                results[index] = data
            }
            return results.compactMap { $0 }
        }
    }

    /// 단일 이미지를 압축합니다. 실패 시 원본을 그대로 반환합니다.
    public func compress(_ data: Data) -> Data {
        guard let cgImage = downsampledImage(from: data) else { return data }
        return compressedJPEG(from: cgImage) ?? data
    }
}

// MARK: - Downsampling

private extension ImageCompressor {
    /// 긴 변이 `maxPixelSize`를 넘지 않도록 다운샘플한 CGImage를 생성합니다.
    ///
    /// 원본 비트맵 전체를 메모리에 펼치지 않고 썸네일 크기만 디코딩합니다.
    func downsampledImage(from data: Data) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: policy.maxPixelSize
        ] as CFDictionary

        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
    }
}

// MARK: - JPEG Encoding

private extension ImageCompressor {
    /// 목표 바이트 이하가 되도록 JPEG 품질을 이진 탐색하여 인코딩합니다.
    ///
    /// 가장 작으면서 목표를 만족하는 결과를 우선하되, 끝내 목표를 못 맞추면
    /// 탐색 중 가장 작았던 결과(`minQuality`까지)를 반환합니다.
    func compressedJPEG(from cgImage: CGImage) -> Data? {
        var low = policy.minQuality
        var high: CGFloat = 1.0
        var bestUnderLimit: Data?
        var smallestData: Data?

        // 품질 1.0 결과가 이미 목표 이하면 추가 탐색 없이 사용합니다.
        if let initialData = encodeJPEG(cgImage, quality: 1.0),
           initialData.count <= policy.maxByteSize {
            return initialData
        }

        // 이진 탐색: 목표를 만족하는 가장 높은 품질을 찾습니다.
        for _ in 0..<8 {
            let mid = (low + high) / 2
            guard let data = encodeJPEG(cgImage, quality: mid) else { break }

            if smallestData.map({ data.count < $0.count }) ?? true {
                smallestData = data
            }

            if data.count <= policy.maxByteSize {
                bestUnderLimit = data
                low = mid
            } else {
                high = mid
            }
        }

        return bestUnderLimit ?? smallestData
    }

    func encodeJPEG(_ cgImage: CGImage, quality: CGFloat) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, properties)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
