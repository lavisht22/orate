//
//  VocabularyView.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import SwiftUI

struct VocabularyView: View {
    @State private var words: [String] = Self.loadWords()
    @State private var newWord: String = ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                addWordField
                if words.isEmpty {
                    emptyState
                } else {
                    wordsList
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vocabulary")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Add custom words so Orate spells them correctly — names, brands, technical terms, or anything unique to you.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Add Word Field

    private var addWordField: some View {
        HStack(spacing: 12) {
            TextField("Add a word (e.g. mytribe, Kubernetes, LangChain)", text: $newWord)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .onSubmit { addWord() }

            Button("Add") { addWord() }
                .buttonStyle(.borderedProminent)
                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if saved {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No custom words yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add words that Orate should recognize and spell correctly.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Words List

    private var wordsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Custom Words")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(words.count) word\(words.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            FlowLayout(spacing: 8) {
                ForEach(words, id: \.self) { word in
                    wordChip(word)
                }
            }
        }
    }

    private func wordChip(_ word: String) -> some View {
        HStack(spacing: 6) {
            Text(word)
                .font(.body)
            Button {
                removeWord(word)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }

    // MARK: - Actions

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !words.contains(where: { $0.lowercased() == trimmed.lowercased() }) else {
            newWord = ""
            return
        }
        words.append(trimmed)
        newWord = ""
        saveWords()
    }

    private func removeWord(_ word: String) {
        words.removeAll { $0 == word }
        saveWords()
    }

    private func saveWords() {
        UserDefaults.standard.set(words, forKey: "vocabularyWords")
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }

    static func loadWords() -> [String] {
        UserDefaults.standard.stringArray(forKey: "vocabularyWords") ?? []
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
