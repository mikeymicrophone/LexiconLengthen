//
//  LexemeGroup.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import Foundation
import SwiftData

/// Represents a group of derivationally related words (a word family).
@Model
final class LexemeGroup {
    /// Base or root form used to label the group (e.g., "caution")
    @Attribute(.spotlight) var rootText: String

    /// Optional notes about the group
    var notes: String?

    /// Words that belong to this group
    @Relationship(deleteRule: .nullify, inverse: \Word.lexemeGroup)
    var words: [Word] = []

    init(rootText: String, notes: String? = nil) {
        self.rootText = rootText
        self.notes = notes
    }
}
