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
    var isSubmitting: Bool = false
    var externalFocus: FocusState<Bool>.Binding? = nil

    @FocusState private var internalFocus: Bool

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
                        .foregroundStyle(text.isEmpty ? WSSColor.wssGray100.swiftUIColor : WSSColor.wssPrimary100.swiftUIColor)
                        .frame(width: 42, height: 42)
                }
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty || isSubmitting)
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
