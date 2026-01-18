//
//  TopicsView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/18/26.
//

import SwiftUI
import SwiftData

struct TopicsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Topic.name) private var topics: [Topic]

    @State private var showingAddTopic = false

    var body: some View {
        NavigationStack {
            List {
                if topics.isEmpty {
                    ContentUnavailableView(
                        "No Topics Yet",
                        systemImage: "tag",
                        description: Text("Create a topic to start organizing words.")
                    )
                } else {
                    ForEach(topics) { topic in
                        NavigationLink {
                            TopicDetailView(topic: topic)
                        } label: {
                            HStack {
                                Label(topic.name, systemImage: topic.iconName)
                                Spacer()
                                Text("\(topic.wordCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTopics)
                }
            }
            .navigationTitle("Topics")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTopic = true
                    } label: {
                        Label("Add Topic", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTopic) {
                AddTopicSheet()
            }
        }
    }

    private func deleteTopics(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(topics[index])
        }
        try? modelContext.save()
    }
}
