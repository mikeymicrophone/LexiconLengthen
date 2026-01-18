//
//  PointsCalculator.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Service for calculating points across all game activities.
/// Points System:
/// - Word Known: 10 + (letterCount × 2)
/// - Definition Mastered: 15 + (definitionLength ÷ 10)
/// - Pronunciation Mastered: 20 + (5 per additional accent)
/// - Sentence Created: 25 + (wordCount × 3) + totalLetterCount
/// - Submission Approved: 100 (+50 with audio)
/// - Daily Streak: min(streak × 5, 50)
struct PointsCalculator {

    // MARK: - Word Points

    /// Calculates points for knowing a word
    /// Formula: 10 + (letterCount × 2)
    static func pointsForWordKnown(letterCount: Int) -> Int {
        return 10 + (letterCount * 2)
    }

    /// Calculates points for knowing a word from its spelling
    static func pointsForWordKnown(spelling: Spelling) -> Int {
        return pointsForWordKnown(letterCount: spelling.letterCount)
    }

    /// Calculates points for knowing a word
    static func pointsForWordKnown(word: Word) -> Int {
        return pointsForWordKnown(letterCount: word.letterCount)
    }

    // MARK: - Definition Points

    /// Calculates points for mastering a definition
    /// Formula: 15 + (definitionLength ÷ 10)
    static func pointsForDefinitionMastered(definitionLength: Int) -> Int {
        return 15 + (definitionLength / 10)
    }

    /// Calculates points for mastering a definition
    static func pointsForDefinitionMastered(definition: Definition) -> Int {
        return pointsForDefinitionMastered(definitionLength: definition.definitionLength)
    }

    /// Calculates points for mastering a definition from mastery record
    static func pointsForDefinitionMastered(mastery: DefinitionMastery) -> Int {
        return pointsForDefinitionMastered(definitionLength: mastery.definitionLength)
    }

    // MARK: - Pronunciation Points

    /// Calculates points for mastering a pronunciation
    /// Formula: 20 + (5 per additional accent beyond the first)
    static func pointsForPronunciationMastered(accentIndex: Int = 0) -> Int {
        // Base points for first pronunciation, +5 for each additional accent
        return 20 + (accentIndex * 5)
    }

    /// Calculates total pronunciation points for a word with multiple accents
    static func totalPronunciationPoints(accentCount: Int) -> Int {
        var total = 0
        for i in 0..<accentCount {
            total += pointsForPronunciationMastered(accentIndex: i)
        }
        return total
    }

    // MARK: - Sentence Points

    /// Calculates points for creating a sentence
    /// Formula: 25 + (wordCount × 3) + totalLetterCount
    static func pointsForSentenceCreated(wordCount: Int, totalLetterCount: Int) -> Int {
        return 25 + (wordCount * 3) + totalLetterCount
    }

    /// Calculates points for creating a sentence from a UserSentence
    static func pointsForSentenceCreated(sentence: UserSentence) -> Int {
        return pointsForSentenceCreated(
            wordCount: sentence.wordCount,
            totalLetterCount: sentence.totalLetterCount
        )
    }

    /// Calculates points for completing a sentence template
    static func pointsForTemplateCompleted(
        template: SentenceTemplate,
        wordCount: Int,
        totalLetterCount: Int
    ) -> Int {
        // Template base points + sentence creation points
        return template.pointsValue + pointsForSentenceCreated(
            wordCount: wordCount,
            totalLetterCount: totalLetterCount
        )
    }

    // MARK: - Submission Points

    /// Calculates points for an approved submission
    /// Formula: 100 (+50 with audio)
    static func pointsForSubmissionApproved(hasAudio: Bool) -> Int {
        return hasAudio ? 150 : 100
    }

    /// Calculates points for an approved submission
    static func pointsForSubmissionApproved(submission: UserSubmission) -> Int {
        return pointsForSubmissionApproved(hasAudio: submission.hasAudio)
    }

    // MARK: - Streak Points

    /// Calculates points for daily streak
    /// Formula: min(streak × 5, 50)
    static func pointsForDailyStreak(streakDays: Int) -> Int {
        return min(streakDays * 5, 50)
    }

    /// Calculates points for daily streak from user profile
    static func pointsForDailyStreak(profile: UserProfile) -> Int {
        return pointsForDailyStreak(streakDays: profile.currentStreak)
    }

    // MARK: - Aggregate Calculations

    /// Calculates total points that would be earned for learning a word completely
    /// (knowing the word + mastering all definitions + mastering all pronunciations)
    static func totalPotentialPoints(for word: Word) -> Int {
        var total = 0

        // Points for knowing the word
        total += pointsForWordKnown(word: word)

        // Points for mastering each definition
        for definition in word.definitions {
            total += pointsForDefinitionMastered(definition: definition)
        }

        // Points for mastering each pronunciation
        for (index, _) in word.pronunciations.enumerated() {
            total += pointsForPronunciationMastered(accentIndex: index)
        }

        return total
    }

    /// Estimates points remaining to learn for a word based on current mastery
    static func pointsRemaining(
        for word: Word,
        masteredDefinitionIDs: Set<String>,
        masteredPronunciationIDs: Set<String>
    ) -> Int {
        var remaining = 0

        // Definition points for unmastered definitions
        for definition in word.definitions {
            let definitionID = definition.persistentModelID.storeIdentifier ?? ""
            if !masteredDefinitionIDs.contains(definitionID) {
                remaining += pointsForDefinitionMastered(definition: definition)
            }
        }

        // Pronunciation points for unmastered pronunciations
        for (index, pronunciation) in word.pronunciations.enumerated() {
            let pronunciationID = pronunciation.persistentModelID.storeIdentifier ?? ""
            if !masteredPronunciationIDs.contains(pronunciationID) {
                remaining += pointsForPronunciationMastered(accentIndex: index)
            }
        }

        return remaining
    }
}

// MARK: - Points Breakdown

extension PointsCalculator {
    /// Represents a breakdown of points for display
    struct PointsBreakdown {
        let wordPoints: Int
        let definitionPoints: Int
        let pronunciationPoints: Int
        let sentencePoints: Int
        let submissionPoints: Int
        let streakPoints: Int

        var total: Int {
            wordPoints + definitionPoints + pronunciationPoints +
            sentencePoints + submissionPoints + streakPoints
        }

        static let empty = PointsBreakdown(
            wordPoints: 0,
            definitionPoints: 0,
            pronunciationPoints: 0,
            sentencePoints: 0,
            submissionPoints: 0,
            streakPoints: 0
        )
    }
}
