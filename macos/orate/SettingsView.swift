//
//  SettingsView.swift
//  orate
//

import SwiftUI

// MARK: - Hotkey Recorder

@Observable
class HotkeyRecorder {
    static var isRecordingHotkey = false

    var isRecording = false
    var keyCode: UInt16
    private var flagMonitor: Any?
    private var keyMonitor: Any?

    init() {
        let stored = UserDefaults.standard.integer(forKey: "pushToTalkKeyCode")
        self.keyCode = stored > 0 ? UInt16(stored) : 61
    }

    func startRecording() {
        isRecording = true
        Self.isRecordingHotkey = true
        flagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.stopRecording()
                return nil
            }
            return event
        }
    }

    func stopRecording() {
        isRecording = false
        Self.isRecordingHotkey = false
        if let m = flagMonitor { NSEvent.removeMonitor(m) }
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        flagMonitor = nil
        keyMonitor = nil
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 58, 59, 60, 61, 62]
        guard modifierKeyCodes.contains(event.keyCode) else { return }

        // Capture on press (modifier flag going up), not release
        if let flag = Self.modifierFlag(for: event.keyCode), event.modifierFlags.contains(flag) {
            keyCode = event.keyCode
            UserDefaults.standard.set(Int(keyCode), forKey: "pushToTalkKeyCode")
            stopRecording()
        }
    }

    static func modifierFlag(for keyCode: UInt16) -> NSEvent.ModifierFlags? {
        switch keyCode {
        case 58, 61: return .option
        case 59, 62: return .control
        case 55, 54: return .command
        case 56, 60: return .shift
        default: return nil
        }
    }

    static func displayName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 58: return "Left Option ⌥"
        case 61: return "Right Option ⌥"
        case 59: return "Left Control ⌃"
        case 62: return "Right Control ⌃"
        case 55: return "Left Command ⌘"
        case 54: return "Right Command ⌘"
        case 56: return "Left Shift ⇧"
        case 60: return "Right Shift ⇧"
        default: return "Key \(keyCode)"
        }
    }
}

struct SettingsView: View {
    @State private var hotkeyRecorder = HotkeyRecorder()
    @State private var selectedProvider: AIProvider = {
        guard let raw = UserDefaults.standard.string(forKey: "aiProvider") else { return .orateCloud }
        return AIProvider(rawValue: raw) ?? .orateCloud
    }()
    @State private var apiKey: String = ""
    @State private var vertexProjectID: String = ""
    @State private var vertexRegion: String = ""
    @State private var saved = false
    @State private var showKey = false

    private var keychainKey: String {
        switch selectedProvider {
        case .orateCloud: "orateCloudAPIKey"
        case .googleAI: "geminiAPIKey"
        case .vertexAI: "vertexAPIKey"
        }
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
                hotkeySection
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

    // MARK: - Push-to-Talk Hotkey

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Push-to-Talk Key")
                .font(.headline)

            Text("Hold this key to record, release to transcribe. Click the button below and press a modifier key to change it.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button {
                if hotkeyRecorder.isRecording {
                    hotkeyRecorder.stopRecording()
                } else {
                    hotkeyRecorder.startRecording()
                }
            } label: {
                HStack {
                    Image(systemName: hotkeyRecorder.isRecording ? "record.circle" : "keyboard")
                        .foregroundStyle(hotkeyRecorder.isRecording ? .red : .secondary)

                    if hotkeyRecorder.isRecording {
                        Text("Press a modifier key...")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(HotkeyRecorder.displayName(for: hotkeyRecorder.keyCode))
                    }

                    Spacer()

                    if hotkeyRecorder.isRecording {
                        Text("ESC to cancel")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(10)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hotkeyRecorder.isRecording ? AnyShapeStyle(Color.accentColor.opacity(0.1)) : AnyShapeStyle(.quaternary.opacity(0.5)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(hotkeyRecorder.isRecording ? Color.accentColor : .clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            Label("Supported keys: Option, Control, Command, Shift (left or right).", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Provider Picker

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Provider")
                .font(.headline)

            Text("Choose where to send your audio for transcription.")
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

            switch selectedProvider {
            case .orateCloud:
                Text("Orate Cloud is the easiest way to get started. Enter your API key below to start transcribing.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .googleAI:
                Text("Orate uses Google's Gemini API to transcribe your audio. You'll need an API key from Google AI Studio.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                    Label("Get your API key from Google AI Studio", systemImage: "arrow.up.right.square")
                        .font(.callout)
                }
            case .vertexAI:
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
