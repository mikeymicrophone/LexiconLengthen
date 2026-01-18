//
//  AddTopicSheet.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct AddTopicSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var iconName = "tag"
    @State private var colorHex = "#007AFF"

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Topic") {
                    TextField("Name", text: $name)
                    TextField("Icon (SF Symbol)", text: $iconName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Color Hex", text: $colorHex)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Suggestions") {
                    ForEach(Topic.CommonTopic.allCases, id: \.self) { topic in
                        Button {
                            name = topic.rawValue
                            iconName = topic.iconName
                            colorHex = topic.colorHex
                        } label: {
                            Label(topic.rawValue, systemImage: topic.iconName)
                        }
                    }
                }
            }
            .navigationTitle("Add Topic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveTopic()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveTopic() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        let topic = Topic(name: trimmed, iconName: iconName, colorHex: colorHex)
        modelContext.insert(topic)
        try? modelContext.save()
        dismiss()
    }
}
