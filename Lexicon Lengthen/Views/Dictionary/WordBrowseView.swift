//
//  WordBrowseView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct WordBrowseView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var lexiconEntries: [UserLexiconEntry]

    @State private var useRandomOrder = false
    @State private var useUppercase = false
    @State private var randomOrder: [Word.ID] = []
    @State private var currentWordID: Word.ID?

    private var lexiconWords: [Word] {
        lexiconEntries.compactMap { $0.word }
    }

    private var sortedWordIDs: [Word.ID] {
        lexiconWords
            .sorted {
                let left = $0.spellingText.localizedCaseInsensitiveCompare($1.spellingText)
                if left != .orderedSame {
                    return left == .orderedAscending
                }
                let right = $0.partOfSpeech.localizedCaseInsensitiveCompare($1.partOfSpeech)
                return right == .orderedAscending
            }
            .map(\.id)
    }

    private var wordsByID: [Word.ID: Word] {
        Dictionary(uniqueKeysWithValues: lexiconWords.map { ($0.id, $0) })
    }

    private var activeOrder: [Word.ID] {
        useRandomOrder ? randomOrder : sortedWordIDs
    }

    private var currentWord: Word? {
        guard !activeOrder.isEmpty else { return nil }
        let id = currentWordID ?? activeOrder.first
        guard let resolvedID = id else { return nil }
        return wordsByID[resolvedID]
    }

    private var currentIndex: Int {
        guard let id = currentWordID,
              let index = activeOrder.firstIndex(of: id) else {
            return 0
        }
        return index
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let word = currentWord {
                    Text(displayText(for: word))
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)

                    Text(word.partOfSpeech)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(currentIndex + 1) of \(activeOrder.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ContentUnavailableView(
                        "No Words Yet",
                        systemImage: "textformat",
                        description: Text("Add words to begin browsing.")
                    )
                }

                Picker("Order", selection: $useRandomOrder) {
                    Text("In Order").tag(false)
                    Text("Random").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button {
                    useUppercase.toggle()
                } label: {
                    Text(useUppercase ? "Lowercase" : "Uppercase")
                }
                .buttonStyle(.bordered)
                .disabled(currentWord == nil)

                HStack(spacing: 16) {
                    Button {
                        move(by: -1)
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentWord == nil)

                    Button {
                        move(by: 1)
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentWord == nil)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Browse Words")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                syncCurrentWord(with: sortedWordIDs)
                if useRandomOrder {
                    rebuildRandomOrder(from: sortedWordIDs)
                }
            }
            .onChange(of: sortedWordIDs) { _, newValue in
                if useRandomOrder {
                    rebuildRandomOrder(from: newValue)
                } else {
                    syncCurrentWord(with: newValue)
                }
            }
            .onChange(of: useRandomOrder) { _, isRandom in
                if isRandom {
                    rebuildRandomOrder(from: sortedWordIDs)
                } else {
                    syncCurrentWord(with: sortedWordIDs)
                }
            }
        }
    }

    private func displayText(for word: Word) -> String {
        let spelling = word.spellingText
        return useUppercase ? spelling.uppercased() : spelling.lowercased()
    }

    private func move(by step: Int) {
        guard !activeOrder.isEmpty else { return }
        let index = currentIndex
        var newIndex = index + step
        if newIndex < 0 {
            newIndex = activeOrder.count - 1
        } else if newIndex >= activeOrder.count {
            newIndex = 0
        }
        currentWordID = activeOrder[newIndex]
    }

    private func syncCurrentWord(with ids: [Word.ID]) {
        guard !ids.isEmpty else {
            currentWordID = nil
            return
        }
        if let current = currentWordID, ids.contains(current) {
            return
        }
        currentWordID = ids.first
    }

    private func rebuildRandomOrder(from ids: [Word.ID]) {
        guard !ids.isEmpty else {
            randomOrder = []
            currentWordID = nil
            return
        }

        var pool = ids
        if let current = currentWordID, let index = pool.firstIndex(of: current) {
            pool.remove(at: index)
            pool.shuffle()
            randomOrder = [current] + pool
        } else {
            randomOrder = ids.shuffled()
        }
        syncCurrentWord(with: randomOrder)
    }
}
