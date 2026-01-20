//
//  SentenceWordSuggestionService.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/20/26.
//

import Foundation
import FoundationModels

@Generable
struct SentenceWordSuggestion: Equatable {
    var word: String
    var partOfSpeech: String
    var definition: String
}

@Generable
struct SentenceWordSuggestionBatch: Equatable {
    @Guide(.maximumCount(10))
    var suggestions: [SentenceWordSuggestion]
}

enum SentenceWordSuggestionService {
    static func suggestWords(for sentence: String) async -> [SentenceWordSuggestion] {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let model = SystemLanguageModel(useCase: .general)
        switch model.availability {
        case .available:
            break
        case .unavailable:
            return []
        }

        let session = LanguageModelSession(model: model)
        let prompt = """
        Given this sentence: \"\(trimmed)\"
        Suggest 10 single-word additions (nouns, verbs, adjectives, adverbs) that could fit naturally in similar sentences.
        Provide each word with its part of speech and a short, clear definition.
        Avoid duplicates and proper nouns. Keep words lowercase unless capitalization is required.
        """

        do {
            let response = try await session.respond(to: prompt, generating: SentenceWordSuggestionBatch.self)
            return response.content.suggestions
        } catch {
            return []
        }
    }
}
