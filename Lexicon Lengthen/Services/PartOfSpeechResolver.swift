//
//  PartOfSpeechResolver.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import Foundation

actor PartOfSpeechResolver {
    static let shared = PartOfSpeechResolver()

    private var cache: [String: String] = [:]

    func suggest(for word: String) async -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 2 else { return nil }

        if let cached = cache[trimmed] {
            return cached
        }

        guard let url = makeDatamuseURL(for: trimmed) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let entries = try JSONDecoder().decode([DatamuseEntry].self, from: data)
            let suggestion = entries.compactMap { mapTags($0.tags) }.first
            if let suggestion {
                cache[trimmed] = suggestion
            }
            return suggestion
        } catch {
            return nil
        }
    }

    private func makeDatamuseURL(for word: String) -> URL? {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = [
            URLQueryItem(name: "sp", value: word),
            URLQueryItem(name: "md", value: "p"),
            URLQueryItem(name: "max", value: "1")
        ]
        return components?.url
    }

    private func mapTags(_ tags: [String]?) -> String? {
        guard let tags else { return nil }
        if tags.contains("n") { return "noun" }
        if tags.contains("v") { return "verb" }
        if tags.contains("adj") { return "adjective" }
        if tags.contains("adv") { return "adverb" }
        return nil
    }
}

private struct DatamuseEntry: Decodable {
    let tags: [String]?
}
