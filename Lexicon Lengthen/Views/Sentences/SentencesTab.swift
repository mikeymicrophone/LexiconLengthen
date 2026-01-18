//
//  SentencesTab.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

struct SentencesTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSentence.createdAt, order: .reverse) private var sentences: [UserSentence]
    @Query private var templates: [SentenceTemplate]

    var body: some View {
        NavigationStack {
            List {
                Section("Create New") {
                    NavigationLink {
                        Text("Sentence Builder - Coming Soon")
                    } label: {
                        Label("Free Form", systemImage: "pencil")
                    }

                    if !templates.isEmpty {
                        NavigationLink {
                            Text("Template Picker - Coming Soon")
                        } label: {
                            Label("Use Template (\(templates.count) available)", systemImage: "doc.text")
                        }
                    }
                }

                Section("My Sentences (\(sentences.count))") {
                    if sentences.isEmpty {
                        ContentUnavailableView(
                            "No Sentences Yet",
                            systemImage: "text.quote",
                            description: Text("Create sentences using words you've learned to earn points")
                        )
                    } else {
                        ForEach(sentences) { sentence in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sentence.sentenceText)
                                    .font(.body)

                                HStack {
                                    Text("\(sentence.wordCount) words")
                                    Text("\(sentence.pointsEarned) pts")
                                        .foregroundStyle(.orange)
                                    Spacer()
                                    Text(sentence.createdAt, style: .date)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Sentences")
        }
    }
}
