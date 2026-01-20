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
    @Query private var lexiconEntries: [UserLexiconEntry]

    @State private var searchText = ""
    @State private var selectedWord: Word?
    @State private var showingAddWord = false
    @State private var showingTopics = false
    @State private var showingLibrary = false
    @State private var showingPreferences = false
    @State private var filteredSpellings: [Spelling] = []
    @State private var lexiconWordIDs: Set<Word.ID> = []

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedWord) {
                if filteredSpellings.isEmpty {
                    ContentUnavailableView(
                        "No Lexicon Words",
                        systemImage: "book",
                        description: Text("Add words from your library to build your lexicon.")
                    )
                } else {
                    ForEach(filteredSpellings) { spelling in
                        let lexiconWords = spelling.words.filter { lexiconWordIDs.contains($0.id) }
                        ForEach(lexiconWords) { word in
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
                }
            }
            .navigationTitle("Dictionary")
            .searchable(text: $searchText, prompt: "Search words")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingLibrary = true
                    } label: {
                        Label("Library", systemImage: "books.vertical")
                    }

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

                    Button {
                        showingPreferences = true
                    } label: {
                        Label("Preferences", systemImage: "gearshape")
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
        .sheet(isPresented: $showingLibrary) {
            DeviceWordLibraryView()
        }
        .sheet(isPresented: $showingPreferences) {
            DictionaryPreferencesView()
        }
        .task {
            refreshFilteredSpellings()
        }
        .onChange(of: searchText) { _, _ in
            refreshFilteredSpellings()
        }
        .onChange(of: spellings) { _, _ in
            refreshFilteredSpellings()
        }
        .onChange(of: lexiconEntries) { _, _ in
            refreshFilteredSpellings()
        }
    }

    private func refreshFilteredSpellings() {
        lexiconWordIDs = Set(lexiconEntries.compactMap { $0.word?.id })
        guard !self.lexiconWordIDs.isEmpty else {
            filteredSpellings = []
            return
        }

        let lowered = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lowered.isEmpty {
            filteredSpellings = spellings.filter { spelling in
                spelling.words.contains { self.lexiconWordIDs.contains($0.id) }
            }
            return
        }

        filteredSpellings = spellings.filter { spelling in
            spelling.textLowercase.contains(lowered) &&
            spelling.words.contains { self.lexiconWordIDs.contains($0.id) }
        }
    }
}
