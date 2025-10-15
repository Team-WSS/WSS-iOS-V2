//
//  BaseCoordinator.swift
//  FeatureMain
//
//  Created by Seoyeon Choi on 10/15/25.
//

import Foundation
import SwiftUI

@Observable
public class BaseCoordinator<Route: Hashable, Sheet: Identifiable, FullScreenCover: Identifiable> {
    public var path: NavigationPath = .init()
    public var sheet: Sheet?
    public var fullScreenCover: FullScreenCover?
    var onDismiss: (() -> Void)?
    
    func push(route: Route) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func presentSheet(_ sheet: Sheet) {
        self.sheet = sheet
    }
    
    func presentFullScreenCover(_ cover: FullScreenCover) {
        self.fullScreenCover = cover
    }
    
    func dismissSheet() {
        self.sheet = nil
    }
    
    func dismissFullScreenCover() {
        self.fullScreenCover = nil
    }
}
