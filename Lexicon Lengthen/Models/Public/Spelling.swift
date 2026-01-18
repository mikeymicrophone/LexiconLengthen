//
//  Spelling.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a unique spelling in a language. Homographs (words spelled the same
/// but with different meanings) share the same Spelling but have different Word entries.
@Model
final class Spelling {
    /// The actual spelling text (e.g., "lead")
    var text: String

    /// Lowercase version for case-insensitive search
    @Attribute(.spotlight) var textLowercase: String

    /// Number of letters (used for points calculation)
    var letterCount: Int

    /// The language this spelling belongs to
    var language: Language?

    /// Words that use this spelling (may include homographs)
    @Relationship(deleteRule: .cascade, inverse: \Word.spelling)
    var words: [Word] = []

    init(text: String, language: Language? = nil) {
        self.text = text
        self.textLowercase = text.lowercased()
        self.letterCount = text.filter { $0.isLetter }.count
        self.language = language
    }
}
