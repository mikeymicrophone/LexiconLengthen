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
    @State private var showingBrowse = false
    @State private var showingLibrary = false

    private var lexiconWordIDs: Set<Word.ID> {
        Set(lexiconEntries.compactMap { $0.word?.id })
    }

    var filteredSpellings: [Spelling] {
        guard !lexiconWordIDs.isEmpty else {
            return []
        }
        if searchText.isEmpty {
            return spellings.filter { spelling in
                spelling.words.contains { lexiconWordIDs.contains($0.id) }
            }
        }
        let lowered = searchText.lowercased()
        return spellings.filter { spelling in
            spelling.textLowercase.contains(lowered) &&
            spelling.words.contains { lexiconWordIDs.contains($0.id) }
        }
    }

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
                        showingBrowse = true
                    } label: {
                        Label("Browse", systemImage: "textformat.size")
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
        .sheet(isPresented: $showingBrowse) {
            WordBrowseView()
        }
        .sheet(isPresented: $showingLibrary) {
            DeviceWordLibraryView()
        }
    }
}
