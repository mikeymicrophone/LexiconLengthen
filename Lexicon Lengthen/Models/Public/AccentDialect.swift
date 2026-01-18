//
//  AccentDialect.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents an accent or dialect variant within a language.
@Model
final class AccentDialect {
    /// The language this accent/dialect belongs to
    var language: Language?

    /// Unique code (e.g., "en-GB-RP", "en-US-General", "es-MX")
    @Attribute(.unique) var code: String

    /// Display name (e.g., "British RP", "General American", "Mexican Spanish")
    var name: String

    /// Geographic region associated with this accent
    var region: String

    /// Pronunciations using this accent/dialect
    @Relationship(deleteRule: .cascade, inverse: \Pronunciation.accentDialect)
    var pronunciations: [Pronunciation] = []

    init(language: Language? = nil, code: String, name: String, region: String) {
        self.language = language
        self.code = code
        self.name = name
        self.region = region
    }
}

// MARK: - Common Accent Codes

extension AccentDialect {
    /// Standard accent codes for English
    enum EnglishAccent: String, CaseIterable {
        case britishRP = "en-GB-RP"
        case britishGeneral = "en-GB-General"
        case americanGeneral = "en-US-General"
        case americanSouthern = "en-US-Southern"
        case australian = "en-AU"
        case irish = "en-IE"
        case scottish = "en-GB-Scottish"

        var displayName: String {
            switch self {
            case .britishRP: return "British RP"
            case .britishGeneral: return "British (General)"
            case .americanGeneral: return "American (General)"
            case .americanSouthern: return "American (Southern)"
            case .australian: return "Australian"
            case .irish: return "Irish"
            case .scottish: return "Scottish"
            }
        }

        var region: String {
            switch self {
            case .britishRP, .britishGeneral: return "United Kingdom"
            case .americanGeneral, .americanSouthern: return "United States"
            case .australian: return "Australia"
            case .irish: return "Ireland"
            case .scottish: return "Scotland"
            }
        }
    }
}
