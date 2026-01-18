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

// MARK: - Dictionary Tab

struct DictionaryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spelling.textLowercase) private var spellings: [Spelling]

    @State private var searchText = ""
    @State private var selectedWord: Word?
    @State private var showingAddWord = false

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
                Button {
                    showingAddWord = true
                } label: {
                    Label("Add Word", systemImage: "plus")
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
    }
}

struct AddWordSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingSpellings: [Spelling]
    let onSave: (Word) -> Void

    @State private var spellingText = ""
    @State private var partOfSpeech = ""
    @State private var definitionText = ""
    @State private var showingDetails = false
    @State private var suggestedPartOfSpeech = "noun"
    @State private var isLookingUpPartOfSpeech = false
    @State private var partOfSpeechLookupTask: Task<Void, Never>?

    private var trimmedSpelling: String {
        spellingText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPartOfSpeech: String {
        partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDefinition: String {
        definitionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedSpelling.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Spelling", text: $spellingText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    DisclosureGroup("More details", isExpanded: $showingDetails) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Part of Speech", text: $partOfSpeech)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if isLookingUpPartOfSpeech {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Finding part of speech...")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            } else {
                                Text("Suggested: \(suggestedPartOfSpeech)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            TextField("Definition", text: $definitionText, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Add Word")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveWord()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: spellingText) { _, _ in
                schedulePartOfSpeechLookup()
            }
            .onDisappear {
                partOfSpeechLookupTask?.cancel()
            }
        }
    }

    private func saveWord() {
        let spellingText = trimmedSpelling
        let partOfSpeech = trimmedPartOfSpeech.isEmpty ? suggestedPartOfSpeech : trimmedPartOfSpeech
        guard !spellingText.isEmpty, !partOfSpeech.isEmpty else { return }

        let spelling = existingSpellings.first(where: {
            $0.textLowercase == spellingText.lowercased()
        }) ?? Spelling(text: spellingText)

        if spelling.modelContext == nil {
            modelContext.insert(spelling)
        }

        let word = Word(spelling: spelling, partOfSpeech: partOfSpeech)
        modelContext.insert(word)

        if !trimmedDefinition.isEmpty {
            let definition = Definition(word: word, definitionText: trimmedDefinition, sortOrder: 0)
            modelContext.insert(definition)
        }

        try? modelContext.save()
        onSave(word)
        dismiss()
    }

    private func schedulePartOfSpeechLookup() {
        partOfSpeechLookupTask?.cancel()

        let spelling = trimmedSpelling
        guard spelling.count >= 2 else {
            suggestedPartOfSpeech = "noun"
            isLookingUpPartOfSpeech = false
            return
        }

        partOfSpeechLookupTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { isLookingUpPartOfSpeech = true }
            let suggestion = await PartOfSpeechResolver.shared.suggest(for: spelling)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if spelling == trimmedSpelling {
                    suggestedPartOfSpeech = suggestion ?? "noun"
                }
                isLookingUpPartOfSpeech = false
            }
        }
    }
}

// MARK: - Word Detail View

struct WordDetailView: View {
    let word: Word
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.spellingText)
                        .font(.largeTitle.bold())

                    HStack {
                        Text(word.partOfSpeech)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())

                        if let etymology = word.etymology {
                            Text(etymology)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Pronunciations
                if !word.pronunciations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pronunciations")
                            .font(.headline)

                        ForEach(word.pronunciations) { pronunciation in
                            HStack {
                                VStack(alignment: .leading) {
                                    if let accent = pronunciation.accentDialect {
                                        Text(accent.name)
                                            .font(.subheadline)
                                    }
                                    if let ipa = pronunciation.ipaTranscription {
                                        Text(ipa)
                                            .font(.body.monospaced())
                                    }
                                    if let respelling = pronunciation.respelling {
                                        Text(respelling)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    try? audioManager.play(pronunciation: pronunciation)
                                } label: {
                                    Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title)
                                }
                            }
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Definitions
                if !word.definitions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Definitions")
                            .font(.headline)

                        ForEach(Array(word.definitions.enumerated()), id: \.element.id) { index, definition in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)

                                    Text(definition.definitionText)
                                        .font(.body)
                                }

                                if let example = definition.exampleSentence {
                                    Text("\"\(example)\"")
                                        .font(.subheadline.italic())
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 24)
                                }

                                HStack {
                                    if definition.register != "neutral" {
                                        Text(definition.register)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.blue.opacity(0.2))
                                            .clipShape(Capsule())
                                    }

                                    if let domain = definition.domain {
                                        Text(domain)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.leading, 24)
                            }
                            .padding()
                            .background(.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Topics
                if !word.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(word.topics) { topic in
                                Label(topic.name, systemImage: topic.iconName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Points info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Points Available")
                        .font(.headline)

                    let totalPoints = PointsCalculator.totalPotentialPoints(for: word)
                    Text("\(totalPoints) points")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
        .navigationTitle(word.spellingText)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flow Layout (for topics)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews)
        return CGSize(width: proposal.replacingUnspecifiedDimensions().width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (positions: [CGPoint], height: CGFloat) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, y + rowHeight)
    }
}

