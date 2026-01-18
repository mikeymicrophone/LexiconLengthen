//
//  UserProfile.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Stores the user's profile, preferences, and aggregate statistics.
/// Synced to private CloudKit database.
@Model
final class UserProfile {
    /// Display name chosen by the user
    var displayName: String?

    /// Preferred language code for dictionary (ISO 639-1)
    var preferredLanguageCode: String

    /// Preferred accent/dialect code for pronunciations
    var preferredAccentCode: String?

    /// Total points earned across all activities
    var totalPoints: Int

    /// Count of unique words known (at least one definition mastered)
    var wordsKnownCount: Int

    /// Count of definitions mastered
    var definitionsMasteredCount: Int

    /// Count of pronunciations mastered
    var pronunciationsMasteredCount: Int

    /// Count of sentences created
    var sentencesCreatedCount: Int

    /// Current daily streak (consecutive days active)
    var currentStreak: Int

    /// Longest streak ever achieved
    var longestStreak: Int

    /// Date of last activity (for streak calculation)
    var lastActiveDate: Date?

    /// Date the profile was created
    var createdAt: Date

    /// Date the profile was last updated
    var updatedAt: Date

    init(
        displayName: String? = nil,
        preferredLanguageCode: String = "en",
        preferredAccentCode: String? = nil
    ) {
        self.displayName = displayName
        self.preferredLanguageCode = preferredLanguageCode
        self.preferredAccentCode = preferredAccentCode
        self.totalPoints = 0
        self.wordsKnownCount = 0
        self.definitionsMasteredCount = 0
        self.pronunciationsMasteredCount = 0
        self.sentencesCreatedCount = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Streak Management

extension UserProfile {
    /// Updates the streak based on activity today
    func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken - reset
                currentStreak = 1
            }
            // daysDiff == 0 means same day, no change to streak
        } else {
            // First activity ever
            currentStreak = 1
        }

        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastActiveDate = Date()
        updatedAt = Date()
    }

    /// Adds points and updates the total
    func addPoints(_ points: Int) {
        totalPoints += points
        updatedAt = Date()
    }

    /// Increments the count when a new word is learned
    func recordWordLearned() {
        wordsKnownCount += 1
        updatedAt = Date()
    }

    /// Increments the count when a definition is mastered
    func recordDefinitionMastered() {
        definitionsMasteredCount += 1
        updatedAt = Date()
    }

    /// Increments the count when a pronunciation is mastered
    func recordPronunciationMastered() {
        pronunciationsMasteredCount += 1
        updatedAt = Date()
    }

    /// Increments the count when a sentence is created
    func recordSentenceCreated() {
        sentencesCreatedCount += 1
        updatedAt = Date()
    }
}
