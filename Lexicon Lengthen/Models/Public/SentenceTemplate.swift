//
//  SentenceTemplate.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a sentence template that users can fill in with words.
@Model
final class SentenceTemplate {
    /// The language this template is for
    var language: Language?

    /// Template text with placeholders (e.g., "The {noun} {verb} quickly.")
    var templateText: String

    /// Grammatical structure (e.g., "DET-NOUN-VERB-ADV")
    var structure: String

    /// JSON array of required parts of speech for each slot
    var partsOfSpeechRequiredJSON: String

    /// Difficulty level (1-5)
    var difficultyLevel: Int

    /// Base points value for completing this template
    var pointsValue: Int

    /// Whether this template is active/available
    var isActive: Bool

    /// Date the template was created
    var createdAt: Date

    init(
        language: Language? = nil,
        templateText: String,
        structure: String,
        partsOfSpeechRequired: [String],
        difficultyLevel: Int = 3,
        pointsValue: Int = 25
    ) {
        self.language = language
        self.templateText = templateText
        self.structure = structure
        self.partsOfSpeechRequiredJSON = (try? JSONEncoder().encode(partsOfSpeechRequired))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.difficultyLevel = difficultyLevel
        self.pointsValue = pointsValue
        self.isActive = true
        self.createdAt = Date()
    }
}

// MARK: - Convenience Extensions

extension SentenceTemplate {
    /// Decodes parts of speech required from JSON storage
    var partsOfSpeechRequired: [String] {
        guard let data = partsOfSpeechRequiredJSON.data(using: .utf8),
              let parts = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return parts
    }

    /// Sets parts of speech required and encodes to JSON
    func setPartsOfSpeechRequired(_ parts: [String]) {
        if let data = try? JSONEncoder().encode(parts),
           let json = String(data: data, encoding: .utf8) {
            partsOfSpeechRequiredJSON = json
        }
    }

    /// Returns the number of word slots in this template
    var slotCount: Int {
        partsOfSpeechRequired.count
    }

    /// Extracts placeholder positions from template text
    var placeholders: [String] {
        var results: [String] = []
        var current = templateText.startIndex

        while let openBrace = templateText[current...].firstIndex(of: "{"),
              let closeBrace = templateText[openBrace...].firstIndex(of: "}") {
            let placeholder = String(templateText[templateText.index(after: openBrace)..<closeBrace])
            results.append(placeholder)
            current = templateText.index(after: closeBrace)
        }

        return results
    }

    /// Fills the template with provided words
    func fill(with words: [String]) -> String {
        var result = templateText
        let placeholderList = placeholders

        for (index, word) in words.enumerated() where index < placeholderList.count {
            let placeholder = "{\(placeholderList[index])}"
            result = result.replacingOccurrences(of: placeholder, with: word)
        }

        return result
    }
}
