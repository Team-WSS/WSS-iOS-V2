//
//  MainCoordinator.swift
//  Core
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

import Home
import Search

public final class WSSCoordinator: BaseCoordinator<WSSRoute, WSSSheet, WSSFullScreenCover> {
    
    public override init() {}
    
    @ViewBuilder
    public func build(route: WSSRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .search: SearchView()
        }
    }
    
    @ViewBuilder
    public func buildSheet(sheet: WSSSheet) -> some View {
        switch sheet {
        case .none: EmptyView()
        }
    }
    
    @ViewBuilder
    public func buildFullScreenCover(cover: WSSFullScreenCover) -> some View {
        switch cover {
        case .none: EmptyView()
        }
    }
}
