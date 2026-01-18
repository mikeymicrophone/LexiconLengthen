//
//  WordReadingMastery.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import Foundation
import SwiftData

/// Tracks user's reading mastery for a specific word.
@Model
final class WordReadingMastery {
    /// Reference to the public word (stored as ID string for CloudKit)
    var wordID: String

    /// Denormalized: Word spelling text for display
    var wordSpellingText: String

    /// Denormalized: Letter count for points calculation
    var wordLetterCount: Int

    /// Mastery level (0 = not started, 1-5 = progressing, 5 = mastered)
    var masteryLevel: Int

    /// Number of times read correctly
    var correctCount: Int

    /// Number of times read incorrectly
    var incorrectCount: Int

    /// Date of last reading check
    var lastReviewedAt: Date?

    /// Total points earned from reading this word
    var pointsEarned: Int

    /// Date first started practicing
    var createdAt: Date

    init(
        wordID: String,
        wordSpellingText: String,
        wordLetterCount: Int
    ) {
        self.wordID = wordID
        self.wordSpellingText = wordSpellingText
        self.wordLetterCount = wordLetterCount
        self.masteryLevel = 0
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastReviewedAt = nil
        self.pointsEarned = 0
        self.createdAt = Date()
    }
}

// MARK: - Mastery Helpers

extension WordReadingMastery {
    /// Returns true if this word has been mastered for reading (level 5)
    var isMastered: Bool {
        masteryLevel >= 5
    }

    /// Human-readable mastery level description
    var masteryLevelDescription: String {
        switch masteryLevel {
        case 0: return "Not Started"
        case 1: return "Decoding"
        case 2: return "Comfortable"
        case 3: return "Fluent"
        case 4: return "Instant"
        case 5: return "Mastered"
        default: return "Unknown"
        }
    }

    /// Records a reading attempt and updates mastery
    func recordAttempt(correct: Bool) {
        lastReviewedAt = Date()

        if correct {
            correctCount += 1
            masteryLevel = min(5, masteryLevel + 1)
        } else {
            incorrectCount += 1
            masteryLevel = max(0, masteryLevel - 1)
        }
    }
}
