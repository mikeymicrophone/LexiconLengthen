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

    @State private var selectedTemplateID: String = "all"

    private struct TemplateFilterOption: Identifiable {
        let id: String
        let title: String
    }

    private var filteredSentences: [UserSentence] {
        guard selectedTemplateID != "all" else {
            return sentences
        }
        return sentences.filter { $0.templateID == selectedTemplateID }
    }

    private var templateFilterOptions: [TemplateFilterOption] {
        var options: [TemplateFilterOption] = []
        options.append(TemplateFilterOption(id: "all", title: "All Sentences (\(sentences.count))"))

        var counts: [String: Int] = [:]
        for sentence in sentences {
            let key = sentence.templateID ?? "unspecified"
            counts[key, default: 0] += 1
        }

        let templateOptions = counts.keys.sorted { left, right in
            templateName(for: left).localizedCaseInsensitiveCompare(templateName(for: right)) == .orderedAscending
        }

        for templateID in templateOptions {
            let count = counts[templateID] ?? 0
            let title = "\(templateName(for: templateID)) (\(count))"
            options.append(TemplateFilterOption(id: templateID, title: title))
        }

        return options
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Create New") {
                    NavigationLink {
                        SentenceBuilderView()
                    } label: {
                        Label("Structured", systemImage: "pencil")
                    }

                    if !templates.isEmpty {
                        NavigationLink {
                            Text("Template Picker - Coming Soon")
                        } label: {
                            Label("Use Template (\(templates.count) available)", systemImage: "doc.text")
                        }
                    }
                }

                Section("Filter") {
                    Picker("Template", selection: $selectedTemplateID) {
                        ForEach(templateFilterOptions) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("My Sentences (\(filteredSentences.count))") {
                    if filteredSentences.isEmpty {
                        ContentUnavailableView(
                            "No Sentences Yet",
                            systemImage: "text.quote",
                            description: Text("Create sentences using words you've learned to earn points")
                        )
                    } else {
                        ForEach(filteredSentences) { sentence in
                            NavigationLink {
                                SentenceDetailView(sentence: sentence)
                            } label: {
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
            }
            .navigationTitle("Sentences")
        }
    }

    private func templateName(for templateID: String) -> String {
        if templateID == "unspecified" {
            return "Unspecified"
        }

        if let builtinName = builtinTemplateNames[templateID] {
            return builtinName
        }

        if templateID.hasPrefix("template:") {
            let storeID = templateID.replacingOccurrences(of: "template:", with: "")
            if let template = templates.first(where: { $0.persistentModelID.storeIdentifier == storeID }) {
                return template.structure
            }
        }

        return "Unknown Template"
    }

    private var builtinTemplateNames: [String: String] {
        [
            "builtin:subject-verb-object-adverb": "Subject Verb Object Adverb",
            "builtin:subject-verb": "Subject Verb",
            "builtin:subject-verb-object": "Subject Verb Object",
            "builtin:subject-verb-adverb": "Subject Verb Adverb",
            "builtin:adjective-subject-verb": "Adjective Subject Verb",
            "builtin:adjective-subject-verb-object": "Adjective Subject Verb Object",
            "builtin:subject-verb-adjective": "Subject Verb Adjective",
            "builtin:subject-verb-adjective-object": "Subject Verb Adjective Object",
            "builtin:subject-verb-object-adjective": "Subject Verb Object Adjective",
            "builtin:subject-verb-noun": "Subject Verb Noun",
            "builtin:subject-verb-object-noun": "Subject Verb Object Noun",
            "builtin:subject-verb-object-after-noun": "Subject Verb Object After Noun",
            "builtin:subject-verb-object-before-noun": "Subject Verb Object Before Noun"
        ]
    }
}
