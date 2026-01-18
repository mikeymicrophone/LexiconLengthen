//
//  Definition.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a single definition of a word. Users master each definition independently.
@Model
final class Definition {
    /// The word this definition belongs to
    var word: Word?

    /// The definition text
    @Attribute(.spotlight) var definitionText: String

    /// Length of the definition (used for points calculation)
    var definitionLength: Int

    /// Example sentence using the word
    var exampleSentence: String?

    /// Register (formal/informal/slang/archaic/literary)
    var register: String

    /// Domain/field (medicine/law/technology/etc.)
    var domain: String?

    /// Sort order for displaying definitions
    var sortOrder: Int

    /// Whether this definition has been approved for public use
    var isApproved: Bool

    /// Date the definition was created
    var createdAt: Date

    init(
        word: Word? = nil,
        definitionText: String,
        exampleSentence: String? = nil,
        register: String = "neutral",
        domain: String? = nil,
        sortOrder: Int = 0,
        isApproved: Bool = false
    ) {
        self.word = word
        self.definitionText = definitionText
        self.definitionLength = definitionText.count
        self.exampleSentence = exampleSentence
        self.register = register
        self.domain = domain
        self.sortOrder = sortOrder
        self.isApproved = isApproved
        self.createdAt = Date()
    }
}

// MARK: - Register Types

extension Definition {
    enum Register: String, CaseIterable {
        case formal
        case neutral
        case informal
        case slang
        case archaic
        case literary
        case technical

        var displayName: String {
            rawValue.capitalized
        }
    }
}
