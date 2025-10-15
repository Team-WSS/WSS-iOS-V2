//
//  SearchView.swift
//  Search
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

import DesignSystem

public struct SearchView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("SearchView")
            
            WSSDropdown {
                print("SearchView")
            }
        }
    }
}

#Preview {
    SearchView()
}
