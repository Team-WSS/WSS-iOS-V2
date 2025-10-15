//
//  WSSRoutingView.swift
//  Core
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

public struct WSSRoutingView: View {
    @State var coordinator: WSSCoordinator = .init()
    
    public init() { }
    
    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(route: .home)
                .navigationDestination(for: WSSRoute.self) { view in
                    coordinator.build(route: view)
                }
                .sheet(item: $coordinator.sheet) { sheet in
                    coordinator.buildSheet(sheet: sheet)
                }
                .fullScreenCover(item: $coordinator.fullScreenCover) { cover in
                    coordinator.buildFullScreenCover(cover: cover)
                }
        }
        .environment(coordinator)
    }
}
