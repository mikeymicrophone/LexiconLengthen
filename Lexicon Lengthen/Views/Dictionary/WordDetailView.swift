//
//  WordDetailView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

struct WordDetailView: View {
    let word: Word
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.modelContext) private var modelContext

    @State private var readingMastery: WordReadingMastery?
    @State private var writingMastery: WordWritingMastery?
    @State private var showingSpellingPractice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.spellingText)
                        .font(.largeTitle.bold())

                    HStack {
                        Text(word.partOfSpeech)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())

                        if let etymology = word.etymology {
                            Text(etymology)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            if audioManager.isPlaying {
                                audioManager.stopPlayback()
                            } else {
                                audioManager.speakText(word.spellingText)
                            }
                        } label: {
                            Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "speaker.wave.2.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel("Speak word")
                    }
                }

                Divider()

                // Reading & Writing
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading & Writing")
                        .font(.headline)

                    literacyRow(
                        title: "Reading",
                        masteryDescription: readingMastery?.masteryLevelDescription ?? "Not Started",
                        correctCount: readingMastery?.correctCount ?? 0,
                        incorrectCount: readingMastery?.incorrectCount ?? 0,
                        onCorrect: { recordReading(correct: true) },
                        onIncorrect: { recordReading(correct: false) }
                    )

                    literacyRow(
                        title: "Writing",
                        masteryDescription: writingMastery?.masteryLevelDescription ?? "Not Started",
                        correctCount: writingMastery?.correctCount ?? 0,
                        incorrectCount: writingMastery?.incorrectCount ?? 0,
                        onCorrect: { recordWriting(correct: true) },
                        onIncorrect: { recordWriting(correct: false) }
                    )

                    Button {
                        showingSpellingPractice = true
                    } label: {
                        Label("Practice Spelling", systemImage: "pencil.and.outline")
                    }
                    .buttonStyle(.bordered)
                }

                // Pronunciations
                if !word.pronunciations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pronunciations")
                            .font(.headline)

                        ForEach(word.pronunciations) { pronunciation in
                            HStack {
                                VStack(alignment: .leading) {
                                    if let accent = pronunciation.accentDialect {
                                        Text(accent.name)
                                            .font(.subheadline)
                                    }
                                    if let ipa = pronunciation.ipaTranscription {
                                        Text(ipa)
                                            .font(.body.monospaced())
                                    }
                                    if let respelling = pronunciation.respelling {
                                        Text(respelling)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    try? audioManager.play(pronunciation: pronunciation)
                                } label: {
                                    Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title)
                                }
                            }
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Definitions
                if !word.definitions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Definitions")
                            .font(.headline)

                        ForEach(Array(word.definitions.enumerated()), id: \.element.id) { index, definition in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)

                                    Text(definition.definitionText)
                                        .font(.body)

                                    Spacer()

                                    Button {
                                        if audioManager.isPlaying {
                                            audioManager.stopPlayback()
                                        } else {
                                            audioManager.speakText(definition.definitionText)
                                        }
                                    } label: {
                                        Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "speaker.wave.2.fill")
                                    }
                                    .accessibilityLabel("Speak definition")
                                }

                                if let example = definition.exampleSentence {
                                    Text("\"\(example)\"")
                                        .font(.subheadline.italic())
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 24)
                                }

                                HStack {
                                    if definition.register != "neutral" {
                                        Text(definition.register)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.blue.opacity(0.2))
                                            .clipShape(Capsule())
                                    }

                                    if let domain = definition.domain {
                                        Text(domain)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.leading, 24)
                            }
                            .padding()
                            .background(.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Topics
                if !word.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(word.topics) { topic in
                                Label(topic.name, systemImage: topic.iconName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Points info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Points Available")
                        .font(.headline)

                    let totalPoints = PointsCalculator.totalPotentialPoints(for: word)
                    Text("\(totalPoints) points")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
        .navigationTitle(word.spellingText)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: word.id) { _, _ in
            audioManager.stopPlayback()
            loadMastery()
        }
        .task {
            loadMastery()
        }
        .sheet(isPresented: $showingSpellingPractice) {
            SpellingPracticeView(word: word) { wasCorrect in
                recordWriting(correct: wasCorrect)
            }
        }
    }

    private func loadMastery() {
        let wordID = word.persistentModelID.storeIdentifier ?? ""
        guard !wordID.isEmpty else {
            readingMastery = nil
            writingMastery = nil
            return
        }

        let readingDescriptor = FetchDescriptor<WordReadingMastery>(
            predicate: #Predicate { $0.wordID == wordID }
        )
        readingMastery = (try? modelContext.fetch(readingDescriptor))?.first

        let writingDescriptor = FetchDescriptor<WordWritingMastery>(
            predicate: #Predicate { $0.wordID == wordID }
        )
        writingMastery = (try? modelContext.fetch(writingDescriptor))?.first
    }

    private func recordReading(correct: Bool) {
        let mastery = readingMastery ?? makeReadingMastery()
        mastery.recordAttempt(correct: correct)
        readingMastery = mastery
        try? modelContext.save()
    }

    private func recordWriting(correct: Bool) {
        let mastery = writingMastery ?? makeWritingMastery()
        mastery.recordAttempt(correct: correct)
        writingMastery = mastery
        try? modelContext.save()
    }

    private func makeReadingMastery() -> WordReadingMastery {
        let wordID = word.persistentModelID.storeIdentifier ?? ""
        let mastery = WordReadingMastery(
            wordID: wordID,
            wordSpellingText: word.spellingText,
            wordLetterCount: word.letterCount
        )
        modelContext.insert(mastery)
        return mastery
    }

    private func makeWritingMastery() -> WordWritingMastery {
        let wordID = word.persistentModelID.storeIdentifier ?? ""
        let mastery = WordWritingMastery(
            wordID: wordID,
            wordSpellingText: word.spellingText,
            wordLetterCount: word.letterCount
        )
        modelContext.insert(mastery)
        return mastery
    }

    @ViewBuilder
    private func literacyRow(
        title: String,
        masteryDescription: String,
        correctCount: Int,
        incorrectCount: Int,
        onCorrect: @escaping () -> Void,
        onIncorrect: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text(masteryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Correct") {
                    onCorrect()
                }
                .buttonStyle(.borderedProminent)

                Button("Missed") {
                    onIncorrect()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(correctCount) correct • \(incorrectCount) missed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
