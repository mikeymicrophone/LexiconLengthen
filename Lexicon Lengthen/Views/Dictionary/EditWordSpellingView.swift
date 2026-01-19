//
//  EditWordSpellingView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/19/26.
//

import SwiftUI
import SwiftData

struct EditWordSpellingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let word: Word

    @State private var newSpelling: String

    init(word: Word) {
        self.word = word
        _newSpelling = State(initialValue: word.spellingText)
    }

    private var trimmedSpelling: String {
        newSpelling.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current") {
                    Text(word.spellingText)
                }

                Section("New Spelling") {
                    TextField("Spelling", text: $newSpelling)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Edit Spelling")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSpelling()
                    }
                    .disabled(trimmedSpelling.isEmpty || trimmedSpelling == word.spellingText)
                }
            }
        }
    }

    private func saveSpelling() {
        let updated = trimmedSpelling
        guard !updated.isEmpty else { return }

        let lowered = updated.lowercased()
        let descriptor = FetchDescriptor<Spelling>(
            predicate: #Predicate { $0.textLowercase == lowered }
        )
        let existing = (try? modelContext.fetch(descriptor))?.first
        let target = existing ?? Spelling(text: updated)
        if target.modelContext == nil {
            modelContext.insert(target)
        }

        word.spelling = target
        try? modelContext.save()
        dismiss()
    }
}
