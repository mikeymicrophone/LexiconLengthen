//
//  SentenceBuilderView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import SwiftUI
import SwiftData

struct SentenceBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @Query private var lexiconEntries: [UserLexiconEntry]
    @Query(sort: \SentenceTemplate.createdAt, order: .reverse) private var templates: [SentenceTemplate]
    @Query private var userProfiles: [UserProfile]

    @EnvironmentObject private var audioManager: AudioManager

    @State private var selectedTemplateID: String?
    @State private var slotAssignments: [Word?] = []
    @State private var selectedSlotIndex: Int?
    @State private var searchText = ""
    @State private var statusMessage: String?

    private var templateOptions: [TemplateOption] {
        var options: [TemplateOption] = templates.compactMap { template in
            let templateID = template.persistentModelID.storeIdentifier ?? UUID().uuidString
            return TemplateOption(
                id: "template:\(templateID)",
                name: template.structure,
                templateText: template.templateText,
                slots: template.partsOfSpeechRequired
            )
        }

        let builtIns = builtInTemplates.filter { builtin in
            !options.contains(where: { $0.templateText == builtin.templateText })
        }
        options.append(contentsOf: builtIns)

        return options
    }

    private var builtInTemplates: [TemplateOption] {
        [
            TemplateOption(
                id: "builtin:subject-verb-object-adverb",
                name: "Subject Verb Object Adverb",
                templateText: "The {subject} {verb} the {object} {adverb}.",
                slots: ["subject", "verb", "object", "adverb"]
            ),
            TemplateOption(
                id: "builtin:subject-verb",
                name: "Subject Verb",
                templateText: "The {subject} {verb}.",
                slots: ["subject", "verb"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-object",
                name: "Subject Verb Object",
                templateText: "The {subject} {verb} the {object}.",
                slots: ["subject", "verb", "object"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-adverb",
                name: "Subject Verb Adverb",
                templateText: "The {subject} {verb} {adverb}.",
                slots: ["subject", "verb", "adverb"]
            ),
            TemplateOption(
                id: "builtin:adjective-subject-verb",
                name: "Adjective Subject Verb",
                templateText: "The {adjective} {subject} {verb}.",
                slots: ["adjective", "subject", "verb"]
            ),
            TemplateOption(
                id: "builtin:adjective-subject-verb-object",
                name: "Adjective Subject Verb Object",
                templateText: "The {adjective} {subject} {verb} the {object}.",
                slots: ["adjective", "subject", "verb", "object"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-adjective",
                name: "Subject Verb Adjective",
                templateText: "The {subject} {verb} {adjective}.",
                slots: ["subject", "verb", "adjective"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-adjective-object",
                name: "Subject Verb Adjective Object",
                templateText: "The {subject} {verb} the {adjective} {object}.",
                slots: ["subject", "verb", "adjective", "object"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-object-adjective",
                name: "Subject Verb Object Adjective",
                templateText: "The {subject} {verb} the {object} as {adjective}.",
                slots: ["subject", "verb", "object", "adjective"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-noun",
                name: "Subject Verb Noun",
                templateText: "The {subject} {verb} a {noun}.",
                slots: ["subject", "verb", "noun"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-object-noun",
                name: "Subject Verb Object Noun",
                templateText: "The {subject} {verb} the {object} near the {noun}.",
                slots: ["subject", "verb", "object", "noun"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-object-after-noun",
                name: "Subject Verb Object After Noun",
                templateText: "The {subject} {verb} the {object} after the {noun}.",
                slots: ["subject", "verb", "object", "noun"]
            ),
            TemplateOption(
                id: "builtin:subject-verb-object-before-noun",
                name: "Subject Verb Object Before Noun",
                templateText: "The {subject} {verb} the {object} before the {noun}.",
                slots: ["subject", "verb", "object", "noun"]
            )
        ]
    }

    private var selectedTemplate: TemplateOption? {
        guard let selectedTemplateID else {
            return templateOptions.first
        }
        return templateOptions.first { $0.id == selectedTemplateID } ?? templateOptions.first
    }

    private var filteredWords: [Word] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pool = availableWords
        let slotFilter = activeSlotCategory
        return pool.filter { word in
            let matchesSearch = trimmed.isEmpty ||
            word.spellingText.localizedCaseInsensitiveContains(trimmed) ||
            word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
            let matchesSlot = slotFilter == nil || matchesSlotFilter(word: word, category: slotFilter)
            return matchesSearch && matchesSlot
        }
    }

    private var sentencePreview: String {
        guard let template = selectedTemplate else { return "" }
        let words = slotAssignments.enumerated().map { index, word in
            let slotLabel = template.slots.indices.contains(index) ? template.slots[index] : ""
            return displayWord(for: word, slotLabel: slotLabel)
        }
        return template.fill(with: words)
    }

    private var isSentenceComplete: Bool {
        guard let template = selectedTemplate else { return false }
        guard slotAssignments.count == template.slots.count else { return false }
        return slotAssignments.allSatisfy { $0 != nil }
    }

    private var templateModel: SentenceTemplate? {
        guard let selectedTemplateID,
              selectedTemplateID.hasPrefix("template:") else {
            return nil
        }
        let templateID = selectedTemplateID.replacingOccurrences(of: "template:", with: "")
        return templates.first {
            $0.persistentModelID.storeIdentifier == templateID
        }
    }

    private var lexiconWords: [Word] {
        lexiconEntries.compactMap { $0.word }
    }

    private var availableWords: [Word] {
        let base = lexiconWords
        guard let category = activeSlotCategory, category == .adjective || category == .adverb else {
            return base
        }

        var expanded = base
        let groupWords = base.compactMap { $0.lexemeGroup?.words }.flatMap { $0 }
        for word in groupWords where !expanded.contains(where: { $0.id == word.id }) {
            expanded.append(word)
        }
        return expanded
    }

    private var activeSlotCategory: SlotCategory? {
        guard let template = selectedTemplate,
              let index = selectedSlotIndex,
              template.slots.indices.contains(index) else {
            return nil
        }
        return slotCategory(for: template.slots[index])
    }

    var body: some View {
        VStack(spacing: 16) {
            if templateOptions.isEmpty {
                ContentUnavailableView(
                    "No Templates",
                    systemImage: "text.book.closed",
                    description: Text("Add a sentence template to start.")
                )
            } else {
                Picker("Template", selection: $selectedTemplateID) {
                    ForEach(templateOptions) { template in
                        Text(template.name).tag(template.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                Text(sentencePreview)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if isSentenceComplete {
                    HStack(spacing: 12) {
                        Button {
                            saveSentence()
                        } label: {
                            Label("Save Sentence", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            if audioManager.isPlaying {
                                audioManager.stopPlayback()
                            } else {
                                audioManager.speakText(sentencePreview)
                            }
                        } label: {
                            Label("Narrate", systemImage: audioManager.isPlaying ? "stop.circle.fill" : "speaker.wave.2.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }

            if let template = selectedTemplate {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(template.slots.enumerated()), id: \.offset) { index, slot in
                            slotView(label: slot, index: index)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Word Bank")
                    .font(.headline)
                    .padding(.horizontal)

                if let category = activeSlotCategory {
                    Text("Filtering for \(category.displayName) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWords) { word in
                            wordRow(word)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Sentence Builder")
        .searchable(text: $searchText, prompt: "Search words")
        .onAppear {
            if selectedTemplateID == nil {
                selectedTemplateID = templateOptions.first?.id
            }
            syncSlots()
        }
        .onChange(of: selectedTemplateID) { _, _ in
            syncSlots()
        }
        .onChange(of: templates) { _, _ in
            if selectedTemplateID == nil {
                selectedTemplateID = templateOptions.first?.id
            }
            syncSlots()
        }
    }

    private func syncSlots() {
        guard let template = selectedTemplate else {
            slotAssignments = []
            selectedSlotIndex = nil
            return
        }
        if slotAssignments.count != template.slots.count {
            slotAssignments = Array(repeating: nil, count: template.slots.count)
        }
        if selectedSlotIndex == nil, !template.slots.isEmpty {
            selectedSlotIndex = 0
        }
    }

    @ViewBuilder
    private func slotView(label: String, index: Int) -> some View {
        let assigned = slotAssignments.indices.contains(index) ? slotAssignments[index] : nil
        let isSelected = selectedSlotIndex == index
        let display = displayWord(for: assigned, slotLabel: label)

        VStack(spacing: 8) {
            Text(label.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : .secondary.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .frame(width: 160, height: 80)

                if let word = assigned {
                    VStack(spacing: 4) {
                        Text(display)
                            .font(.headline)
                        Text(word.partOfSpeech)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Drop word")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if assigned != nil {
                Button("Clear") {
                    slotAssignments[index] = nil
                }
                .font(.caption)
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let key = items.first, let word = resolveWord(from: key) else {
                return false
            }
            if slotAssignments.indices.contains(index) {
                slotAssignments[index] = word
                advanceSelection(from: index)
                return true
            }
            return false
        }
        .onTapGesture {
            selectedSlotIndex = index
        }
    }

    @ViewBuilder
    private func wordRow(_ word: Word) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.spellingText)
                    .font(.headline)
                Text(word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "hand.draw")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .draggable(wordKey(for: word))
        .onTapGesture {
            assignToSelectedSlot(word)
        }
    }

    private func wordKey(for word: Word) -> String {
        let spelling = word.spellingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pos = word.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if spelling.isEmpty {
            return pos
        }
        return "\(spelling)::\(pos)"
    }

    private func resolveWord(from key: String) -> Word? {
        let parts = key.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        if parts.count >= 3 {
            let spelling = String(parts[0])
            let pos = String(parts[2])
            return words.first {
                $0.spellingText.lowercased() == spelling && $0.partOfSpeech.lowercased() == pos
            } ?? words.first { $0.spellingText.lowercased() == spelling }
        }
        return words.first { $0.spellingText.lowercased() == key.lowercased() }
    }

    private func assignToSelectedSlot(_ word: Word) {
        guard let index = selectedSlotIndex,
              slotAssignments.indices.contains(index) else {
            return
        }
        slotAssignments[index] = word
        advanceSelection(from: index)
        statusMessage = nil
    }

    private func slotCategory(for label: String) -> SlotCategory? {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("adverb") { return .adverb }
        if normalized.contains("verb") { return .verb }
        if normalized.contains("adj") { return .adjective }
        if normalized.contains("subject") || normalized.contains("object") || normalized.contains("noun") {
            return .noun
        }
        return nil
    }

    private func matchesSlotFilter(word: Word, category: SlotCategory?) -> Bool {
        guard let category else { return true }
        let pos = word.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch category {
        case .noun:
            return pos.contains("noun") || pos.contains("pronoun")
        case .verb:
            return pos.contains("verb")
        case .adjective:
            return pos.contains("adjective") || pos.contains("adj")
        case .adverb:
            return pos.contains("adverb") || pos.contains("adv") ||
            pos.contains("adjective") || pos.contains("adj")
        }
    }

    private func displayWord(for word: Word?, slotLabel: String) -> String {
        guard let word else { return "____" }
        if slotCategory(for: slotLabel) == .verb {
            let subject = subjectWordText()
            return conjugatePresent(verb: word.spellingText, subject: subject)
        }
        return word.spellingText
    }

    private func subjectWordText() -> String? {
        guard let template = selectedTemplate else { return nil }
        for (index, slot) in template.slots.enumerated() {
            let label = slot.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if label.contains("subject"),
               let word = slotAssignments[safe: index],
               let resolved = word {
                return resolved.spellingText
            }
        }
        return nil
    }

    private func conjugatePresent(verb: String, subject: String?) -> String {
        let trimmedVerb = verb.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedVerb.isEmpty else { return verb }

        let pieces = trimmedVerb.split(separator: " ")
        let base = String(pieces.first ?? "")
        let rest = pieces.dropFirst().joined(separator: " ")

        let lowerBase = base.lowercased()
        let subjectLower = subject?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        let thirdPerson = isThirdPersonSingular(subjectLower)
        let conjugated: String
        if thirdPerson {
            conjugated = conjugateThirdPersonSingular(verb: lowerBase, original: base)
        } else {
            conjugated = base
        }

        if rest.isEmpty {
            return conjugated
        }
        return "\(conjugated) \(rest)"
    }

    private func isThirdPersonSingular(_ subject: String) -> Bool {
        guard !subject.isEmpty else { return false }
        if ["i", "you", "we", "they"].contains(subject) { return false }
        if ["he", "she", "it"].contains(subject) { return true }
        return true
    }

    private func conjugateThirdPersonSingular(verb: String, original: String) -> String {
        let lower = verb.lowercased()
        let irregular: [String: String] = [
            "be": "is",
            "have": "has",
            "do": "does",
            "go": "goes"
        ]
        if let replacement = irregular[lower] {
            return matchCase(of: original, replacement: replacement)
        }

        if lower.hasSuffix("ch") || lower.hasSuffix("sh") ||
            lower.hasSuffix("s") || lower.hasSuffix("x") || lower.hasSuffix("z") {
            return matchCase(of: original, replacement: "\(lower)es")
        }

        if lower.hasSuffix("y") && lower.count > 1 {
            let beforeY = lower[lower.index(before: lower.endIndex)]
            if !"aeiou".contains(beforeY) {
                let stem = lower.dropLast()
                return matchCase(of: original, replacement: "\(stem)ies")
            }
        }

        return matchCase(of: original, replacement: "\(lower)s")
    }

    private func matchCase(of original: String, replacement: String) -> String {
        if original == original.uppercased() {
            return replacement.uppercased()
        }
        if original.first?.isUppercase == true {
            return replacement.prefix(1).uppercased() + replacement.dropFirst()
        }
        return replacement
    }

    private func advanceSelection(from index: Int) {
        guard !slotAssignments.isEmpty else {
            selectedSlotIndex = nil
            return
        }

        let nextIndices = Array((index + 1)..<slotAssignments.count) + Array(0..<index)
        if let next = nextIndices.first(where: { slotAssignments[$0] == nil }) {
            selectedSlotIndex = next
        } else {
            selectedSlotIndex = nil
        }
    }

    private func saveSentence() {
        guard let template = selectedTemplate, isSentenceComplete else {
            return
        }

        let words = slotAssignments.enumerated().map { index, word in
            let slotLabel = template.slots.indices.contains(index) ? template.slots[index] : ""
            return displayWord(for: word, slotLabel: slotLabel)
        }
        let wordIDs = slotAssignments.map { $0?.persistentModelID.storeIdentifier ?? "" }
        let totalLetters = words.reduce(0) { count, text in
            count + text.filter { $0.isLetter }.count
        }

        let points: Int
        if let templateModel {
            points = PointsCalculator.pointsForTemplateCompleted(
                template: templateModel,
                wordCount: words.count,
                totalLetterCount: totalLetters
            )
        } else {
            points = PointsCalculator.pointsForSentenceCreated(
                wordCount: words.count,
                totalLetterCount: totalLetters
            )
        }

        let sentence = UserSentence(
            sentenceText: sentencePreview,
            templateID: selectedTemplateID,
            wordIDs: wordIDs,
            wordSpellings: words,
            pointsEarned: points
        )
        modelContext.insert(sentence)

        if let profile = userProfiles.first {
            profile.recordSentenceCreated()
            profile.addPoints(points)
            profile.recordActivity()
        }

        try? modelContext.save()
        statusMessage = "Saved sentence."
    }
}

private struct TemplateOption: Identifiable, Equatable {
    let id: String
    let name: String
    let templateText: String
    let slots: [String]

    func fill(with words: [String]) -> String {
        guard templateText.contains("{") else {
            return words.joined(separator: " ")
        }

        var result = templateText
        var currentIndex = result.startIndex
        var replacements = words

        while let open = result[currentIndex...].firstIndex(of: "{"),
              let close = result[open...].firstIndex(of: "}") {
            let replacement = replacements.isEmpty ? "____" : replacements.removeFirst()
            result.replaceSubrange(open...close, with: replacement)
            currentIndex = result.index(after: open)
        }

        return result
    }
}

private enum SlotCategory {
    case noun
    case verb
    case adjective
    case adverb

    var displayName: String {
        switch self {
        case .noun: return "noun/pronoun"
        case .verb: return "verb"
        case .adjective: return "adjective"
        case .adverb: return "adverb"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
