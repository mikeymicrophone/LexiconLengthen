//
//  DictionaryPreferencesView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct DictionaryPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allWords: [Word]
    @Query private var lexiconEntries: [UserLexiconEntry]

    @State private var listScope: WordListScope = .lexicon
    @State private var searchText = ""
    @State private var editingWord: Word?
    @State private var deletingWord: Word?
    @State private var statusMessage: String?

    private enum WordListScope: String, CaseIterable, Identifiable {
        case lexicon = "Lexicon"
        case device = "Device"
        case notInLexicon = "Not in Lexicon"

        var id: String { rawValue }
    }

    private var lexiconWordIDs: Set<Word.ID> {
        LexiconWordService.lexiconWordIDs(from: lexiconEntries)
    }

    private func isInLexicon(_ word: Word) -> Bool {
        LexiconWordService.isInLexicon(word, entries: lexiconEntries)
    }

    private var baseWords: [Word] {
        switch listScope {
        case .lexicon:
            return uniqueWords(lexiconEntries.compactMap { $0.word })
        case .device:
            return uniqueWords(allWords)
        case .notInLexicon:
            return uniqueWords(allWords.filter { !isInLexicon($0) })
        }
    }

    private var filteredWords: [Word] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = baseWords.filter { word in
            trimmed.isEmpty ||
            word.spellingText.localizedCaseInsensitiveContains(trimmed) ||
            word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }
        return filtered.sorted {
            let left = $0.spellingText.localizedCaseInsensitiveCompare($1.spellingText)
            if left != .orderedSame {
                return left == .orderedAscending
            }
            let right = $0.partOfSpeech.localizedCaseInsensitiveCompare($1.partOfSpeech)
            return right == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    Picker("Scope", selection: $listScope) {
                        ForEach(WordListScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)

                    List {
                        Section {
                            HStack(spacing: 12) {
                                Button("Export to Clipboard") {
                                    exportLexicon()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Import from Clipboard") {
                                    importLexicon()
                                }
                                .buttonStyle(.bordered)
                            }
                        } footer: {
                            Text("Format: spelling<TAB>part of speech (one word per line).")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(filteredWords) { word in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(word.spellingText)
                                        .font(.headline)
                                    HStack(spacing: 6) {
                                        Text(word.partOfSpeech)
                                        if isInLexicon(word) {
                                            Label("Lexicon", systemImage: "bookmark.fill")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    editingWord = word
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)

                                if isInLexicon(word) {
                                    Button {
                                        removeFromLexicon(word)
                                    } label: {
                                        Image(systemName: "bookmark.slash")
                                    }
                                    .buttonStyle(.borderless)
                                }

                                Button {
                                    deletingWord = word
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .tint(.red)
                            }
                        }
                    }
                    .overlay {
                        if filteredWords.isEmpty {
                            ContentUnavailableView(
                                listScope == .lexicon ? "No Lexicon Words" : "No Words Found",
                                systemImage: "gearshape",
                                description: Text(listScope == .lexicon
                                    ? "Add words to your lexicon to edit them here."
                                    : "Try changing your filters or search.")
                            )
                        }
                    }
                    .listStyle(.insetGrouped)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }

                if let deletingWord {
                    DeleteWordConfirmationView(
                        word: deletingWord,
                        onDelete: { word in
                            deleteWord(word)
                            self.deletingWord = nil
                        },
                        onCancel: { self.deletingWord = nil }
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search lexicon")
        }
        .sheet(item: $editingWord) { word in
            EditWordSpellingView(word: word)
        }
    }

    private func removeFromLexicon(_ word: Word) {
        LexiconWordService.removeFromLexicon(word, entries: lexiconEntries, in: modelContext)
    }

    private func deleteWord(_ word: Word) {
        LexiconWordService.deleteWord(word, entries: lexiconEntries, in: modelContext)
    }

    private func uniqueWords(_ words: [Word]) -> [Word] {
        var seen = Set<Word.ID>()
        return words.filter { word in
            if seen.contains(word.id) { return false }
            seen.insert(word.id)
            return true
        }
    }

    private func exportLexicon() {
        let words = uniqueWords(lexiconEntries.compactMap { $0.word })
        let sorted = words.sorted {
            $0.spellingText.localizedCaseInsensitiveCompare($1.spellingText) == .orderedAscending
        }
        let lines = sorted.map { "\($0.spellingText)\t\($0.partOfSpeech)" }
        setClipboardText(lines.joined(separator: "\n"))
        statusMessage = "Copied \(lines.count) words to the clipboard."
    }

    private func importLexicon() {
        guard let text = clipboardText(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Clipboard is empty."
            return
        }

        let rows = text.components(separatedBy: .newlines)
        var addedCount = 0
        var skippedCount = 0
        var lexiconIDs = Set(lexiconEntries.compactMap { $0.word?.persistentModelID })
        let descriptor = FetchDescriptor<Spelling>()
        let existingSpellings = (try? modelContext.fetch(descriptor)) ?? []
        var spellingByLower = Dictionary(uniqueKeysWithValues: existingSpellings.map { ($0.textLowercase, $0) })

        for row in rows {
            guard let (spellingText, partOfSpeech) = parseImportRow(row) else { continue }
            let lower = spellingText.lowercased()

            let spelling = spellingByLower[lower] ?? Spelling(text: spellingText)
            if spelling.modelContext == nil {
                modelContext.insert(spelling)
                spellingByLower[lower] = spelling
            }

            let existingWord = spelling.words.first {
                $0.partOfSpeech.localizedCaseInsensitiveCompare(partOfSpeech) == .orderedSame
            }

            let word = existingWord ?? Word(spelling: spelling, partOfSpeech: partOfSpeech)
            if word.modelContext == nil {
                modelContext.insert(word)
            }

            if !lexiconIDs.contains(word.persistentModelID) {
                let entry = UserLexiconEntry(
                    wordID: word.persistentModelID.storeIdentifier ?? "",
                    word: word
                )
                modelContext.insert(entry)
                lexiconIDs.insert(word.persistentModelID)
                addedCount += 1
            } else {
                skippedCount += 1
            }
        }

        try? modelContext.save()
        statusMessage = "Imported \(addedCount) words. Skipped \(skippedCount)."
    }

    private func parseImportRow(_ row: String) -> (String, String)? {
        let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let tabRange = trimmed.range(of: "\t") {
            let spelling = trimmed[..<tabRange.lowerBound].trimmingCharacters(in: .whitespaces)
            let part = trimmed[tabRange.upperBound...].trimmingCharacters(in: .whitespaces)
            if spelling.isEmpty {
                return nil
            }
            return (spelling, part.isEmpty ? "noun" : part)
        }

        return (trimmed, "noun")
    }

    private func clipboardText() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }

    private func setClipboardText(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}
