//
//  TopicWordSuggestionService.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import Foundation
import FoundationModels

@Generable
struct TopicWordSuggestion: Equatable {
    var word: String
    var partOfSpeech: String
    var definition: String
}

@Generable
struct TopicWordSuggestionBatch: Equatable {
    @Guide(.count(4))
    var words: [TopicWordSuggestion]
}

actor TopicWordSuggestionService {
    static let shared = TopicWordSuggestionService()

    func suggestWords(for topicName: String) async throws -> [TopicWordSuggestion] {
        let model = SystemLanguageModel(useCase: .general)
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw TopicSuggestionError.unavailable(reason)
        }

        let session = LanguageModelSession(model: model)
        let prompt = """
        Suggest 4 distinct English words that fit the topic "\(topicName)".
        Provide a part of speech (noun, verb, adjective, or adverb) and a full definition.
        Avoid proper nouns and invented terms.
        """
        let response = try await session.respond(to: prompt, generating: TopicWordSuggestionBatch.self)
        return response.content.words
    }
}

enum TopicSuggestionError: LocalizedError {
    case unavailable(SystemLanguageModel.Availability.UnavailableReason)

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Apple Intelligence isn't available on this device."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is disabled. Enable it to get suggestions."
            case .modelNotReady:
                return "Apple Intelligence is still preparing. Try again shortly."
            @unknown default:
                return "Apple Intelligence is unavailable on this device."
            }
        }
    }
}
