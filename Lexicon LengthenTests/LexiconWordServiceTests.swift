//
//  LexiconWordServiceTests.swift
//  Lexicon LengthenTests
//
//  Created by Mike Schwab on 1/20/26.
//

import Testing
import SwiftData
@testable import Lexicon_Lengthen

struct LexiconWordServiceTests {
    @Test func removeFromLexiconKeepsWord() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let spelling = Spelling(text: "caution")
        context.insert(spelling)
        let word = Word(spelling: spelling, partOfSpeech: "noun")
        context.insert(word)
        try context.save()

        let entry = UserLexiconEntry(
            wordID: word.persistentModelID.storeIdentifier ?? "",
            word: word
        )
        context.insert(entry)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        LexiconWordService.removeFromLexicon(word, entries: entries, in: context)

        let remainingEntries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        #expect(remainingEntries.isEmpty)

        let remainingWords = try context.fetch(FetchDescriptor<Word>())
        #expect(remainingWords.count == 1)
    }

    @Test func deleteWordRemovesLexiconAndWord() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let spelling = Spelling(text: "cautious")
        context.insert(spelling)
        let word = Word(spelling: spelling, partOfSpeech: "adjective")
        context.insert(word)
        try context.save()

        let entry = UserLexiconEntry(
            wordID: word.persistentModelID.storeIdentifier ?? "",
            word: word
        )
        context.insert(entry)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        LexiconWordService.deleteWord(word, entries: entries, in: context)

        let remainingEntries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        #expect(remainingEntries.isEmpty)

        let remainingWords = try context.fetch(FetchDescriptor<Word>())
        #expect(remainingWords.isEmpty)
    }

    @Test func removeFromLexiconPreservesOtherEntries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let spelling = Spelling(text: "caution")
        context.insert(spelling)
        let noun = Word(spelling: spelling, partOfSpeech: "noun")
        let adjective = Word(spelling: spelling, partOfSpeech: "adjective")
        context.insert(noun)
        context.insert(adjective)
        try context.save()

        let nounEntry = UserLexiconEntry(
            wordID: noun.persistentModelID.storeIdentifier ?? "",
            word: noun
        )
        let adjectiveEntry = UserLexiconEntry(
            wordID: adjective.persistentModelID.storeIdentifier ?? "",
            word: adjective
        )
        context.insert(nounEntry)
        context.insert(adjectiveEntry)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        LexiconWordService.removeFromLexicon(noun, entries: entries, in: context)

        let remainingEntries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        #expect(remainingEntries.count == 1)
        #expect(remainingEntries.first?.word?.id == adjective.id)
    }

    @Test func deleteNonLexiconWordKeepsEntries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let spelling = Spelling(text: "caution")
        context.insert(spelling)
        let noun = Word(spelling: spelling, partOfSpeech: "noun")
        let adjective = Word(spelling: spelling, partOfSpeech: "adjective")
        let extra = Word(spelling: spelling, partOfSpeech: "verb")
        context.insert(noun)
        context.insert(adjective)
        context.insert(extra)
        try context.save()

        let nounEntry = UserLexiconEntry(wordID: "", word: noun)
        let adjectiveEntry = UserLexiconEntry(wordID: "", word: adjective)
        context.insert(nounEntry)
        context.insert(adjectiveEntry)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        LexiconWordService.deleteWord(extra, entries: entries, in: context)

        let remainingEntries = try context.fetch(FetchDescriptor<UserLexiconEntry>())
        #expect(remainingEntries.count == 2)
        let remainingWordIDs = Set(remainingEntries.compactMap { $0.word?.id })
        #expect(remainingWordIDs.contains(noun.id))
        #expect(remainingWordIDs.contains(adjective.id))
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Language.self,
            Spelling.self,
            Word.self,
            LexemeGroup.self,
            Definition.self,
            AccentDialect.self,
            Pronunciation.self,
            Topic.self,
            WordTopic.self,
            SentenceTemplate.self,
            UserProfile.self,
            DefinitionMastery.self,
            PronunciationMastery.self,
            WordReadingMastery.self,
            WordWritingMastery.self,
            UserLexiconEntry.self,
            UserSentence.self,
            UserTopicPreference.self,
            UserSubmission.self,
            AISuggestion.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
