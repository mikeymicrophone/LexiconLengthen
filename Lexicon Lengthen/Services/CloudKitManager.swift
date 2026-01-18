//
//  CloudKitManager.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import CloudKit
import SwiftData
import Combine

/// Manages CloudKit operations and sync status.
@MainActor
final class CloudKitManager: ObservableObject {

    // MARK: - Constants

    static nonisolated let containerIdentifier = "iCloud.com.MICharisma.Lexicon-Lengthen"

    // MARK: - Published Properties

    @Published var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase

    // MARK: - Initialization

    nonisolated init() {
        let cont = CKContainer(identifier: Self.containerIdentifier)
        self.container = cont
        self.publicDatabase = cont.publicCloudDatabase
        self.privateDatabase = cont.privateCloudDatabase
    }

    // MARK: - Account Status

    /// Checks and updates the iCloud account status
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudStatus = status

            if status != .available {
                errorMessage = accountStatusMessage(for: status)
            } else {
                errorMessage = nil
            }
        } catch {
            iCloudStatus = .couldNotDetermine
            errorMessage = "Could not determine iCloud status: \(error.localizedDescription)"
        }
    }

    /// Returns a user-friendly message for account status
    private func accountStatusMessage(for status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "Please sign in to iCloud in Settings to sync your data across devices"
        case .restricted:
            return "iCloud access is restricted on this device"
        case .couldNotDetermine:
            return "Could not determine iCloud status"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "Unknown iCloud status"
        }
    }

    /// Returns true if iCloud sync is available
    var isSyncAvailable: Bool {
        iCloudStatus == .available
    }

    // MARK: - User Identity

    /// Fetches the current user's record ID
    func fetchUserRecordID() async throws -> CKRecord.ID {
        try await container.userRecordID()
    }

    /// Fetches the current user's identity
    func fetchUserIdentity() async throws -> CKUserIdentity? {
        let recordID = try await fetchUserRecordID()
        return try await container.userIdentity(forUserRecordID: recordID)
    }

    // MARK: - Subscriptions

    /// Sets up CloudKit subscriptions for change notifications
    func setupSubscriptions() async throws {
        guard isSyncAvailable else { return }

        // Create subscription for public database changes
        let publicSubscription = CKDatabaseSubscription(subscriptionID: "public-changes")
        let publicNotificationInfo = CKSubscription.NotificationInfo()
        publicNotificationInfo.shouldSendContentAvailable = true
        publicSubscription.notificationInfo = publicNotificationInfo

        // Create subscription for private database changes
        let privateSubscription = CKDatabaseSubscription(subscriptionID: "private-changes")
        let privateNotificationInfo = CKSubscription.NotificationInfo()
        privateNotificationInfo.shouldSendContentAvailable = true
        privateSubscription.notificationInfo = privateNotificationInfo

        // Save subscriptions
        do {
            _ = try await publicDatabase.save(publicSubscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription may already exist, which is fine
        }

        do {
            _ = try await privateDatabase.save(privateSubscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription may already exist, which is fine
        }
    }

    // MARK: - Sync Operations

    /// Triggers a manual sync
    func triggerSync() {
        syncStatus = .syncing
        // SwiftData with CloudKit handles sync automatically
        // This method can be used to update UI state
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate sync
            syncStatus = .idle
            lastSyncDate = Date()
        }
    }

    // MARK: - Record Operations (for custom operations)

    /// Fetches records from the public database
    func fetchPublicRecords(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = [],
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: resultsLimit)

        return results.compactMap { _, result in
            try? result.get()
        }
    }

    /// Fetches records from the private database
    func fetchPrivateRecords(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = [],
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        let (results, _) = try await privateDatabase.records(matching: query, resultsLimit: resultsLimit)

        return results.compactMap { _, result in
            try? result.get()
        }
    }

    /// Saves a record to the public database
    func savePublicRecord(_ record: CKRecord) async throws -> CKRecord {
        try await publicDatabase.save(record)
    }

    /// Saves a record to the private database
    func savePrivateRecord(_ record: CKRecord) async throws -> CKRecord {
        try await privateDatabase.save(record)
    }

    /// Deletes a record from the public database
    func deletePublicRecord(recordID: CKRecord.ID) async throws {
        try await publicDatabase.deleteRecord(withID: recordID)
    }

    /// Deletes a record from the private database
    func deletePrivateRecord(recordID: CKRecord.ID) async throws {
        try await privateDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Batch Operations

    /// Performs a batch save to the public database
    func batchSavePublic(records: [CKRecord]) async throws -> [CKRecord] {
        let (saveResults, _) = try await publicDatabase.modifyRecords(
            saving: records,
            deleting: []
        )

        return saveResults.compactMap { _, result in
            try? result.get()
        }
    }

    /// Performs a batch delete from the public database
    func batchDeletePublic(recordIDs: [CKRecord.ID]) async throws {
        _ = try await publicDatabase.modifyRecords(
            saving: [],
            deleting: recordIDs
        )
    }
}

// MARK: - Sync Status

extension CloudKitManager {
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(String)

        var isIdle: Bool {
            self == .idle
        }

        var isSyncing: Bool {
            self == .syncing
        }

        var displayText: String {
            switch self {
            case .idle:
                return "Synced"
            case .syncing:
                return "Syncing..."
            case .error(let message):
                return "Sync Error: \(message)"
            }
        }
    }
}

// MARK: - SwiftData ModelContainer Configuration

extension CloudKitManager {
    /// Creates a ModelContainer configured for CloudKit sync
    static func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            // Public models
            Language.self,
            Spelling.self,
            Word.self,
            Definition.self,
            AccentDialect.self,
            Pronunciation.self,
            Topic.self,
            WordTopic.self,
            SentenceTemplate.self,

            // Private models
            UserProfile.self,
            DefinitionMastery.self,
            PronunciationMastery.self,
            UserSentence.self,
            UserTopicPreference.self,

            // Submission models
            UserSubmission.self,
            AISuggestion.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
