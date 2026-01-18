//
//  Language.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

@Model
final class Language {
    /// ISO 639-1 code (e.g., "en", "es", "fr")
    @Attribute(.unique) var code: String

    /// English name of the language
    var name: String

    /// Name in the native language
    var nativeName: String

    /// Whether this language is currently active/available
    var isActive: Bool

    /// Spellings in this language
    @Relationship(deleteRule: .cascade, inverse: \Spelling.language)
    var spellings: [Spelling] = []

    /// Accent/dialect variants for this language
    @Relationship(deleteRule: .cascade, inverse: \AccentDialect.language)
    var accentDialects: [AccentDialect] = []

    /// Sentence templates for this language
    @Relationship(deleteRule: .cascade, inverse: \SentenceTemplate.language)
    var sentenceTemplates: [SentenceTemplate] = []

    init(code: String, name: String, nativeName: String, isActive: Bool = true) {
        self.code = code
        self.name = name
        self.nativeName = nativeName
        self.isActive = isActive
    }
}
