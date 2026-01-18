//
//  AddWordSheet.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct AddWordSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingSpellings: [Spelling]
    let onSave: (Word) -> Void

    @State private var spellingText = ""
    @State private var partOfSpeech = ""
    @State private var definitionText = ""
    @State private var pronunciationText = ""
    @State private var showingDetails = false
    @State private var suggestedPartOfSpeech = "noun"
    @State private var suggestedPronunciation: String?
    @State private var isLookingUpSuggestions = false
    @State private var lookupTask: Task<Void, Never>?

    private var trimmedSpelling: String {
        spellingText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPartOfSpeech: String {
        partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDefinition: String {
        definitionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPronunciation: String {
        pronunciationText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedSpelling.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Spelling", text: $spellingText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    DisclosureGroup("More details", isExpanded: $showingDetails) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Part of Speech", text: $partOfSpeech)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            TextField("Pronunciation (IPA)", text: $pronunciationText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if isLookingUpSuggestions {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Finding suggestions...")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            } else {
                                Text("Suggested part of speech: \(suggestedPartOfSpeech)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Suggested IPA: \(suggestedPronunciation ?? "unknown")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            TextField("Definition", text: $definitionText, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Add Word")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveWord()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: spellingText) { _, _ in
                scheduleLookup()
            }
            .onDisappear {
                lookupTask?.cancel()
            }
        }
    }

    private func saveWord() {
        let spellingText = trimmedSpelling
        let partOfSpeech = trimmedPartOfSpeech.isEmpty ? suggestedPartOfSpeech : trimmedPartOfSpeech
        let pronunciation = trimmedPronunciation.isEmpty ? suggestedPronunciation : trimmedPronunciation
        guard !spellingText.isEmpty, !partOfSpeech.isEmpty else { return }

        let spelling = existingSpellings.first(where: {
            $0.textLowercase == spellingText.lowercased()
        }) ?? Spelling(text: spellingText)

        if spelling.modelContext == nil {
            modelContext.insert(spelling)
        }

        let word = Word(spelling: spelling, partOfSpeech: partOfSpeech)
        modelContext.insert(word)

        if !trimmedDefinition.isEmpty {
            let definition = Definition(word: word, definitionText: trimmedDefinition, sortOrder: 0)
            modelContext.insert(definition)
        }

        if let pronunciation, !pronunciation.isEmpty {
            let entry = Pronunciation(word: word, ipaTranscription: pronunciation)
            modelContext.insert(entry)
        }

        try? modelContext.save()
        onSave(word)
        dismiss()
    }

    private func scheduleLookup() {
        lookupTask?.cancel()

        let spelling = trimmedSpelling
        guard spelling.count >= 2 else {
            suggestedPartOfSpeech = "noun"
            suggestedPronunciation = nil
            isLookingUpSuggestions = false
            return
        }

        lookupTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { isLookingUpSuggestions = true }
            let suggestion = await PartOfSpeechResolver.shared.lookup(for: spelling)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if spelling == trimmedSpelling {
                    suggestedPartOfSpeech = suggestion.partOfSpeech ?? "noun"
                    suggestedPronunciation = suggestion.ipa
                }
                isLookingUpSuggestions = false
            }
        }
    }
}
