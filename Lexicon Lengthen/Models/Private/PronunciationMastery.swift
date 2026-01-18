//
//  PronunciationMastery.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Tracks user's mastery of a specific pronunciation.
/// Synced to private CloudKit database.
@Model
final class PronunciationMastery {
    /// Reference to the public pronunciation (stored as ID string for CloudKit)
    var pronunciationID: String

    /// Denormalized: Word spelling text for display
    var wordSpellingText: String

    /// Denormalized: Accent/dialect code for display
    var accentDialectCode: String

    /// Mastery level (0 = not started, 1-5 = progressing, 5 = mastered)
    var masteryLevel: Int

    /// Number of times practiced
    var practiceCount: Int

    /// Date of last practice
    var lastPracticedAt: Date?

    /// Total points earned from this pronunciation
    var pointsEarned: Int

    /// Date first started practicing
    var createdAt: Date

    init(
        pronunciationID: String,
        wordSpellingText: String,
        accentDialectCode: String
    ) {
        self.pronunciationID = pronunciationID
        self.wordSpellingText = wordSpellingText
        self.accentDialectCode = accentDialectCode
        self.masteryLevel = 0
        self.practiceCount = 0
        self.lastPracticedAt = nil
        self.pointsEarned = 0
        self.createdAt = Date()
    }
}

// MARK: - Mastery Helpers

extension PronunciationMastery {
    /// Returns true if this pronunciation has been mastered (level 5)
    var isMastered: Bool {
        masteryLevel >= 5
    }

    /// Human-readable mastery level description
    var masteryLevelDescription: String {
        switch masteryLevel {
        case 0: return "Not Practiced"
        case 1: return "Beginning"
        case 2: return "Developing"
        case 3: return "Improving"
        case 4: return "Confident"
        case 5: return "Mastered"
        default: return "Unknown"
        }
    }

    /// Records a practice session and updates mastery
    func recordPractice(successful: Bool) {
        practiceCount += 1
        lastPracticedAt = Date()

        if successful && masteryLevel < 5 {
            // Increment mastery level based on practice count at current level
            let practicesNeeded = 3 + masteryLevel // More practices needed at higher levels
            if practiceCount >= practicesNeeded {
                masteryLevel += 1
            }
        }
    }
}
