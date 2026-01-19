//
//  SpellingPracticeView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI

struct SpellingPracticeView: View {
    let word: Word
    let onRecord: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var audioManager: AudioManager

    @State private var attempt = ""
    @State private var resultMessage: String?
    @State private var isCorrect: Bool?

    private var normalizedWord: String {
        word.spellingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Spell the word you hear")
                    .font(.headline)

                Button {
                    audioManager.speakText(word.spellingText)
                } label: {
                    Label("Play Word", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)

                Text("Letters: \(max(1, normalizedWord.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Type the spelling", text: $attempt)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                Button("Check") {
                    evaluateAttempt()
                }
                .buttonStyle(.bordered)

                if let resultMessage {
                    Text(resultMessage)
                        .font(.subheadline)
                        .foregroundStyle(isCorrect == true ? .green : .red)
                }

                if isCorrect == false {
                    Text("Correct spelling: \(word.spellingText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Spelling")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func evaluateAttempt() {
        let cleanedAttempt = attempt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = !normalizedWord.isEmpty && cleanedAttempt == normalizedWord
        isCorrect = correct
        resultMessage = correct ? "Nice work!" : "Not quite."
        onRecord(correct)
    }
}
