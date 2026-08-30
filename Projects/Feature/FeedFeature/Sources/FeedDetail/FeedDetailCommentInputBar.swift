//
//  FeedDetailCommentInputBar.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

struct FeedDetailCommentInputBar: View {

    @Binding var text: String
    let profileImageURL: URL?
    let sendAction: () -> Void
    var isSubmitting: Bool = false
    /// 전송 버튼 활성 여부 — 호출자가 "내용이 비어있지 않고(수정 모드면) 원본과 다르다"를 계산해 넘긴다.
    /// 입력바는 이 값 하나로 아이콘 색·`disabled`를 정한다(무변경 재전송 가드 복원, #222).
    var isSendEnabled: Bool = true
    var externalFocus: FocusState<Bool>.Binding? = nil

    @FocusState private var internalFocus: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .foregroundStyle(WSSColor.wssGray100.swiftUIColor)

                if let profileImageURL {
                    AsyncImage(url: profileImageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .frame(width: 42, height: 42)

            Spacer().frame(width: 10)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text("댓글을 남겨주세요")
                                .applyWSSFont(.body3)
                                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                        }
                        
                        TextField("",
                                  text: $text,
                                  axis: .vertical)
                        .applyWSSFont(.body3)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                        .lineLimit(5)
                        .focused(externalFocus ?? $internalFocus)
                    }
                }
            }
            .padding(.vertical, 10.5)
            .padding(.horizontal, 16)
            .background(WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
            .onTapGesture {
                if let externalFocus {
                    externalFocus.wrappedValue = true
                } else {
                    internalFocus = true
                }
            }
            
            Spacer().frame(width: 1)
            
            Button {
                sendAction()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .frame(width: 42, height: 42)
                } else {
                    WSSImage.icCommentRegister.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(isSendEnabled ? WSSColor.wssPrimary100.swiftUIColor : WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 42, height: 42)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isSendEnabled || isSubmitting)
        }
        .padding(.leading, 20)
        .padding(.trailing, 7)
        .padding(.vertical, 17)
        .background(WSSColor.wssWhite.swiftUIColor)
    }
}

#Preview {
    @Previewable @State var text: String = ""
    FeedDetailCommentInputBar(text: $text,
                              profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
                              sendAction: { })
}
