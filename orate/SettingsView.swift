//
//  SettingsView.swift
//  orate
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var saved = false
    @State private var showKey = false

    private let keychainKey = "geminiAPIKey"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                apiKeySection
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            apiKey = KeychainHelper.read(key: keychainKey) ?? ""
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configure your API credentials and preferences.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Google AI Studio API Key")
                .font(.headline)

            Text("Orate uses Google's Gemini API to transcribe your audio. You'll need an API key from Google AI Studio.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                Label("Get your API key from Google AI Studio", systemImage: "arrow.up.right.square")
                    .font(.callout)
            }

            HStack(spacing: 8) {
                Group {
                    if showKey {
                        TextField("Paste your API key here", text: $apiKey)
                    } else {
                        SecureField("Paste your API key here", text: $apiKey)
                    }
                }
                .textFieldStyle(.plain)
                .font(.body.monospaced())
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(showKey ? "Hide API key" : "Show API key")
            }

            HStack {
                Button("Save") {
                    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        KeychainHelper.delete(key: keychainKey)
                    } else {
                        KeychainHelper.save(key: keychainKey, value: trimmed)
                    }
                    apiKey = trimmed
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { saved = false }
                    }
                }
                .buttonStyle(.borderedProminent)

                if saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .transition(.opacity)
                }

                Spacer()

                if !apiKey.isEmpty {
                    Button("Remove") {
                        apiKey = ""
                        KeychainHelper.delete(key: keychainKey)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Label("Your API key is stored securely in the macOS Keychain.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
