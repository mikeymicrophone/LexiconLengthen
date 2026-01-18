//
//  UserSentence.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Stores a sentence created by the user.
/// Synced to private CloudKit database.
@Model
final class UserSentence {
    /// The complete sentence text
    var sentenceText: String

    /// Reference to the template used (if any)
    var templateID: String?

    /// JSON array of word IDs used in the sentence
    var wordIDsJSON: String

    /// Denormalized: Array of word spellings used
    var wordSpellingsJSON: String

    /// Number of words in the sentence
    var wordCount: Int

    /// Total letter count across all words (for points)
    var totalLetterCount: Int

    /// Points earned for this sentence
    var pointsEarned: Int

    /// Whether this sentence has been favorited
    var isFavorite: Bool

    /// Date the sentence was created
    var createdAt: Date

    init(
        sentenceText: String,
        templateID: String? = nil,
        wordIDs: [String],
        wordSpellings: [String],
        pointsEarned: Int = 0
    ) {
        self.sentenceText = sentenceText
        self.templateID = templateID
        self.wordIDsJSON = (try? JSONEncoder().encode(wordIDs))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.wordSpellingsJSON = (try? JSONEncoder().encode(wordSpellings))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.wordCount = wordSpellings.count
        self.totalLetterCount = wordSpellings.reduce(0) { $0 + $1.filter { $0.isLetter }.count }
        self.pointsEarned = pointsEarned
        self.isFavorite = false
        self.createdAt = Date()
    }
}

// MARK: - Convenience Extensions

extension UserSentence {
    /// Decodes word IDs from JSON storage
    var wordIDs: [String] {
        guard let data = wordIDsJSON.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }

    /// Decodes word spellings from JSON storage
    var wordSpellings: [String] {
        guard let data = wordSpellingsJSON.data(using: .utf8),
              let spellings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return spellings
    }

    /// Sets word IDs and encodes to JSON
    func setWordIDs(_ ids: [String]) {
        if let data = try? JSONEncoder().encode(ids),
           let json = String(data: data, encoding: .utf8) {
            wordIDsJSON = json
        }
    }

    /// Sets word spellings and encodes to JSON
    func setWordSpellings(_ spellings: [String]) {
        if let data = try? JSONEncoder().encode(spellings),
           let json = String(data: data, encoding: .utf8) {
            wordSpellingsJSON = json
            wordCount = spellings.count
            totalLetterCount = spellings.reduce(0) { $0 + $1.filter { $0.isLetter }.count }
        }
    }

    /// Whether this sentence used a template
    var usedTemplate: Bool {
        templateID != nil
    }
}
