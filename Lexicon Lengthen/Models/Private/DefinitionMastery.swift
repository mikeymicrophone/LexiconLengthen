//
//  DefinitionMastery.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Tracks user's mastery of a specific definition using spaced repetition.
/// Synced to private CloudKit database.
@Model
final class DefinitionMastery {
    /// Reference to the public definition (stored as ID string for CloudKit)
    var definitionID: String

    /// Denormalized: Word spelling text for display without fetching public data
    var wordSpellingText: String

    /// Denormalized: Letter count for points calculation
    var wordLetterCount: Int

    /// Denormalized: Definition length for points calculation
    var definitionLength: Int

    /// Mastery level (0 = not started, 1-5 = progressing, 5 = mastered)
    var masteryLevel: Int

    /// Number of times answered correctly
    var correctCount: Int

    /// Number of times answered incorrectly
    var incorrectCount: Int

    /// Date of last review
    var lastReviewedAt: Date?

    /// Next scheduled review date (for spaced repetition)
    var nextReviewAt: Date?

    /// SM-2 ease factor (starts at 2.5, adjusts based on performance)
    var easeFactor: Double

    /// Current interval in days until next review
    var intervalDays: Int

    /// Total points earned from this definition
    var pointsEarned: Int

    /// Date first learned
    var createdAt: Date

    init(
        definitionID: String,
        wordSpellingText: String,
        wordLetterCount: Int,
        definitionLength: Int
    ) {
        self.definitionID = definitionID
        self.wordSpellingText = wordSpellingText
        self.wordLetterCount = wordLetterCount
        self.definitionLength = definitionLength
        self.masteryLevel = 0
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastReviewedAt = nil
        self.nextReviewAt = nil
        self.easeFactor = 2.5
        self.intervalDays = 0
        self.pointsEarned = 0
        self.createdAt = Date()
    }
}

// MARK: - Mastery Helpers

extension DefinitionMastery {
    /// Returns true if this definition is due for review
    var isDueForReview: Bool {
        guard let nextReview = nextReviewAt else {
            return masteryLevel == 0 // Not started yet
        }
        return Date() >= nextReview
    }

    /// Returns true if this definition has been mastered (level 5)
    var isMastered: Bool {
        masteryLevel >= 5
    }

    /// Returns the accuracy rate (0.0 to 1.0)
    var accuracyRate: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    /// Human-readable mastery level description
    var masteryLevelDescription: String {
        switch masteryLevel {
        case 0: return "Not Started"
        case 1: return "Learning"
        case 2: return "Familiar"
        case 3: return "Practiced"
        case 4: return "Proficient"
        case 5: return "Mastered"
        default: return "Unknown"
        }
    }
}

// MARK: - Spaced Repetition Quality Grades

extension DefinitionMastery {
    /// Quality grades for SM-2 algorithm (0-5)
    enum ReviewQuality: Int {
        case completeBlackout = 0
        case incorrect = 1
        case incorrectButRemembered = 2
        case correctWithDifficulty = 3
        case correctWithHesitation = 4
        case perfectResponse = 5

        var description: String {
            switch self {
            case .completeBlackout: return "Complete blackout"
            case .incorrect: return "Incorrect"
            case .incorrectButRemembered: return "Incorrect, but remembered after seeing"
            case .correctWithDifficulty: return "Correct with serious difficulty"
            case .correctWithHesitation: return "Correct after hesitation"
            case .perfectResponse: return "Perfect response"
            }
        }
    }
}
