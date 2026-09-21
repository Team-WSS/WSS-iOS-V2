//
//  ContentView.swift
//  KeychainDemo
//
//  Created by YunhakLee on 10/22/25.
//
import SwiftUI
import Keychain

struct ContentView: View {
    @State private var key = "demoKey"
    @State private var value = ""
    @State private var message = ""
    
    private let keychain = KeychainClient() // 실제 Keychain 모듈 사용
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Keychain Input") {
                    TextField("Key", text: $key)
                    TextField("Value", text: $value)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Actions") {
                    Button("Create") { perform(.create) }
                    Button("Read") { perform(.read) }
                    Button("Update") { perform(.update) }
                    Button("Delete") { perform(.delete) }
                }
                
                if !message.isEmpty {
                    Section("Result") {
                        Text(message)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("🔐 Keychain Demo")
        }
    }
    
    private enum Action {
        case create, read, update, delete
    }
    
    private func perform(_ action: Action) {
        do {
            switch action {
            case .create:
                try keychain.create(value: value, forKey: key)
                showMessage("✅ Created value for key: \(key)")
                
            case .read:
                if let result = try keychain.value(forKey: key) {
                    showMessage("📦 Read value: \(result)")
                    value = result
                } else {
                    showMessage("❌ No value found for key: \(key)")
                }
                
            case .update:
                try keychain.update(value: value, forKey: key)
                showMessage("🔄 Updated value for key: \(key)")
                
            case .delete:
                try keychain.delete(forKey: key)
                showMessage("🗑️ Deleted value for key: \(key)")
            }
        } catch let error as KeychainError {
            showMessage(error.description)
        } catch {
            showMessage("❗️Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func showMessage(_ text: String) {
        withAnimation {
            message = text
        }
    }
}


