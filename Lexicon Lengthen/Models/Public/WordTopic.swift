//
//  WordTopic.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Junction table linking words to topics with a relevance score.
@Model
final class WordTopic {
    /// The word being categorized
    var word: Word?

    /// The topic the word belongs to
    var topic: Topic?

    /// Relevance score (0.0 to 1.0, higher = more relevant to topic)
    var relevanceScore: Double

    init(word: Word? = nil, topic: Topic? = nil, relevanceScore: Double = 1.0) {
        self.word = word
        self.topic = topic
        self.relevanceScore = min(1.0, max(0.0, relevanceScore))
    }
}
