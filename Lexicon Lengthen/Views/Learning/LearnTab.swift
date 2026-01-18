//
//  LearnTab.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

struct LearnTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var definitionMasteries: [DefinitionMastery]
    @Query private var pronunciationMasteries: [PronunciationMastery]

    var dueForReview: [DefinitionMastery] {
        SpacedRepetitionEngine.itemsDueForReview(from: definitionMasteries)
    }

    var retentionRate: Double {
        SpacedRepetitionEngine.retentionRate(for: definitionMasteries)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today's Review") {
                    if dueForReview.isEmpty {
                        ContentUnavailableView(
                            "All Caught Up!",
                            systemImage: "checkmark.circle",
                            description: Text("No definitions due for review right now")
                        )
                    } else {
                        ForEach(dueForReview) { mastery in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(mastery.wordSpellingText)
                                        .font(.headline)
                                    Text(mastery.masteryLevelDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("Level \(mastery.masteryLevel)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }

                        NavigationLink("Start Review Session") {
                            Text("Review Session View - Coming Soon")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section("Statistics") {
                    LabeledContent("Definitions Studied", value: "\(definitionMasteries.count)")
                    LabeledContent("Pronunciations Practiced", value: "\(pronunciationMasteries.count)")
                    LabeledContent("Retention Rate", value: String(format: "%.0f%%", retentionRate * 100))
                }

                Section("Mastery Distribution") {
                    let distribution = SpacedRepetitionEngine.masteryDistribution(for: definitionMasteries)
                    ForEach(0...5, id: \.self) { level in
                        HStack {
                            Text("Level \(level)")
                            Spacer()
                            Text("\(distribution[level] ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Learn")
        }
    }
}
