//
//  DictionaryTab.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

struct DictionaryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spelling.textLowercase) private var spellings: [Spelling]

    @State private var searchText = ""
    @State private var selectedWord: Word?
    @State private var showingAddWord = false
    @State private var showingTopics = false

    var filteredSpellings: [Spelling] {
        if searchText.isEmpty {
            return spellings
        }
        return spellings.filter {
            $0.textLowercase.contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filteredSpellings, selection: $selectedWord) { spelling in
                ForEach(spelling.words) { word in
                    NavigationLink(value: word) {
                        VStack(alignment: .leading) {
                            Text(spelling.text)
                                .font(.headline)
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Dictionary")
            .searchable(text: $searchText, prompt: "Search words")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingTopics = true
                    } label: {
                        Label("Topics", systemImage: "tag")
                    }

                    Button {
                        showingAddWord = true
                    } label: {
                        Label("Add Word", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let word = selectedWord {
                WordDetailView(word: word)
            } else {
                ContentUnavailableView(
                    "Select a Word",
                    systemImage: "book",
                    description: Text("Choose a word from the dictionary to see its details")
                )
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordSheet(existingSpellings: spellings) { newWord in
                selectedWord = newWord
            }
        }
        .sheet(isPresented: $showingTopics) {
            TopicsView()
        }
    }
}
