//
//  WSSFeadView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

public struct WSSFeadView: View {
    public var body: some View {
        VStack(spacing: 0) {
            WSSFeadHeaderView(
                profileImageURL: <#T##URL?#>,
                nickname: <#T##String#>,
                createdDate: <#T##String#>,
                isEdited: <#T##Bool#>
            )
            
            LinkNovelView(
                genreType: <#T##LinkNovelGenreType#>,
                novelTitle: <#T##String#>,
                novelRating: <#T##Float#>
            )
            
            WSSFeedReactView(
                likeCount: <#T##Int#>,
                commentCount: <#T##Int#>
            )
        }
    }
}
