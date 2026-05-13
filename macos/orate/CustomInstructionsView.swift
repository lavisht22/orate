//
//  CustomInstructionsView.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import SwiftUI

struct CustomInstructionsView: View {
    @State private var instructions: String = UserDefaults.standard.string(forKey: "customInstructions") ?? ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                instructionsEditor
                examples
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Instructions")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Tell Orate about yourself and how you'd like your transcriptions formatted. These instructions are included with every transcription request.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Editor

    private var instructionsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $instructions)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 180)

            HStack {
                Button("Save") {
                    UserDefaults.standard.set(instructions, forKey: "customInstructions")
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

                if !instructions.isEmpty {
                    Button("Clear") {
                        instructions = ""
                        UserDefaults.standard.removeObject(forKey: "customInstructions")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Examples

    private var examples: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Examples")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                exampleRow("I'm a doctor. Use proper medical terminology (e.g. \"myocardial infarction\" instead of \"heart attack\").")
                exampleRow("I write code. Format technical terms in lowercase (e.g. \"kubernetes\", \"nginx\"). Spell out variable-style names as spoken.")
                exampleRow("I speak with filler words. Remove \"um\", \"uh\", \"like\", and \"you know\" from my speech.")
                exampleRow("I dictate in Spanish but want transcriptions in English.")
                exampleRow("Always use Oxford commas and American English spelling.")
            }
        }
    }

    private func exampleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb")
                .foregroundStyle(.yellow)
                .font(.caption)
                .padding(.top, 2)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            instructions = text
        }
    }
}
