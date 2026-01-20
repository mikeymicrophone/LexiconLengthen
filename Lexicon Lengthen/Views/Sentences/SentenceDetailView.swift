//
//  SentenceDetailView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/20/26.
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct SentenceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lexiconEntries: [UserLexiconEntry]

    let sentence: UserSentence

    @StateObject private var narrator = SentenceWordNarrator()
    @State private var suggestions: [SuggestedWord] = []
    @State private var isLoadingSuggestions = false
    @State private var statusMessage: String?

    private var tokens: [String] {
        sentence.sentenceText
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    private var highlightedSentence: Text {
        var result = AttributedString()
        for (index, token) in tokens.enumerated() {
            if index > 0 {
                result.append(AttributedString(" "))
            }
            var piece = AttributedString(token)
            if index == narrator.currentTokenIndex {
                piece.font = .system(.title3, weight: .bold)
            }
            result.append(piece)
        }
        return Text(result)
    }

    var body: some View {
        List {
            Section("Sentence") {
                highlightedSentence
                    .font(.title3)
                    .multilineTextAlignment(.leading)

                Button {
                    if narrator.isNarrating {
                        narrator.stop()
                    } else {
                        narrator.start(tokens: tokens)
                    }
                } label: {
                    Label(
                        narrator.isNarrating ? "Stop Narration" : "Narrate Words",
                        systemImage: narrator.isNarrating ? "stop.circle.fill" : "speaker.wave.2.fill"
                    )
                }
                .buttonStyle(.bordered)
            }

            Section("Suggestions") {
                Button {
                    suggestWords()
                } label: {
                    if isLoadingSuggestions {
                        Label("Suggesting...", systemImage: "sparkles")
                    } else {
                        Label("Suggest 10 Words", systemImage: "sparkles")
                    }
                }
                .disabled(isLoadingSuggestions)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if suggestions.isEmpty {
                    ContentUnavailableView(
                        "No Suggestions Yet",
                        systemImage: "sparkles",
                        description: Text("Generate suggestions based on this sentence.")
                    )
                } else {
                    ForEach(suggestions) { suggestion in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.word.spellingText)
                                    .font(.headline)
                                Text(suggestion.word.partOfSpeech)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !suggestion.definition.isEmpty {
                                    Text(suggestion.definition)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if isInLexicon(suggestion.word) {
                                Text("In Lexicon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Button("Add") {
                                    addToLexicon(suggestion.word)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Sentence")
        .onDisappear {
            narrator.stop()
        }
    }

    private func suggestWords() {
        guard !isLoadingSuggestions else { return }
        isLoadingSuggestions = true
        statusMessage = nil

        Task {
            let results = await SentenceWordSuggestionService.suggestWords(for: sentence.sentenceText)
            await MainActor.run {
                applySuggestions(results)
                isLoadingSuggestions = false
            }
        }
    }

    private func applySuggestions(_ results: [SentenceWordSuggestion]) {
        var created: [SuggestedWord] = []
        var seen = Set<Word.ID>()
        let existingLower = Set(wordsOnDeviceLowercased())

        for result in results {
            let candidate = result.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if existingLower.contains(candidate) {
                continue
            }
            guard let word = upsertWord(from: result) else { continue }
            if seen.contains(word.id) { continue }
            seen.insert(word.id)
            created.append(SuggestedWord(word: word, definition: result.definition))
        }

        suggestions = created
        statusMessage = "Added \(created.count) words to your device."
    }

    private func wordsOnDeviceLowercased() -> [String] {
        let descriptor = FetchDescriptor<Spelling>()
        let spellings = (try? modelContext.fetch(descriptor)) ?? []
        return spellings.map { $0.textLowercase }
    }

    private func upsertWord(from suggestion: SentenceWordSuggestion) -> Word? {
        let spellingText = suggestion.word.trimmingCharacters(in: .whitespacesAndNewlines)
        let partOfSpeech = suggestion.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        let definitionText = suggestion.definition.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !spellingText.isEmpty else { return nil }
        let pos = partOfSpeech.isEmpty ? "noun" : partOfSpeech
        let lower = spellingText.lowercased()

        let spellingDescriptor = FetchDescriptor<Spelling>(
            predicate: #Predicate { $0.textLowercase == lower }
        )
        let spelling = (try? modelContext.fetch(spellingDescriptor))?.first ?? Spelling(text: spellingText)
        if spelling.modelContext == nil {
            modelContext.insert(spelling)
        }

        let existingWord = spelling.words.first {
            $0.partOfSpeech.localizedCaseInsensitiveCompare(pos) == .orderedSame
        }

        let word = existingWord ?? Word(
            spelling: spelling,
            partOfSpeech: pos,
            isApproved: false,
            sourceType: "sentence-suggestion"
        )
        if word.modelContext == nil {
            modelContext.insert(word)
        }

        if !definitionText.isEmpty,
           !word.definitions.contains(where: { $0.definitionText == definitionText }) {
            let definition = Definition(word: word, definitionText: definitionText, sortOrder: 0)
            modelContext.insert(definition)
        }

        try? modelContext.save()
        return word
    }

    private func isInLexicon(_ word: Word) -> Bool {
        LexiconWordService.isInLexicon(word, entries: lexiconEntries)
    }

    private func addToLexicon(_ word: Word) {
        LexiconWordService.addToLexicon(word, entries: lexiconEntries, in: modelContext)
    }
}

private struct SuggestedWord: Identifiable {
    let word: Word
    let definition: String

    var id: Word.ID {
        word.id
    }
}

@MainActor
private final class SentenceWordNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isNarrating = false
    @Published var currentTokenIndex: Int?

    private let synthesizer = AVSpeechSynthesizer()
    private var queue: [(index: Int, token: String)] = []

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func start(tokens: [String]) {
        stop()
        queue = tokens.enumerated().compactMap { index, token in
            let cleaned = token.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
            guard !cleaned.isEmpty else { return nil }
            return (index, cleaned)
        }
        guard !queue.isEmpty else { return }
        isNarrating = true
        speakNext()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        queue.removeAll()
        currentTokenIndex = nil
        isNarrating = false
    }

    private func speakNext() {
        guard !queue.isEmpty else {
            isNarrating = false
            currentTokenIndex = nil
            return
        }

        let next = queue.removeFirst()
        currentTokenIndex = next.index

        let utterance = AVSpeechUtterance(string: next.token)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speakNext()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isNarrating = false
            currentTokenIndex = nil
        }
    }
}
