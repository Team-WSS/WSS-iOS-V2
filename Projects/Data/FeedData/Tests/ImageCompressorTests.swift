//
//  ImageCompressorTests.swift
//  FeedDataTests
//
//  Created by Lee Wonsun on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing
import UIKit
@testable import FeedData

@Suite
struct ImageCompressorTests {

    // MARK: - 정상 케이스

    @Test("목표 바이트를 초과하는 이미지는 목표 이하로 압축된다")
    func compress_largeImage_resultIsUnderMaxByteSize() async throws {
        let policy = ImageCompressionPolicy(maxByteSize: 256 * 1024, maxPixelSize: 1024, minQuality: 0.1)
        let sut = ImageCompressor(policy: policy)
        let largeImageData = try #require(makeNoisyImageData(size: 2000))

        let compressed = sut.compress(largeImageData)

        #expect(compressed.count <= policy.maxByteSize)
        #expect(compressed.count < largeImageData.count)
    }

    @Test("이미 목표 바이트 이하인 이미지는 더 키우지 않는다")
    func compress_smallImage_doesNotGrow() async throws {
        let policy = ImageCompressionPolicy(maxByteSize: 5 * 1024 * 1024, maxPixelSize: 1920, minQuality: 0.1)
        let sut = ImageCompressor(policy: policy)
        let smallImageData = try #require(makeSolidImageData(size: 50))

        let compressed = sut.compress(smallImageData)

        #expect(compressed.count <= policy.maxByteSize)
        #expect(!compressed.isEmpty)
    }

    // MARK: - 경계값 / 정책 위반 케이스

    @Test("이미지로 디코딩되지 않는 데이터는 원본을 그대로 반환한다")
    func compress_nonImageData_returnsOriginal() async {
        let sut = ImageCompressor()
        let garbage = Data("not an image".utf8)

        let result = sut.compress(garbage)

        #expect(result == garbage)
    }

    @Test("빈 입력 배열은 빈 결과를 반환한다")
    func compress_emptyArray_returnsEmpty() async {
        let sut = ImageCompressor()

        let result = await sut.compress([Data]())

        #expect(result.isEmpty)
    }

    // MARK: - 상태/순서 검증

    @Test("여러 이미지를 압축해도 입력 순서가 보존된다")
    func compress_multipleImages_preservesOrder() async throws {
        let sut = ImageCompressor()
        // 디코딩 불가한 데이터는 원본 그대로 반환되므로 순서 검증에 사용한다.
        let inputs = [
            Data("first".utf8),
            Data("second".utf8),
            Data("third".utf8)
        ]

        let result = await sut.compress(inputs)

        #expect(result == inputs)
    }
}

// MARK: - Helpers

private extension ImageCompressorTests {

    /// 단색 이미지는 JPEG로 매우 작게 압축되므로 "작은 이미지" 케이스에 사용한다.
    func makeSolidImageData(size: CGFloat) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
        return image.jpegData(compressionQuality: 1.0)
    }

    /// 노이즈가 많은 이미지는 JPEG 압축이 잘 안 되어 용량이 커지므로 "큰 이미지" 케이스에 사용한다.
    func makeNoisyImageData(size: CGFloat) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let step: CGFloat = 4
            var y: CGFloat = 0
            var seed: UInt64 = 0x9E3779B97F4A7C15
            while y < size {
                var x: CGFloat = 0
                while x < size {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    let hue = CGFloat((seed >> 33) & 0xFF) / 255.0
                    UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).setFill()
                    context.fill(CGRect(x: x, y: y, width: step, height: step))
                    x += step
                }
                y += step
            }
        }
        return image.jpegData(compressionQuality: 1.0)
    }
}
