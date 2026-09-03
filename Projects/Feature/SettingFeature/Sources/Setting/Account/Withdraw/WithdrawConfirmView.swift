//
//  WithdrawConfirmView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import BaseDomain
import NovelDomain

struct WithdrawConfirmView: View {

    @State private var viewModel: WithdrawConfirmViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let stateColumnCount = 2
    private let statelItemSpacing: CGFloat = 6
    private let stateColumnSpacing: CGFloat = 6
    /// "확인" 탭 시 호출된다. 실제 탈퇴 제출은 다음 화면(`WithdrawReasonView`)의 책임이라
    /// 이 화면은 다음 화면으로의 이동 신호만 호출자에게 알린다.
    private let onConfirm: () -> Void

    init(viewModel: WithdrawConfirmViewModel, onConfirm: @escaping () -> Void = {}) {
        self._viewModel = State(initialValue: viewModel)
        self.onConfirm = onConfirm
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            VStack(alignment: .leading, spacing: 0) {
                WSSNavigationBar(title: "회원탈퇴") { dismiss() }

                Spacer().frame(height: 45)

                Text("정말 탈퇴하시겠어요?")
                    .applyWSSFont(.headline1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 8)
                
                Text("남겼던 평가와 기록들이 모두 사라져요..")
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 60)
                
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed((size.width - 46) / 2),
                                            spacing: statelItemSpacing),
                        count: stateColumnCount
                    ),
                    spacing: stateColumnSpacing
                ) {
                    statItem(
                        icon: WSSImage.icQuittingLike.swiftUIImage,
                        title: "관심",
                        count: viewModel.state.registeredNovelStats?.interest ?? 0
                    )
                    ForEach(ReadingStatus.allCases, id: \.statusName) { status in
                        statItem(
                            icon: status.strokeImage,
                            title: status.statusName,
                            count: registeredNovelCount(for: status)
                        )
                    }
                }

                Spacer()

                WSSCTAButton(title: "확인",
                             action: onConfirm)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .wssCustomNavigationBar()
        }
        .onAppear {
            viewModel.handle(.load)
        }
    }

    private func registeredNovelCount(for status: ReadingStatus) -> Int {
        guard let stats = viewModel.state.registeredNovelStats else { return 0 }
        switch status {
        case .watching: return stats.watching
        case .watched:  return stats.watched
        case .quit:     return stats.quit
        }
    }

    private func statItem(icon: Image, title: String, count: Int) -> some View {
        VStack(spacing: 0) {
            icon
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                .frame(width: 25, height: 25)

            Spacer().frame(height: 5)

            Text(title)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)

            Text("\(count)")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(WSSColor.wssPrimary20.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        WithdrawConfirmView(
            viewModel: WithdrawConfirmViewModel(
                loadRegisteredNovelStatsUseCase: PreviewLoadRegisteredNovelStatsUseCase()
            )
        )
    }
}

private struct PreviewLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}
