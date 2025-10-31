//
//  NetworkDemoView.swift
//  NetworkDemo
//
//  Created by YunhakLee on 10/30/25.
//

import SwiftUI
import Networking

struct NetworkDemoView: View {
    @State private var log: String = ""
    private let network: NetworkingRequestable = NetworkingClient()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("🔍 GET Post") {
                    Task { await performGet() }
                }
                .buttonStyle(.borderedProminent)
                
                Button("📝 POST New Post") {
                    Task { await performPost() }
                }
                .buttonStyle(.bordered)
                
                ScrollView {
                    Text(log)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            }
            .padding()
            .navigationTitle("🌐 Network Demo")
        }
    }
    
    private func performGet() async {
        do {
            let result: Post = try await network.request(
                MockEndpoint.getPost(id: 1),
                decodeTo: Post.self
            )
            log = "✅ GET Success:\n\(result)"
        } catch {
            log = "❌ GET Failed:\n\(error)"
        }
    }
    
    private func performPost() async {
        do {
            let result: Post = try await network.request(
                MockEndpoint.createPost(title: "Hello", body: "World"),
                decodeTo: Post.self
            )
            log = "✅ POST Success:\n\(result)"
        } catch {
            log = "❌ POST Failed:\n\(error)"
        }
    }
}
