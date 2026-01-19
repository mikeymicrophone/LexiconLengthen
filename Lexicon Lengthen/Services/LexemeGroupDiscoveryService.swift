//
//  LexemeGroupDiscoveryService.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import Foundation
import FoundationModels
import SwiftData

@Generable
struct LexemeFormSuggestion: Equatable {
    var word: String
    var partOfSpeech: String
}

@Generable
struct LexemeFormSuggestionBatch: Equatable {
    @Guide(.maximumCount(6))
    var forms: [LexemeFormSuggestion]
}

enum LexemeGroupDiscoveryService {
    @MainActor
    static func discoverRelatedForms(for word: Word, in context: ModelContext) async {
        let root = word.spellingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !root.isEmpty else { return }

        let suggestions = await suggestForms(for: root)
        guard !suggestions.isEmpty else { return }

        applySuggestions(suggestions, rootWord: word, in: context)
    }

    private static func suggestForms(for root: String) async -> [LexemeFormSuggestion] {
        let model = SystemLanguageModel(useCase: .general)
        switch model.availability {
        case .available:
            break
        case .unavailable:
            return []
        }

        let session = LanguageModelSession(model: model)
        let prompt = """
        List derivationally related forms for the English word \"\(root)\".
        Provide up to 6 distinct words with their part of speech (noun, verb, adjective, adverb).
        Avoid proper nouns and keep words in lowercase unless capitalization is required.
        Do not include the original word.
        """
        do {
            let response = try await session.respond(to: prompt, generating: LexemeFormSuggestionBatch.self)
            return response.content.forms
        } catch {
            return []
        }
    }

    @MainActor
    private static func applySuggestions(
        _ suggestions: [LexemeFormSuggestion],
        rootWord: Word,
        in context: ModelContext
    ) {
        let normalizedRoot = rootWord.spellingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let group = rootWord.lexemeGroup ?? fetchOrCreateGroup(for: normalizedRoot, in: context)
        rootWord.lexemeGroup = group

        let descriptor = FetchDescriptor<Spelling>()
        let existingSpellings = (try? context.fetch(descriptor)) ?? []
        var spellingByLower = Dictionary(uniqueKeysWithValues: existingSpellings.map { ($0.textLowercase, $0) })

        for suggestion in suggestions {
            let spellingText = suggestion.word.trimmingCharacters(in: .whitespacesAndNewlines)
            let posText = suggestion.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !spellingText.isEmpty, !posText.isEmpty else { continue }
            let lower = spellingText.lowercased()
            guard lower != normalizedRoot else { continue }

            let spelling = spellingByLower[lower] ?? Spelling(text: spellingText)
            if spelling.modelContext == nil {
                context.insert(spelling)
                spellingByLower[lower] = spelling
            }

            let existing = spelling.words.first {
                $0.partOfSpeech.localizedCaseInsensitiveCompare(posText) == .orderedSame
            }
            if let existing {
                existing.lexemeGroup = group
                continue
            }

            let derivedWord = Word(
                spelling: spelling,
                lexemeGroup: group,
                partOfSpeech: posText,
                isApproved: false,
                sourceType: "lexeme-group"
            )
            context.insert(derivedWord)
        }

        try? context.save()
    }

    @MainActor
    private static func fetchOrCreateGroup(for root: String, in context: ModelContext) -> LexemeGroup {
        let descriptor = FetchDescriptor<LexemeGroup>(
            predicate: #Predicate { $0.rootText == root }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let group = LexemeGroup(rootText: root)
        context.insert(group)
        return group
    }
}
