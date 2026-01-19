//
//  DeviceWordLibraryView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import SwiftUI
import SwiftData

struct DeviceWordLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var words: [Word]
    @Query private var lexiconEntries: [UserLexiconEntry]

    @State private var showOnlyNotInLexicon = true
    @State private var searchText = ""

    private var lexiconIDs: Set<Word.ID> {
        Set(lexiconEntries.compactMap { $0.word?.id })
    }

    private var filteredWords: [Word] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return words
            .filter { word in
                let matchesSearch = trimmed.isEmpty ||
                word.spellingText.localizedCaseInsensitiveContains(trimmed) ||
                word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
                let matchesLexicon = !showOnlyNotInLexicon || !lexiconIDs.contains(word.id)
                return matchesSearch && matchesLexicon
            }
            .sorted {
                let left = $0.spellingText.localizedCaseInsensitiveCompare($1.spellingText)
                if left != .orderedSame {
                    return left == .orderedAscending
                }
                let right = $0.partOfSpeech.localizedCaseInsensitiveCompare($1.partOfSpeech)
                return right == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredWords.isEmpty {
                    ContentUnavailableView(
                        "No Words",
                        systemImage: "books.vertical",
                        description: Text("Try changing the filter.")
                    )
                } else {
                    ForEach(filteredWords) { word in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(word.spellingText)
                                    .font(.headline)
                                Text(word.partOfSpeech)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if lexiconIDs.contains(word.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Add") {
                                    addToLexicon(word)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Word Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 8) {
                    Toggle("Only show words not in my lexicon", isOn: $showOnlyNotInLexicon)
                        .padding(.horizontal)
                    Divider()
                }
                .background(.ultraThinMaterial)
            }
            .searchable(text: $searchText, prompt: "Search words")
        }
    }

    private func addToLexicon(_ word: Word) {
        guard !lexiconIDs.contains(word.id) else { return }
        let wordID = word.persistentModelID.storeIdentifier ?? ""
        guard !wordID.isEmpty else { return }
        let entry = UserLexiconEntry(wordID: wordID, word: word)
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
