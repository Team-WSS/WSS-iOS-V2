//
//  HomeView.swift
//  Home
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

import DesignSystem

public struct HomeView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("안녕하세요반갑습니다제일")
                .wssFont(.body1)
                .foregroundStyle(WSSColor.primary100)
            
            WSSDropdown {
                print("dropdown")
            }
        }
    }
}

#Preview {
    HomeView()
}
