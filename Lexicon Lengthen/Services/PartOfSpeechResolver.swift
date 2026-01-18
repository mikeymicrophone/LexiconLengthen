//
//  PartOfSpeechResolver.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import Foundation

actor PartOfSpeechResolver {
    static let shared = PartOfSpeechResolver()

    private var cache: [String: WordLookupSuggestion] = [:]

    func lookup(for word: String) async -> WordLookupSuggestion {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 2 else {
            return WordLookupSuggestion(partOfSpeech: nil, ipa: nil)
        }

        if let cached = cache[trimmed] {
            return cached
        }

        guard let url = makeDatamuseURL(for: trimmed) else {
            return WordLookupSuggestion(partOfSpeech: nil, ipa: nil)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let entries = try JSONDecoder().decode([DatamuseEntry].self, from: data)
            for entry in entries {
                let partOfSpeech = mapTags(entry.tags)
                let ipa = normalizeIpa(entry.pron?.value)
                if partOfSpeech != nil || ipa != nil {
                    let suggestion = WordLookupSuggestion(partOfSpeech: partOfSpeech, ipa: ipa)
                    cache[trimmed] = suggestion
                    return suggestion
                }
            }
            return WordLookupSuggestion(partOfSpeech: nil, ipa: nil)
        } catch {
            return WordLookupSuggestion(partOfSpeech: nil, ipa: nil)
        }
    }

    private func makeDatamuseURL(for word: String) -> URL? {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = [
            URLQueryItem(name: "sp", value: word),
            URLQueryItem(name: "md", value: "rp"),
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

    private func normalizeIpa(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("/") {
            return trimmed
        }
        return "/\(trimmed)/"
    }
}

struct WordLookupSuggestion: Equatable {
    let partOfSpeech: String?
    let ipa: String?
}

private struct DatamuseEntry: Decodable {
    let tags: [String]?
    let pron: DatamusePronunciation?
}

private struct DatamusePronunciation: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
            return
        }
        if let dict = try? container.decode([String: String].self) {
            value = dict["ipa"] ?? dict["pron"] ?? dict["phonetic"]
            return
        }
        value = nil
    }
}
