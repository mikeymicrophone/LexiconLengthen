//
//  AISuggestion.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents an AI-generated suggestion for the user.
/// Stored in public CloudKit database.
@Model
final class AISuggestion {
    /// Unique identifier for the suggestion
    @Attribute(.unique) var suggestionID: String

    /// Type of suggestion (word/definition/sentence/topic)
    var suggestionType: String

    /// The suggested content
    var suggestedContent: String

    /// Additional context or explanation
    var contextExplanation: String?

    /// Reference to related word ID (if applicable)
    var relatedWordID: String?

    /// Reference to related topic ID (if applicable)
    var relatedTopicID: String?

    /// Target user ID this suggestion is for
    var targetUserID: String

    /// Source of the suggestion (on-device/cloud-api)
    var source: String

    /// Whether the suggestion was accepted by the user
    var wasAccepted: Bool?

    /// User feedback on the suggestion
    var userFeedback: String?

    /// Date the suggestion was generated
    var generatedAt: Date

    /// Date the user responded to the suggestion
    var respondedAt: Date?

    /// Expiration date (suggestions may become stale)
    var expiresAt: Date

    init(
        suggestionType: SuggestionType,
        suggestedContent: String,
        targetUserID: String,
        source: SuggestionSource,
        contextExplanation: String? = nil,
        relatedWordID: String? = nil,
        relatedTopicID: String? = nil,
        expirationDays: Int = 7
    ) {
        self.suggestionID = UUID().uuidString
        self.suggestionType = suggestionType.rawValue
        self.suggestedContent = suggestedContent
        self.targetUserID = targetUserID
        self.source = source.rawValue
        self.contextExplanation = contextExplanation
        self.relatedWordID = relatedWordID
        self.relatedTopicID = relatedTopicID
        self.wasAccepted = nil
        self.generatedAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: expirationDays, to: Date()) ?? Date()
    }
}

// MARK: - Suggestion Types

extension AISuggestion {
    enum SuggestionType: String, CaseIterable {
        case wordToLearn
        case definitionToExplore
        case sentenceToCreate
        case topicToExplore
        case practiceReminder
        case relatedWord

        var displayName: String {
            switch self {
            case .wordToLearn: return "Word to Learn"
            case .definitionToExplore: return "Definition to Explore"
            case .sentenceToCreate: return "Sentence to Create"
            case .topicToExplore: return "Topic to Explore"
            case .practiceReminder: return "Practice Reminder"
            case .relatedWord: return "Related Word"
            }
        }

        var iconName: String {
            switch self {
            case .wordToLearn: return "book"
            case .definitionToExplore: return "text.book.closed"
            case .sentenceToCreate: return "text.quote"
            case .topicToExplore: return "folder"
            case .practiceReminder: return "clock"
            case .relatedWord: return "link"
            }
        }
    }

    enum SuggestionSource: String, CaseIterable {
        case onDevice = "on-device"
        case cloudAPI = "cloud-api"

        var displayName: String {
            switch self {
            case .onDevice: return "On-Device AI"
            case .cloudAPI: return "Cloud AI"
            }
        }

        var description: String {
            switch self {
            case .onDevice: return "Generated using Apple Intelligence for privacy"
            case .cloudAPI: return "Generated using cloud AI for enhanced suggestions"
            }
        }
    }

    /// Returns the suggestion type as an enum
    var type: SuggestionType? {
        SuggestionType(rawValue: suggestionType)
    }

    /// Returns the source as an enum
    var suggestionSource: SuggestionSource? {
        SuggestionSource(rawValue: source)
    }

    /// Whether this suggestion has expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Whether this suggestion is still pending a response
    var isPending: Bool {
        wasAccepted == nil && !isExpired
    }

    /// Records user acceptance of the suggestion
    func accept(feedback: String? = nil) {
        wasAccepted = true
        userFeedback = feedback
        respondedAt = Date()
    }

    /// Records user rejection of the suggestion
    func reject(feedback: String? = nil) {
        wasAccepted = false
        userFeedback = feedback
        respondedAt = Date()
    }
}
