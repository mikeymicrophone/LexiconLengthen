//
//  DefinitionSuggestionService.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/20/26.
//

import Foundation
import FoundationModels

@Generable
struct DefinitionSuggestion: Equatable {
    var definition: String
    var example: String?
}

enum DefinitionSuggestionService {
    static func suggestDefinition(word: String, partOfSpeech: String?) async -> DefinitionSuggestion? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let model = SystemLanguageModel(useCase: .general)
        switch model.availability {
        case .available:
            break
        case .unavailable:
            return nil
        }

        let session = LanguageModelSession(model: model)
        let posText = partOfSpeech?.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = """
        Provide a short dictionary-style definition for the English word \"\(trimmed)\".
        Part of speech: \(posText?.isEmpty == false ? posText! : "unknown").
        Keep the definition concise and avoid proper nouns. Provide an optional example sentence.
        """

        do {
            let response = try await session.respond(to: prompt, generating: DefinitionSuggestion.self)
            let definition = response.content.definition.trimmingCharacters(in: .whitespacesAndNewlines)
            if definition.isEmpty {
                return nil
            }
            return response.content
        } catch {
            return nil
        }
    }
}
