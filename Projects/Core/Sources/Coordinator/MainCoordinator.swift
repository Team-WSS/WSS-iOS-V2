//
//  MainCoordinator.swift
//  Core
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

import Home
import Search

final class WSSCoordinator: BaseCoordinator<WSSRoute, WSSSheet, WSSFullScreenCover> {
    @ViewBuilder
    func build(route: WSSRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .search: SearchView()
        }
    }
    
    @ViewBuilder
    func buildSheet(sheet: WSSSheet) -> some View {
        switch sheet {
        case .none: EmptyView()
        }
    }
    
    @ViewBuilder
    func buildFullScreenCover(cover: WSSFullScreenCover) -> some View {
        switch cover {
        case .none: EmptyView()
        }
    }
}
