//
//  TopicDetailView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct TopicDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let topic: Topic
    @State private var showingAddWord = false

    var body: some View {
        List {
            Section("Words") {
                if topic.wordTopics.isEmpty {
                    ContentUnavailableView(
                        "No Words Yet",
                        systemImage: "text.book.closed",
                        description: Text("Add words to start building this topic.")
                    )
                } else {
                    ForEach(topic.wordTopics) { link in
                        if let word = link.word {
                            HStack {
                                Text(word.spellingText)
                                    .font(.headline)
                                Text(word.partOfSpeech)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteWords)
                }
            }
        }
        .navigationTitle(topic.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddWord = true
                } label: {
                    Label("Add Word", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordToTopicSheet(topic: topic)
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(topic.wordTopics[index])
        }
        try? modelContext.save()
    }
}
