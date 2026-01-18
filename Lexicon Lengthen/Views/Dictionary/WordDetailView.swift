//
//  WordDetailView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI

struct WordDetailView: View {
    let word: Word
    @EnvironmentObject private var audioManager: AudioManager

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
        }
    }
}
