//
//  UserSubmission.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a user's submission of a new word, definition, or pronunciation.
/// Stored in public CloudKit database for moderation.
@Model
final class UserSubmission {
    /// Unique identifier for the submission
    @Attribute(.unique) var submissionID: String

    /// Type of submission (word/definition/pronunciation)
    var submissionType: String

    /// The submitted word spelling
    var wordSpelling: String

    /// Part of speech (for word submissions)
    var partOfSpeech: String?

    /// Definition text (for definition submissions)
    var definitionText: String?

    /// Example sentence
    var exampleSentence: String?

    /// IPA transcription (for pronunciation submissions)
    var ipaTranscription: String?

    /// Respelling (for pronunciation submissions)
    var respelling: String?

    /// Audio data (for pronunciation submissions)
    @Attribute(.externalStorage) var audioData: Data?

    /// Language code
    var languageCode: String

    /// Accent/dialect code (for pronunciation submissions)
    var accentDialectCode: String?

    /// Submitter's user record ID (anonymized)
    var submitterID: String

    /// Current moderation status
    var moderationStatus: String

    /// Moderator notes (if any)
    var moderatorNotes: String?

    /// Date submitted
    var submittedAt: Date

    /// Date moderation was completed
    var moderatedAt: Date?

    init(
        submissionType: SubmissionType,
        wordSpelling: String,
        languageCode: String,
        submitterID: String
    ) {
        self.submissionID = UUID().uuidString
        self.submissionType = submissionType.rawValue
        self.wordSpelling = wordSpelling
        self.languageCode = languageCode
        self.submitterID = submitterID
        self.moderationStatus = ModerationStatus.pending.rawValue
        self.submittedAt = Date()
    }
}

// MARK: - Submission Types

extension UserSubmission {
    enum SubmissionType: String, CaseIterable {
        case word
        case definition
        case pronunciation

        var displayName: String {
            rawValue.capitalized
        }

        var description: String {
            switch self {
            case .word: return "Submit a new word to the dictionary"
            case .definition: return "Add a definition for an existing word"
            case .pronunciation: return "Record a pronunciation for a word"
            }
        }

        var pointsAwarded: Int {
            switch self {
            case .word: return 100
            case .definition: return 100
            case .pronunciation: return 150 // +50 for audio
            }
        }
    }

    enum ModerationStatus: String, CaseIterable {
        case pending
        case approved
        case rejected
        case needsRevision

        var displayName: String {
            switch self {
            case .pending: return "Pending Review"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .needsRevision: return "Needs Revision"
            }
        }
    }

    /// Returns the submission type as an enum
    var type: SubmissionType? {
        SubmissionType(rawValue: submissionType)
    }

    /// Returns the moderation status as an enum
    var status: ModerationStatus? {
        ModerationStatus(rawValue: moderationStatus)
    }

    /// Whether the submission includes audio
    var hasAudio: Bool {
        audioData != nil
    }

    /// Points that would be awarded if approved
    var potentialPoints: Int {
        var points = type?.pointsAwarded ?? 100
        if hasAudio {
            points += 50
        }
        return points
    }
}
