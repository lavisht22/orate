//
//  OnboardingView.swift
//  orate
//

import AVFoundation
import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var micGranted = false
    @State private var accessibilityGranted = TextInserter.isAccessibilityGranted
    @State private var apiKey = ""
    @State private var showKey = false
    @State private var accessibilityTimer: Timer?

    var onComplete: () -> Void

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            progressIndicator
                .padding(.top, 32)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: microphoneStep
                case 2: accessibilityStep
                case 3: apiKeyStep
                case 4: doneStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: 480)

            Spacer()

            // Navigation buttons
            navigationButtons
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Orate")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Hold a key, speak, release — your words appear as text wherever you're typing.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Microphone Step

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(micGranted ? .green : .accentColor)

            Text("Microphone Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Orate needs access to your microphone to record your speech for transcription.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if micGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button("Grant Microphone Access") {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        DispatchQueue.main.async {
                            micGranted = granted
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .onAppear {
            // Check if already granted
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                micGranted = true
            default:
                break
            }
        }
    }

    // MARK: - Accessibility Step

    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "accessibility.fill")
                .font(.system(size: 56))
                .foregroundStyle(accessibilityGranted ? .green : .accentColor)

            Text("Accessibility Permission")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Orate needs accessibility access to paste transcribed text into the app you're using.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if accessibilityGranted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button("Open Accessibility Settings") {
                    TextInserter.promptForAccessibility()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("After enabling Orate in System Settings, this screen will update automatically.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            startAccessibilityPolling()
        }
        .onDisappear {
            stopAccessibilityPolling()
        }
    }

    // MARK: - API Key Step

    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("API Key")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Orate uses Google's Gemini API to transcribe your audio. You'll need a free API key from Google AI Studio.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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
            }
            .frame(maxWidth: 400)

            Label("Your API key is stored securely in the macOS Keychain.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Label("Looking for Vertex AI? Skip this step and configure it later in Settings.", systemImage: "arrow.right.circle")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Done Step

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(icon: "1.circle.fill", text: "Hold **Right Option (⌥)** to start recording")
                instructionRow(icon: "2.circle.fill", text: "Speak naturally — Orate cleans up your speech")
                instructionRow(icon: "3.circle.fill", text: "Release the key and the text appears where you're typing")
            }
            .padding(20)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func instructionRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()

            switch currentStep {
            case 0:
                Button("Get Started") {
                    withAnimation { currentStep = 1 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            case 1:
                Button("Continue") {
                    withAnimation { currentStep = 2 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!micGranted)

            case 2:
                Button("Continue") {
                    withAnimation { currentStep = 3 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!accessibilityGranted)

            case 3:
                HStack(spacing: 12) {
                    if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Skip for Now") {
                            withAnimation { currentStep = 4 }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    Button("Continue") {
                        saveAPIKey()
                        withAnimation { currentStep = 4 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

            case 4:
                Button("Start Using Orate") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private func startAccessibilityPolling() {
        accessibilityGranted = TextInserter.isAccessibilityGranted
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let granted = TextInserter.isAccessibilityGranted
            if granted != accessibilityGranted {
                accessibilityGranted = granted
            }
        }
    }

    private func stopAccessibilityPolling() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = nil
    }

    private func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainHelper.save(key: "geminiAPIKey", value: trimmed)
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}
