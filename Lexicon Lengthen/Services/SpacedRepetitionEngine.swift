//
//  SpacedRepetitionEngine.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation

/// Implements the SM-2 (SuperMemo 2) spaced repetition algorithm
/// for optimizing definition review scheduling.
struct SpacedRepetitionEngine {

    // MARK: - SM-2 Algorithm Constants

    /// Minimum ease factor allowed
    static let minimumEaseFactor: Double = 1.3

    /// Default ease factor for new items
    static let defaultEaseFactor: Double = 2.5

    /// Minimum quality grade considered "correct"
    static let minimumCorrectGrade = 3

    // MARK: - Review Processing

    /// Processes a review and returns updated mastery values
    /// - Parameters:
    ///   - mastery: The current definition mastery record
    ///   - quality: The quality of the response (0-5)
    /// - Returns: Updated mastery values
    static func processReview(
        mastery: DefinitionMastery,
        quality: DefinitionMastery.ReviewQuality
    ) -> ReviewResult {
        let q = quality.rawValue

        // Calculate new ease factor using SM-2 formula
        var newEaseFactor = mastery.easeFactor + (0.1 - (5 - Double(q)) * (0.08 + (5 - Double(q)) * 0.02))
        newEaseFactor = max(minimumEaseFactor, newEaseFactor)

        // Calculate new interval
        let newInterval: Int
        let newMasteryLevel: Int
        let isCorrect = q >= minimumCorrectGrade

        if !isCorrect {
            // If answer was incorrect, reset interval
            newInterval = 1
            newMasteryLevel = max(0, mastery.masteryLevel - 1)
        } else {
            // Calculate new interval based on repetition number
            if mastery.intervalDays == 0 {
                newInterval = 1
            } else if mastery.intervalDays == 1 {
                newInterval = 6
            } else {
                newInterval = Int(round(Double(mastery.intervalDays) * newEaseFactor))
            }

            // Increase mastery level for correct answers
            newMasteryLevel = min(5, mastery.masteryLevel + (q >= 4 ? 1 : 0))
        }

        // Calculate next review date
        let nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: newInterval,
            to: Date()
        ) ?? Date()

        return ReviewResult(
            newEaseFactor: newEaseFactor,
            newIntervalDays: newInterval,
            newMasteryLevel: newMasteryLevel,
            nextReviewAt: nextReviewDate,
            wasCorrect: isCorrect
        )
    }

    /// Applies review results to a mastery record
    static func applyReview(
        to mastery: inout DefinitionMastery,
        quality: DefinitionMastery.ReviewQuality
    ) {
        let result = processReview(mastery: mastery, quality: quality)

        mastery.easeFactor = result.newEaseFactor
        mastery.intervalDays = result.newIntervalDays
        mastery.masteryLevel = result.newMasteryLevel
        mastery.nextReviewAt = result.nextReviewAt
        mastery.lastReviewedAt = Date()

        if result.wasCorrect {
            mastery.correctCount += 1
        } else {
            mastery.incorrectCount += 1
        }

        // Award points if mastery level increased
        if result.newMasteryLevel > mastery.masteryLevel {
            mastery.pointsEarned += PointsCalculator.pointsForDefinitionMastered(
                definitionLength: mastery.definitionLength
            ) / 5 // Partial points per level
        }
    }

    // MARK: - Scheduling

    /// Returns items due for review, sorted by priority
    static func itemsDueForReview(
        from masteryRecords: [DefinitionMastery],
        limit: Int = 20
    ) -> [DefinitionMastery] {
        let now = Date()

        return masteryRecords
            .filter { mastery in
                // Include items that are due or never started
                guard let nextReview = mastery.nextReviewAt else {
                    return mastery.masteryLevel == 0
                }
                return nextReview <= now
            }
            .sorted { a, b in
                // Priority: overdue items first, then by ease factor (harder items first)
                let aOverdue = overdueDays(for: a)
                let bOverdue = overdueDays(for: b)

                if aOverdue != bOverdue {
                    return aOverdue > bOverdue
                }
                return a.easeFactor < b.easeFactor
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Calculates how many days overdue an item is
    static func overdueDays(for mastery: DefinitionMastery) -> Int {
        guard let nextReview = mastery.nextReviewAt else {
            return mastery.masteryLevel == 0 ? Int.max : 0
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: nextReview, to: Date()).day ?? 0
        return max(0, days)
    }

    /// Estimates the optimal number of new items to learn per day
    static func recommendedNewItemsPerDay(
        totalItemsToLearn: Int,
        currentDailyReviewLoad: Int,
        targetDailyReviewTime: Int = 20 // minutes
    ) -> Int {
        // Assume average 30 seconds per review
        let maxReviewsPerDay = targetDailyReviewTime * 2

        // Leave room for reviews of previously learned items
        let availableSlots = max(0, maxReviewsPerDay - currentDailyReviewLoad)

        // New items typically need to be reviewed multiple times initially
        // So divide available slots by expected initial review count
        let newItemsPerDay = availableSlots / 4

        return max(1, min(newItemsPerDay, 10)) // Between 1 and 10 new items
    }

    // MARK: - Statistics

    /// Calculates retention rate based on review history
    static func retentionRate(for masteryRecords: [DefinitionMastery]) -> Double {
        let totalCorrect = masteryRecords.reduce(0) { $0 + $1.correctCount }
        let totalIncorrect = masteryRecords.reduce(0) { $0 + $1.incorrectCount }
        let total = totalCorrect + totalIncorrect

        guard total > 0 else { return 0 }
        return Double(totalCorrect) / Double(total)
    }

    /// Estimates total review time for due items
    static func estimatedReviewTime(itemCount: Int, secondsPerItem: Int = 30) -> TimeInterval {
        return TimeInterval(itemCount * secondsPerItem)
    }

    /// Returns mastery distribution across levels
    static func masteryDistribution(
        for masteryRecords: [DefinitionMastery]
    ) -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        for level in 0...5 {
            distribution[level] = 0
        }

        for mastery in masteryRecords {
            distribution[mastery.masteryLevel, default: 0] += 1
        }

        return distribution
    }
}

// MARK: - Review Result

extension SpacedRepetitionEngine {
    /// Result of processing a review
    struct ReviewResult {
        let newEaseFactor: Double
        let newIntervalDays: Int
        let newMasteryLevel: Int
        let nextReviewAt: Date
        let wasCorrect: Bool
    }
}

// MARK: - Learning Session

extension SpacedRepetitionEngine {
    /// Represents a learning session with items to review
    struct LearningSession {
        let newItems: [DefinitionMastery]
        let reviewItems: [DefinitionMastery]
        let estimatedDuration: TimeInterval

        var totalItems: Int {
            newItems.count + reviewItems.count
        }

        var isEmpty: Bool {
            totalItems == 0
        }
    }

    /// Creates a balanced learning session
    static func createSession(
        newItems: [DefinitionMastery],
        dueForReview: [DefinitionMastery],
        maxNewItems: Int = 5,
        maxReviewItems: Int = 15
    ) -> LearningSession {
        let selectedNew = Array(newItems.prefix(maxNewItems))
        let selectedReview = Array(dueForReview.prefix(maxReviewItems))

        let duration = estimatedReviewTime(
            itemCount: selectedNew.count + selectedReview.count
        )

        return LearningSession(
            newItems: selectedNew,
            reviewItems: selectedReview,
            estimatedDuration: duration
        )
    }
}
