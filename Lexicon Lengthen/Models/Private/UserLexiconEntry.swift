//
//  UserLexiconEntry.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import Foundation
import SwiftData

/// Tracks which words are in the user's personal lexicon.
@Model
final class UserLexiconEntry {
    /// Reference to the public word (stored as ID string for CloudKit)
    var wordID: String

    /// Relationship to the word
    @Relationship(deleteRule: .nullify)
    var word: Word?

    /// Date the word was added to the lexicon
    var addedAt: Date

    init(wordID: String, word: Word?, addedAt: Date = Date()) {
        self.wordID = wordID
        self.word = word
        self.addedAt = addedAt
    }
}
