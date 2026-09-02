//
//  WSSAsyncImageDemoView.swift
//  WSSComponent
//
//  Created by Claude on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import WSSComponent

/// `WSSAsyncImage`/`WSSNovelCoverImage`의 로딩 상태(`isLoading`) 표시를 눈으로 확인하는 데모(#237).
/// `WSSImageCache`가 세션 중 URL별로 캐시하므로, **한 번 로드된 URL은 다시 봐도 즉시 그려져 로딩
/// 상태가 안 보인다** — 그래서 "새 URL로 다시 로딩" 버튼이 매번 새 picsum ID를 골라 캐시를 강제로
/// 무효화한다(진짜 캐시 미스라야 `WSSImageLoader`가 실제로 네트워크에 나가 `isLoading`이 `true`가 됨).
struct WSSAsyncImageDemoView: View {

    private enum URLMode: String, CaseIterable, Identifiable {
        case normal = "정상 URL"
        case nilURL = "URL 없음"
        case failing = "로딩 실패"
        var id: String { rawValue }
    }

    @State private var mode: URLMode = .normal
    /// picsum.photos ID 시드 — 바뀔 때마다 새 URL이라 `WSSImageCache`가 무조건 미스한다.
    @State private var seed = Int.random(in: 1...800)

    private var singleURL: URL? {
        switch mode {
        case .normal: URL(string: "https://picsum.photos/id/\(seed)/300/450")
        case .nilURL: nil
        // 존재하지 않는 호스트 — WSSImageLoader가 실패하고, WSSAsyncImage는 실패를 별도 상태로
        // 노출하지 않으므로(placeholder에 계속 머묾) isLoading이 다시 false로 떨어진 뒤에도
        // 기본 표지로 조용히 남는 것까지 확인할 수 있다.
        case .failing: URL(string: "https://wss-does-not-exist.invalid/no-image.jpg")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("""
                한 번 로드된 URL은 이 세션 동안 캐시돼 다음엔 즉시 그려집니다. \
                아래 버튼으로 새 URL을 골라야 캐시가 미스되어 실제 로딩(ProgressView) 상태를 볼 수 있습니다.
                """)
                .font(.footnote)
                .foregroundStyle(.secondary)

                controls

                section("WSSNovelCoverImage — .default (단일 이미지, 배경 없이 스피너만)") {
                    WSSNovelCoverImage(url: singleURL, placeholderStyle: .default)
                        .frame(width: 120, height: 168)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                section("WSSNovelCoverImage — .grid (배경색 + 스피너, 그리드 6칸 동시 로딩)") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            WSSNovelCoverImage(
                                url: mode == .normal ? URL(string: "https://picsum.photos/id/\(seed + index)/300/450") : singleURL,
                                aspectRatio: 3.0 / 4.0,
                                placeholderStyle: .grid
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                section("WSSAsyncImage — isLoading 인자 직접 확인") {
                    WSSAsyncImage(url: singleURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: { isLoading in
                        VStack(spacing: 6) {
                            if isLoading {
                                ProgressView()
                                Text("isLoading = true").font(.caption2)
                            } else {
                                Text("isLoading = false\n(URL 없음/실패/캐시 히트)")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.15))
                    }
                    .frame(width: 120, height: 168)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("URL 상태", selection: $mode) {
                ForEach(URLMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Button("새 URL로 다시 로딩 (캐시 미스 강제)") {
                seed = Int.random(in: 1...800)
            }
            .buttonStyle(.borderedProminent)
            .disabled(mode != .normal)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
            content()
        }
    }
}

#Preview {
    WSSAsyncImageDemoView()
}
