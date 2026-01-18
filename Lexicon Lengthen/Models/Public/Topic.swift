//
//  Topic.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import SwiftData

/// Represents a topic/category for organizing words.
@Model
final class Topic {
    /// Topic name
    @Attribute(.spotlight) var name: String

    /// Parent topic for hierarchical organization
    var parentTopic: Topic?

    /// SF Symbol icon name
    var iconName: String

    /// Color hex code for display
    var colorHex: String

    /// Child topics
    @Relationship(deleteRule: .cascade, inverse: \Topic.parentTopic)
    var childTopics: [Topic] = []

    /// Word associations for this topic
    @Relationship(deleteRule: .cascade, inverse: \WordTopic.topic)
    var wordTopics: [WordTopic] = []

    init(name: String, parentTopic: Topic? = nil, iconName: String = "tag", colorHex: String = "#007AFF") {
        self.name = name
        self.parentTopic = parentTopic
        self.iconName = iconName
        self.colorHex = colorHex
    }
}

// MARK: - Convenience Extensions

extension Topic {
    /// Returns all words associated with this topic
    var words: [Word] {
        wordTopics.compactMap { $0.word }
    }

    /// Returns the number of words in this topic
    var wordCount: Int {
        wordTopics.count
    }

    /// Returns true if this is a root-level topic (no parent)
    var isRootTopic: Bool {
        parentTopic == nil
    }

    /// Returns the full path of topic names from root to this topic
    var fullPath: [String] {
        var path: [String] = [name]
        var current = parentTopic
        while let parent = current {
            path.insert(parent.name, at: 0)
            current = parent.parentTopic
        }
        return path
    }
}

// MARK: - Common Topics

extension Topic {
    enum CommonTopic: String, CaseIterable {
        case science = "Science"
        case technology = "Technology"
        case arts = "Arts"
        case humanities = "Humanities"
        case business = "Business"
        case medicine = "Medicine"
        case law = "Law"
        case sports = "Sports"
        case food = "Food"
        case nature = "Nature"
        case travel = "Travel"
        case education = "Education"

        var iconName: String {
            switch self {
            case .science: return "atom"
            case .technology: return "cpu"
            case .arts: return "paintpalette"
            case .humanities: return "book"
            case .business: return "briefcase"
            case .medicine: return "cross.case"
            case .law: return "scale.3d"
            case .sports: return "sportscourt"
            case .food: return "fork.knife"
            case .nature: return "leaf"
            case .travel: return "airplane"
            case .education: return "graduationcap"
            }
        }

        var colorHex: String {
            switch self {
            case .science: return "#5856D6"
            case .technology: return "#007AFF"
            case .arts: return "#FF2D55"
            case .humanities: return "#AF52DE"
            case .business: return "#34C759"
            case .medicine: return "#FF3B30"
            case .law: return "#8E8E93"
            case .sports: return "#FF9500"
            case .food: return "#FFCC00"
            case .nature: return "#30B0C7"
            case .travel: return "#5AC8FA"
            case .education: return "#FF6B6B"
            }
        }
    }
}
