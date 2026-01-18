//
//  TopicDetailView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct TopicDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let topic: Topic
    @State private var showingAddWord = false
    @State private var isGeneratingSuggestions = false
    @State private var suggestionError: String?
    @State private var lastSuggestions: [TopicWordSuggestion] = []

    var body: some View {
        List {
            Section("Suggestions") {
                Button {
                    suggestWords()
                } label: {
                    HStack {
                        Text("Suggest 4 Words")
                        Spacer()
                        if isGeneratingSuggestions {
                            ProgressView()
                        }
                    }
                }
                .disabled(isGeneratingSuggestions)

                if let suggestionError {
                    Text(suggestionError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !lastSuggestions.isEmpty {
                    ForEach(lastSuggestions.indices, id: \.self) { index in
                        let suggestion = lastSuggestions[index]
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(suggestion.word) • \(suggestion.partOfSpeech)")
                                .font(.headline)
                            Text(suggestion.definition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Words") {
                if topic.wordTopics.isEmpty {
                    ContentUnavailableView(
                        "No Words Yet",
                        systemImage: "text.book.closed",
                        description: Text("Add words to start building this topic.")
                    )
                } else {
                    ForEach(topic.wordTopics) { link in
                        if let word = link.word {
                            HStack {
                                Text(word.spellingText)
                                    .font(.headline)
                                Text(word.partOfSpeech)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteWords)
                }
            }
        }
        .navigationTitle(topic.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddWord = true
                } label: {
                    Label("Add Word", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordToTopicSheet(topic: topic)
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(topic.wordTopics[index])
        }
        try? modelContext.save()
    }

    private func suggestWords() {
        suggestionError = nil
        isGeneratingSuggestions = true

        Task {
            do {
                let suggestions = try await TopicWordSuggestionService.shared.suggestWords(for: topic.name)
                await MainActor.run {
                    lastSuggestions = suggestions
                    applySuggestions(suggestions)
                    isGeneratingSuggestions = false
                }
            } catch {
                await MainActor.run {
                    suggestionError = error.localizedDescription
                    isGeneratingSuggestions = false
                }
            }
        }
    }

    @MainActor
    private func applySuggestions(_ suggestions: [TopicWordSuggestion]) {
        let descriptor = FetchDescriptor<Spelling>()
        let existingSpellings = (try? modelContext.fetch(descriptor)) ?? []
        var spellingByLower = Dictionary(uniqueKeysWithValues: existingSpellings.map { ($0.textLowercase, $0) })

        for suggestion in suggestions {
            let spellingText = suggestion.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !spellingText.isEmpty else { continue }

            let spellingLower = spellingText.lowercased()
            let spelling = spellingByLower[spellingLower] ?? Spelling(text: spellingText)
            if spelling.modelContext == nil {
                modelContext.insert(spelling)
                spellingByLower[spellingLower] = spelling
            }

            let partOfSpeech = suggestion.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedPartOfSpeech = partOfSpeech.isEmpty ? "noun" : partOfSpeech
            let existingWord = spelling.words.first {
                $0.partOfSpeech.caseInsensitiveCompare(resolvedPartOfSpeech) == .orderedSame
            }
            let word = existingWord ?? Word(spelling: spelling, partOfSpeech: resolvedPartOfSpeech)
            if word.modelContext == nil {
                modelContext.insert(word)
            }

            let definitionText = suggestion.definition.trimmingCharacters(in: .whitespacesAndNewlines)
            if !definitionText.isEmpty {
                let alreadyHasDefinition = word.definitions.contains { $0.definitionText == definitionText }
                if !alreadyHasDefinition {
                    let definition = Definition(
                        word: word,
                        definitionText: definitionText,
                        sortOrder: word.definitions.count
                    )
                    modelContext.insert(definition)
                }
            }

            let alreadyLinked = topic.wordTopics.contains { $0.word == word }
            if !alreadyLinked {
                let link = WordTopic(word: word, topic: topic)
                modelContext.insert(link)
            }
        }

        try? modelContext.save()
    }
}
