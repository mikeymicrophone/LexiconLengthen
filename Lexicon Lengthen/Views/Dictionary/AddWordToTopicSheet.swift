//
//  AddWordToTopicSheet.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct AddWordToTopicSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]

    let topic: Topic

    @State private var searchText = ""

    var filteredWords: [Word] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let list = words.sorted { $0.spellingText.localizedCaseInsensitiveCompare($1.spellingText) == .orderedAscending }
        guard !trimmed.isEmpty else { return list }
        return list.filter { $0.spellingText.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List(filteredWords) { word in
                Button {
                    addWord(word)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(word.spellingText)
                                .font(.headline)
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isAssigned(word) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isAssigned(word))
            }
            .navigationTitle("Add Words")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search words")
        }
    }

    private func isAssigned(_ word: Word) -> Bool {
        topic.wordTopics.contains { $0.word == word }
    }

    private func addWord(_ word: Word) {
        guard !isAssigned(word) else { return }
        let link = WordTopic(word: word, topic: topic)
        modelContext.insert(link)
        try? modelContext.save()
    }
}
