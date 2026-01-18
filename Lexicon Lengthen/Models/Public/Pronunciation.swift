//
//  Pronunciation.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a pronunciation of a word in a specific accent/dialect.
/// Users can master each pronunciation independently.
@Model
final class Pronunciation {
    /// The word this pronunciation is for
    var word: Word?

    /// The accent/dialect of this pronunciation
    var accentDialect: AccentDialect?

    /// IPA transcription (e.g., "/ˈlɛksɪkɒn/")
    var ipaTranscription: String?

    /// Phonetic respelling (e.g., "LEK-si-kon")
    var respelling: String?

    /// Primary audio recording data
    @Attribute(.externalStorage) var audioData: Data?

    /// Reversed audio for backwards playback feature
    @Attribute(.externalStorage) var audioBackwardsData: Data?

    /// JSON map of emotional variants: {"happy": "url", "sad": "url", "angry": "url"}
    var emotionalVariantsJSON: String?

    /// Text optimized for TTS (may differ from spelling for better pronunciation)
    var ttsOptimizedText: String?

    /// Whether this pronunciation has been approved for public use
    var isApproved: Bool

    /// Date the pronunciation was created
    var createdAt: Date

    init(
        word: Word? = nil,
        accentDialect: AccentDialect? = nil,
        ipaTranscription: String? = nil,
        respelling: String? = nil,
        audioData: Data? = nil,
        ttsOptimizedText: String? = nil,
        isApproved: Bool = false
    ) {
        self.word = word
        self.accentDialect = accentDialect
        self.ipaTranscription = ipaTranscription
        self.respelling = respelling
        self.audioData = audioData
        self.ttsOptimizedText = ttsOptimizedText
        self.isApproved = isApproved
        self.createdAt = Date()
    }
}

// MARK: - Emotional Variants

extension Pronunciation {
    enum Emotion: String, CaseIterable {
        case neutral
        case happy
        case sad
        case angry
        case excited
        case whispered

        var displayName: String {
            rawValue.capitalized
        }
    }

    /// Decodes emotional variants from JSON storage
    var emotionalVariants: [Emotion: String]? {
        guard let json = emotionalVariantsJSON,
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }

        var result: [Emotion: String] = [:]
        for (key, value) in dict {
            if let emotion = Emotion(rawValue: key) {
                result[emotion] = value
            }
        }
        return result
    }

    /// Encodes emotional variants to JSON for storage
    func setEmotionalVariants(_ variants: [Emotion: String]) {
        let dict = Dictionary(uniqueKeysWithValues: variants.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict),
           let json = String(data: data, encoding: .utf8) {
            emotionalVariantsJSON = json
        }
    }
}
