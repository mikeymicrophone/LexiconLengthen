//
//  Word.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a lexeme - a distinct meaning unit. Multiple words may share
/// the same spelling (homographs) but have different parts of speech or etymologies.
@Model
final class Word {
    /// The spelling of this word
    var spelling: Spelling?

    /// Part of speech (noun, verb, adjective, etc.)
    var partOfSpeech: String

    /// Etymology/origin of the word
    var etymology: String?

    /// Usage frequency (0.0 to 1.0, higher = more common)
    var frequency: Double

    /// Difficulty level (1-5, higher = more difficult)
    var difficultyLevel: Int

    /// Whether this word has been approved for public use
    var isApproved: Bool

    /// Source of this word (user/ai/import)
    var sourceType: String

    /// Date the word was created
    var createdAt: Date

    /// Definitions for this word (users master each independently)
    @Relationship(deleteRule: .cascade, inverse: \Definition.word)
    var definitions: [Definition] = []

    /// Pronunciations for this word (may vary by accent/dialect)
    @Relationship(deleteRule: .cascade, inverse: \Pronunciation.word)
    var pronunciations: [Pronunciation] = []

    /// Topic associations for this word
    @Relationship(deleteRule: .cascade, inverse: \WordTopic.word)
    var wordTopics: [WordTopic] = []

    /// Lexeme group that connects derivationally related words
    var lexemeGroup: LexemeGroup?

    init(
        spelling: Spelling? = nil,
        lexemeGroup: LexemeGroup? = nil,
        partOfSpeech: String,
        etymology: String? = nil,
        frequency: Double = 0.5,
        difficultyLevel: Int = 3,
        isApproved: Bool = false,
        sourceType: String = "user"
    ) {
        self.spelling = spelling
        self.lexemeGroup = lexemeGroup
        self.partOfSpeech = partOfSpeech
        self.etymology = etymology
        self.frequency = frequency
        self.difficultyLevel = difficultyLevel
        self.isApproved = isApproved
        self.sourceType = sourceType
        self.createdAt = Date()
    }
}

// MARK: - Convenience Extensions

extension Word {
    /// Returns the spelling text, or empty string if no spelling
    var spellingText: String {
        spelling?.text ?? ""
    }

    /// Returns the letter count from the spelling
    var letterCount: Int {
        spelling?.letterCount ?? 0
    }

    /// Returns the primary definition, if any
    var primaryDefinition: Definition? {
        definitions.sorted { $0.sortOrder < $1.sortOrder }.first
    }

    /// Returns topics associated with this word
    var topics: [Topic] {
        wordTopics.compactMap { $0.topic }
    }
}
