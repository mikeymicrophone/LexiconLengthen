//
//  ProfileTab.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import SwiftUI
import SwiftData

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
