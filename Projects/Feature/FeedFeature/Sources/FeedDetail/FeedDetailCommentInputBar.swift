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
    let sendAction: () -> Void
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 14)
                .frame(width: 42, height: 42)
                .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
            
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
                        .lineLimit(1)
                        .focused($isKeyboardFocused)
                    }
                }
            }
            .padding(.vertical, 10.5)
            .padding(.horizontal, 16)
            .background(WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
            .onTapGesture {
                isKeyboardFocused = true
            }
            
            Spacer().frame(width: 1)
            
            Button {
                sendAction()
            } label: {
                WSSImage.icCommentRegister.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(text.isEmpty ? WSSColor.wssGray100.swiftUIColor : WSSColor.wssPrimary100.swiftUIColor)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
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
                              sendAction: { })
}
