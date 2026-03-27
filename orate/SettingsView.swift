//
//  SettingsView.swift
//  orate
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedProvider: AIProvider = {
        guard let raw = UserDefaults.standard.string(forKey: "aiProvider") else { return .googleAI }
        return AIProvider(rawValue: raw) ?? .googleAI
    }()
    @State private var apiKey: String = ""
    @State private var vertexProjectID: String = ""
    @State private var vertexRegion: String = ""
    @State private var saved = false
    @State private var showKey = false

    private var keychainKey: String {
        selectedProvider == .googleAI ? "geminiAPIKey" : "vertexAPIKey"
    }

    private static let vertexRegions = [
        "global",
        "us-central1",
        "us-east4",
        "us-west1",
        "europe-west1",
        "europe-west4",
        "asia-northeast1",
        "asia-southeast1",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                providerPicker
                apiKeySection
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        apiKey = KeychainHelper.read(key: keychainKey) ?? ""
        vertexProjectID = UserDefaults.standard.string(forKey: "vertexProjectID") ?? ""
        vertexRegion = UserDefaults.standard.string(forKey: "vertexRegion") ?? "us-central1"
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

    // MARK: - Provider Picker

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Provider")
                .font(.headline)

            Text("Choose where to send your audio for transcription. Both use the same Gemini model.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Picker(selection: $selectedProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .fixedSize()

                Spacer()
            }
            .onChange(of: selectedProvider) {
                // Reload API key for the new provider
                apiKey = KeychainHelper.read(key: keychainKey) ?? ""
                showKey = false
                saved = false
            }
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(selectedProvider.displayName) API Key")
                .font(.headline)

            if selectedProvider == .googleAI {
                Text("Orate uses Google's Gemini API to transcribe your audio. You'll need an API key from Google AI Studio.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                    Label("Get your API key from Google AI Studio", systemImage: "arrow.up.right.square")
                        .font(.callout)
                }
            } else {
                Text("Use Vertex AI for transcription through your Google Cloud project. You'll need an API key from the GCP console with Vertex AI access.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://console.cloud.google.com/apis/credentials")!) {
                    Label("Create an API key in Google Cloud Console", systemImage: "arrow.up.right.square")
                        .font(.callout)
                }

                vertexConfigSection
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
                    saveSettings()
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

    // MARK: - Vertex AI Config

    private var vertexConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Project ID")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("your-gcp-project-id", text: $vertexProjectID)
                    .textFieldStyle(.plain)
                    .font(.body.monospaced())
                    .padding(10)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Region")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Region", selection: $vertexRegion) {
                    ForEach(Self.vertexRegions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }

    private func saveSettings() {
        // Save provider choice
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "aiProvider")

        // Save API key
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainHelper.delete(key: keychainKey)
        } else {
            KeychainHelper.save(key: keychainKey, value: trimmed)
        }
        apiKey = trimmed

        // Save Vertex AI config
        if selectedProvider == .vertexAI {
            UserDefaults.standard.set(vertexProjectID.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "vertexProjectID")
            UserDefaults.standard.set(vertexRegion, forKey: "vertexRegion")
        }

        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}
