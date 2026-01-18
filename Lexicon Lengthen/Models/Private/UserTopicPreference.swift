//
//  UserTopicPreference.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Stores user's preference and progress for a specific topic.
/// Synced to private CloudKit database.
@Model
final class UserTopicPreference {
    /// Reference to the public topic (stored as ID string for CloudKit)
    var topicID: String

    /// Denormalized: Topic name for display
    var topicName: String

    /// User's interest level in this topic (1-5, higher = more interested)
    var interestLevel: Int

    /// Number of words learned in this topic
    var wordsLearnedInTopic: Int

    /// Whether this topic is currently active/enabled for the user
    var isActive: Bool

    /// Date this preference was created
    var createdAt: Date

    /// Date this preference was last updated
    var updatedAt: Date

    init(
        topicID: String,
        topicName: String,
        interestLevel: Int = 3,
        isActive: Bool = true
    ) {
        self.topicID = topicID
        self.topicName = topicName
        self.interestLevel = min(5, max(1, interestLevel))
        self.wordsLearnedInTopic = 0
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Convenience Extensions

extension UserTopicPreference {
    /// Updates the interest level (clamped to 1-5)
    func setInterestLevel(_ level: Int) {
        interestLevel = min(5, max(1, level))
        updatedAt = Date()
    }

    /// Increments the words learned count
    func recordWordLearned() {
        wordsLearnedInTopic += 1
        updatedAt = Date()
    }

    /// Toggles the active state
    func toggleActive() {
        isActive.toggle()
        updatedAt = Date()
    }

    /// Human-readable interest level description
    var interestLevelDescription: String {
        switch interestLevel {
        case 1: return "Low Interest"
        case 2: return "Slight Interest"
        case 3: return "Moderate Interest"
        case 4: return "High Interest"
        case 5: return "Very High Interest"
        default: return "Unknown"
        }
    }
}
