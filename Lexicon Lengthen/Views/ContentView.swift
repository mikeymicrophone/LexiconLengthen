//
//  ContentView.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var selectedTab: Tab = .dictionary

    enum Tab: String, CaseIterable {
        case dictionary = "Dictionary"
        case learn = "Learn"
        case sentences = "Sentences"
        case profile = "Profile"

        var iconName: String {
            switch self {
            case .dictionary: return "book"
            case .learn: return "brain.head.profile"
            case .sentences: return "text.quote"
            case .profile: return "person.circle"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DictionaryTab()
                .tabItem {
                    Label(Tab.dictionary.rawValue, systemImage: Tab.dictionary.iconName)
                }
                .tag(Tab.dictionary)

            LearnTab()
                .tabItem {
                    Label(Tab.learn.rawValue, systemImage: Tab.learn.iconName)
                }
                .tag(Tab.learn)

            SentencesTab()
                .tabItem {
                    Label(Tab.sentences.rawValue, systemImage: Tab.sentences.iconName)
                }
                .tag(Tab.sentences)

            ProfileTab()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.iconName)
                }
                .tag(Tab.profile)
        }
        .task {
            await setupUserProfileIfNeeded()
        }
    }

    private func setupUserProfileIfNeeded() async {
        if userProfiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
            try? modelContext.save()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Language.self,
            Spelling.self,
            Word.self,
            Definition.self,
            AccentDialect.self,
            Pronunciation.self,
            Topic.self,
            WordTopic.self,
            SentenceTemplate.self,
            UserProfile.self,
            DefinitionMastery.self,
            PronunciationMastery.self,
            UserSentence.self,
            UserTopicPreference.self,
            UserSubmission.self,
            AISuggestion.self
        ], inMemory: true)
        .environmentObject(AudioManager())
}
