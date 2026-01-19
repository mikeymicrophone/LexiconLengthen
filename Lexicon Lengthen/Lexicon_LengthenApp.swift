//
//  Lexicon_LengthenApp.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

@main
struct Lexicon_LengthenApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Public models (shared dictionary)
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

            // Private models (user data)
            UserProfile.self,
            DefinitionMastery.self,
            PronunciationMastery.self,
            WordReadingMastery.self,
            WordWritingMastery.self,
            UserLexiconEntry.self,
            UserSentence.self,
            UserTopicPreference.self,

            // Submission models (moderation)
            UserSubmission.self,
            AISuggestion.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
