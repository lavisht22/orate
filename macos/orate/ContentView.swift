//
//  ContentView.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AVFoundation
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case instructions = "Instructions"
    case vocabulary = "Vocabulary"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: "house"
        case .instructions: "text.quote"
        case .vocabulary: "character.book.closed"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selection {
            case .home:
                HomeView()
            case .instructions:
                CustomInstructionsView()
            case .vocabulary:
                VocabularyView()
            case .settings:
                SettingsView()
            case nil:
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var recordings: [RecordingMetadata] = []
    @State private var playingID: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var clearMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                welcomeHeader
                    .padding(.bottom, 8)

                if recordings.isEmpty {
                    emptyState
                } else {
                    recordingsList
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { recordings = RecordingStore.loadAll() }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to Orate")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Hold **Right Option (⌥)** and speak. Release to transcribe.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No transcriptions yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Hold Right Option to start your first recording.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transcriptions")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button("Older than 7 days") { clearRecordings(olderThan: 7) }
                    Button("Older than 14 days") { clearRecordings(olderThan: 14) }
                    Button("Older than 30 days") { clearRecordings(olderThan: 30) }
                    Divider()
                    Button("All Recordings", role: .destructive) { clearRecordings(olderThan: nil) }
                } label: {
                    Text("Clear")
                }
                .buttonStyle(.bordered)

                if let clearMessage {
                    Label(clearMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .transition(.opacity)
                }
            }

            ForEach(recordings, id: \.id) { recording in
                recordingRow(recording)
            }
        }
    }

    private func clearRecordings(olderThan days: Int?) {
        let countBefore = recordings.count
        RecordingStore.deleteRecordings(olderThan: days)
        recordings = RecordingStore.loadAll()
        let deleted = countBefore - recordings.count

        if deleted > 0 {
            withAnimation { clearMessage = "\(deleted) recording\(deleted == 1 ? "" : "s") cleared" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { clearMessage = nil }
            }
        } else {
            withAnimation { clearMessage = "No recordings to clear" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { clearMessage = nil }
            }
        }
    }

    private func recordingRow(_ recording: RecordingMetadata) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Transcript
            Text(recording.transcript)
                .font(.body)
                .textSelection(.enabled)

            // Bottom bar: actions + metadata
            HStack(spacing: 12) {
                // Play button
                Button {
                    togglePlayback(recording)
                } label: {
                    Image(systemName: playingID == recording.id ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(playingID == recording.id ? .red : .accentColor)
                }
                .buttonStyle(.plain)
                .help(playingID == recording.id ? "Stop" : "Play")

                // Copy button
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(recording.transcript, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy transcript")

                Divider()
                    .frame(height: 14)

                // Timestamp
                Label(recording.timestamp.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Latency
                Label("\(recording.latencyMs)ms", systemImage: "bolt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Word count
                Label("\(recording.transcript.split(separator: /\s+/).count) words", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Playback

    private func togglePlayback(_ recording: RecordingMetadata) {
        if playingID == recording.id {
            audioPlayer?.stop()
            playingID = nil
            return
        }

        let audioURL = RecordingStore.recordingsDirectory.appendingPathComponent(recording.audioFile)
        guard let player = try? AVAudioPlayer(contentsOf: audioURL) else { return }

        audioPlayer?.stop()
        audioPlayer = player
        playingID = recording.id
        player.play()

        // Reset when done
        DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
            if playingID == recording.id {
                playingID = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