// MARK: - Learn Tab

struct LearnTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var definitionMasteries: [DefinitionMastery]
    @Query private var pronunciationMasteries: [PronunciationMastery]

    var dueForReview: [DefinitionMastery] {
        SpacedRepetitionEngine.itemsDueForReview(from: definitionMasteries)
    }

    var retentionRate: Double {
        SpacedRepetitionEngine.retentionRate(for: definitionMasteries)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today's Review") {
                    if dueForReview.isEmpty {
                        ContentUnavailableView(
                            "All Caught Up!",
                            systemImage: "checkmark.circle",
                            description: Text("No definitions due for review right now")
                        )
                    } else {
                        ForEach(dueForReview) { mastery in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(mastery.wordSpellingText)
                                        .font(.headline)
                                    Text(mastery.masteryLevelDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("Level \(mastery.masteryLevel)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }

                        NavigationLink("Start Review Session") {
                            Text("Review Session View - Coming Soon")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section("Statistics") {
                    LabeledContent("Definitions Studied", value: "\(definitionMasteries.count)")
                    LabeledContent("Pronunciations Practiced", value: "\(pronunciationMasteries.count)")
                    LabeledContent("Retention Rate", value: String(format: "%.0f%%", retentionRate * 100))
                }

                Section("Mastery Distribution") {
                    let distribution = SpacedRepetitionEngine.masteryDistribution(for: definitionMasteries)
                    ForEach(0...5, id: \.self) { level in
                        HStack {
                            Text("Level \(level)")
                            Spacer()
                            Text("\(distribution[level] ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Learn")
        }
    }
}

// MARK: - Sentences Tab

struct SentencesTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSentence.createdAt, order: .reverse) private var sentences: [UserSentence]
    @Query private var templates: [SentenceTemplate]

    var body: some View {
        NavigationStack {
            List {
                Section("Create New") {
                    NavigationLink {
                        Text("Sentence Builder - Coming Soon")
                    } label: {
                        Label("Free Form", systemImage: "pencil")
                    }

                    if !templates.isEmpty {
                        NavigationLink {
                            Text("Template Picker - Coming Soon")
                        } label: {
                            Label("Use Template (\(templates.count) available)", systemImage: "doc.text")
                        }
                    }
                }

                Section("My Sentences (\(sentences.count))") {
                    if sentences.isEmpty {
                        ContentUnavailableView(
                            "No Sentences Yet",
                            systemImage: "text.quote",
                            description: Text("Create sentences using words you've learned to earn points")
                        )
                    } else {
                        ForEach(sentences) { sentence in
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
            .navigationTitle("Sentences")
        }
    }
}

// MARK: - Profile Tab

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    var profile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                if let profile = profile {
                    Section("Overview") {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.displayName ?? "Vocabulary Builder")
                                    .font(.title2.bold())
                                Text("Level \(profile.totalPoints / 1000 + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack {
                                Text("\(profile.totalPoints)")
                                    .font(.title.bold())
                                    .foregroundStyle(.orange)
                                Text("Points")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Progress") {
                        LabeledContent("Words Known", value: "\(profile.wordsKnownCount)")
                        LabeledContent("Definitions Mastered", value: "\(profile.definitionsMasteredCount)")
                        LabeledContent("Pronunciations Mastered", value: "\(profile.pronunciationsMasteredCount)")
                        LabeledContent("Sentences Created", value: "\(profile.sentencesCreatedCount)")
                    }

                    Section("Streaks") {
                        HStack {
                            VStack {
                                Text("\(profile.currentStreak)")
                                    .font(.title.bold())
                                    .foregroundStyle(.orange)
                                Text("Current")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            VStack {
                                Text("\(profile.longestStreak)")
                                    .font(.title.bold())
                                Text("Longest")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            VStack {
                                Text("\(PointsCalculator.pointsForDailyStreak(profile: profile))")
                                    .font(.title.bold())
                                    .foregroundStyle(.green)
                                Text("Bonus/Day")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Settings") {
                        NavigationLink {
                            Text("Language Settings - Coming Soon")
                        } label: {
                            LabeledContent("Preferred Language", value: profile.preferredLanguageCode.uppercased())
                        }

                        NavigationLink {
                            Text("Accent Settings - Coming Soon")
                        } label: {
                            LabeledContent("Preferred Accent", value: profile.preferredAccentCode ?? "Default")
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Loading Profile",
                        systemImage: "person.circle",
                        description: Text("Please wait...")
                    )
                }
            }
            .navigationTitle("Profile")
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
