import Foundation
import SQLite3
import SwiftData

@MainActor
enum CafeineXStoreFactory {
    static var defaultStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    static func makePersistentContainer(
        storeURL: URL = defaultStoreURL,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CafeineXSchemaV5.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            return try LegacyV3StoreRecovery.recover(
                storeURL: storeURL,
                initialError: error,
                fileManager: fileManager
            )
        }
    }
}

@MainActor
enum LegacyV3StoreRecovery {
    static func recover(
        storeURL: URL,
        initialError: Error,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        let snapshot: LegacyV3Snapshot
        do {
            snapshot = try LegacyV3StoreReader.read(from: storeURL)
        } catch {
            throw LegacyV3RecoveryError.notRecoverable(
                initialError: initialError,
                recoveryError: error
            )
        }

        let backupDirectory = try makeBackup(
            storeURL: storeURL,
            snapshot: snapshot,
            initialError: initialError,
            fileManager: fileManager
        )

        do {
            try removeStoreFiles(at: storeURL, fileManager: fileManager)
            let container = try makeEmptyCurrentContainer(at: storeURL)
            try importSnapshot(snapshot, into: container)
            DrinkLibrary.backfillDetailsIfNeeded(context: container.mainContext)
            return container
        } catch {
            do {
                try restoreBackup(
                    from: backupDirectory,
                    to: storeURL,
                    fileManager: fileManager
                )
            } catch let restoreError {
                throw LegacyV3RecoveryError.rollbackFailed(
                    backupDirectory: backupDirectory,
                    importError: error,
                    restoreError: restoreError
                )
            }
            throw LegacyV3RecoveryError.importFailed(
                backupDirectory: backupDirectory,
                underlyingError: error
            )
        }
    }

    private static func makeEmptyCurrentContainer(at storeURL: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CafeineXSchemaV5.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func importSnapshot(
        _ snapshot: LegacyV3Snapshot,
        into container: ModelContainer
    ) throws {
        let context = container.mainContext
        context.autosaveEnabled = false

        for value in snapshot.caffeineEntries {
            let entry = CaffeineEntry(
                id: value.id,
                drinkName: value.drinkName,
                caffeineMG: value.caffeineMG,
                consumedAt: value.consumedAt,
                source: CaffeineSource(rawValue: value.sourceRawValue) ?? .manual,
                healthKitUUID: value.healthKitUUIDString.flatMap(UUID.init(uuidString:)),
                createdAt: value.createdAt
            )
            entry.sourceRawValue = value.sourceRawValue
            entry.healthKitUUIDString = value.healthKitUUIDString
            context.insert(entry)
        }

        for value in snapshot.drinks {
            let drink = Drink(
                id: value.id,
                name: value.name,
                caffeineMG: value.caffeineMG,
                category: DrinkCategory(rawValue: value.categoryRawValue) ?? .custom,
                isFavorite: value.isFavorite,
                createdAt: value.createdAt
            )
            drink.categoryRawValue = value.categoryRawValue
            context.insert(drink)
        }

        for value in snapshot.nicotineEntries {
            let entry = NicotineEntry(
                id: value.id,
                product: NicotineProduct(rawValue: value.productRawValue) ?? .other,
                quantity: value.quantity,
                unit: NicotineUnit(rawValue: value.unitRawValue) ?? .pieces,
                usedAt: value.usedAt,
                source: NicotineSource(rawValue: value.sourceRawValue) ?? .manual,
                note: value.note,
                createdAt: value.createdAt
            )
            entry.productRawValue = value.productRawValue
            entry.unitRawValue = value.unitRawValue
            entry.sourceRawValue = value.sourceRawValue
            context.insert(entry)
        }

        for value in snapshot.profiles {
            let profile = UserProfile(
                id: value.id,
                displayName: value.displayName,
                avatarData: value.avatarData,
                goal: ProfileGoal(rawValue: value.goalRawValue) ?? .protectSleep,
                createdAt: value.createdAt,
                updatedAt: value.updatedAt,
                syncIdentifier: value.syncIdentifier,
                syncRevision: value.syncRevision,
                lastSyncedAt: value.lastSyncedAt
            )
            profile.goalRawValue = value.goalRawValue
            context.insert(profile)
        }

        for value in snapshot.checkIns {
            context.insert(
                AwarenessCheckIn(
                    id: value.id,
                    day: value.day,
                    createdAt: value.createdAt
                )
            )
        }

        for value in snapshot.drinkMetadata {
            context.insert(
                DrinkMetadata(
                    drinkID: value.drinkID,
                    isArchived: value.isArchived,
                    useCount: value.useCount,
                    lastUsedAt: value.lastUsedAt,
                    updatedAt: value.updatedAt
                )
            )
        }

        for value in snapshot.outboxItems {
            context.insert(
                HealthSyncOutboxItem(
                    entryID: value.entryID,
                    createdAt: value.createdAt
                )
            )
        }

        try context.save()
    }

    private static func makeBackup(
        storeURL: URL,
        snapshot: LegacyV3Snapshot,
        initialError: Error,
        fileManager: FileManager
    ) throws -> URL {
        let recoveryRoot = storeURL.deletingLastPathComponent()
            .appending(path: "CafeineX Store Recovery", directoryHint: .isDirectory)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let directoryName = formatter.string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
            + "-\(UUID().uuidString.prefix(8))"
        let backupDirectory = recoveryRoot.appending(
            path: directoryName,
            directoryHint: .isDirectory
        )

        try fileManager.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        do {
            for sourceURL in existingStoreFiles(
                at: storeURL,
                fileManager: fileManager
            ) {
                try fileManager.copyItem(
                    at: sourceURL,
                    to: backupDirectory.appending(path: sourceURL.lastPathComponent)
                )
            }

            let manifest = LegacyV3RecoveryManifest(
                createdAt: .now,
                sourceVersion: snapshot.sourceVersion,
                initialError: String(describing: initialError),
                caffeineEntryCount: snapshot.caffeineEntries.count,
                drinkCount: snapshot.drinks.count,
                nicotineEntryCount: snapshot.nicotineEntries.count,
                profileCount: snapshot.profiles.count,
                checkInCount: snapshot.checkIns.count,
                drinkMetadataCount: snapshot.drinkMetadata.count,
                outboxItemCount: snapshot.outboxItems.count
            )
            let manifestData = try JSONEncoder.cafeineXRecoveryEncoder.encode(manifest)
            try manifestData.write(
                to: backupDirectory.appending(path: "recovery-manifest.json"),
                options: .atomic
            )
        } catch {
            try? fileManager.removeItem(at: backupDirectory)
            throw LegacyV3RecoveryError.backupFailed(underlyingError: error)
        }

        return backupDirectory
    }

    private static func restoreBackup(
        from backupDirectory: URL,
        to storeURL: URL,
        fileManager: FileManager
    ) throws {
        try removeStoreFiles(at: storeURL, fileManager: fileManager)
        for suffix in storeFileSuffixes {
            let destination = storeURLForSuffix(suffix, storeURL: storeURL)
            let source = backupDirectory.appending(path: destination.lastPathComponent)
            if fileManager.fileExists(atPath: source.path) {
                try fileManager.copyItem(at: source, to: destination)
            }
        }
    }

    private static func removeStoreFiles(
        at storeURL: URL,
        fileManager: FileManager
    ) throws {
        for url in existingStoreFiles(at: storeURL, fileManager: fileManager) {
            try fileManager.removeItem(at: url)
        }
    }

    private static func existingStoreFiles(
        at storeURL: URL,
        fileManager: FileManager
    ) -> [URL] {
        storeFileSuffixes
            .map { storeURLForSuffix($0, storeURL: storeURL) }
            .filter { fileManager.fileExists(atPath: $0.path) }
    }

    private static let storeFileSuffixes = ["", "-wal", "-shm"]

    private static func storeURLForSuffix(_ suffix: String, storeURL: URL) -> URL {
        suffix.isEmpty
            ? storeURL
            : URL(filePath: storeURL.path + suffix)
    }
}

private struct LegacyV3RecoveryManifest: Codable {
    let createdAt: Date
    let sourceVersion: String
    let initialError: String
    let caffeineEntryCount: Int
    let drinkCount: Int
    let nicotineEntryCount: Int
    let profileCount: Int
    let checkInCount: Int
    let drinkMetadataCount: Int
    let outboxItemCount: Int
}

private extension JSONEncoder {
    static var cafeineXRecoveryEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private enum LegacyV3RecoveryError: LocalizedError {
    case notRecoverable(initialError: Error, recoveryError: Error)
    case backupFailed(underlyingError: Error)
    case importFailed(backupDirectory: URL, underlyingError: Error)
    case rollbackFailed(backupDirectory: URL, importError: Error, restoreError: Error)

    var errorDescription: String? {
        switch self {
        case let .notRecoverable(initialError, recoveryError):
            "The persistent store could not be opened and is not a supported historical V3 store. Original error: \(initialError). Recovery check: \(recoveryError)."
        case let .backupFailed(underlyingError):
            "The historical store was left untouched because its backup could not be completed: \(underlyingError)."
        case let .importFailed(backupDirectory, underlyingError):
            "The V3 import failed and the original store was restored. Backup: \(backupDirectory.path). Error: \(underlyingError)."
        case let .rollbackFailed(backupDirectory, importError, restoreError):
            "The V3 import failed and automatic rollback also failed. The untouched backup remains at \(backupDirectory.path). Import error: \(importError). Restore error: \(restoreError)."
        }
    }
}

private struct LegacyV3Snapshot {
    struct CaffeineValue {
        let id: UUID
        let drinkName: String
        let caffeineMG: Double
        let consumedAt: Date
        let sourceRawValue: String
        let healthKitUUIDString: String?
        let createdAt: Date
    }

    struct DrinkValue {
        let id: UUID
        let name: String
        let caffeineMG: Double
        let categoryRawValue: String
        let isFavorite: Bool
        let createdAt: Date
    }

    struct NicotineValue {
        let id: UUID
        let productRawValue: String
        let quantity: Double
        let unitRawValue: String
        let usedAt: Date
        let sourceRawValue: String
        let note: String?
        let createdAt: Date
    }

    struct ProfileValue {
        let id: UUID
        let displayName: String
        let avatarData: Data?
        let goalRawValue: String
        let createdAt: Date
        let updatedAt: Date
        let syncIdentifier: UUID
        let syncRevision: Int
        let lastSyncedAt: Date?
    }

    struct CheckInValue {
        let id: UUID
        let day: Date
        let createdAt: Date
    }

    struct DrinkMetadataValue {
        let drinkID: UUID
        let isArchived: Bool
        let useCount: Int
        let lastUsedAt: Date?
        let updatedAt: Date
    }

    struct OutboxValue {
        let entryID: UUID
        let createdAt: Date
    }

    let sourceVersion: String
    let caffeineEntries: [CaffeineValue]
    let drinks: [DrinkValue]
    let nicotineEntries: [NicotineValue]
    let profiles: [ProfileValue]
    let checkIns: [CheckInValue]
    let drinkMetadata: [DrinkMetadataValue]
    let outboxItems: [OutboxValue]
}

private enum LegacyV3StoreReader {
    private static let requiredTables: Set<String> = [
        "Z_METADATA",
        "ZCAFFEINEENTRY",
        "ZDRINK",
        "ZNICOTINEENTRY",
        "ZUSERPROFILE",
        "ZAWARENESSCHECKIN",
        "ZDRINKMETADATA",
        "ZHEALTHSYNCOUTBOXITEM",
    ]

    static func read(from storeURL: URL) throws -> LegacyV3Snapshot {
        let database = try SQLiteReadDatabase(url: storeURL)
        let tables = try database.tableNames()
        guard requiredTables.isSubset(of: tables),
              !tables.contains("ZDRINKDETAILS"),
              !tables.contains("ZPHASECSCHEMASTATE") else {
            throw ReaderError.unsupportedTables
        }

        guard try database.quickCheck() else {
            throw ReaderError.integrityCheckFailed
        }
        let sourceVersion = try database.sourceVersion()
        guard sourceVersion == "3.0.0" else {
            throw ReaderError.unsupportedVersion(sourceVersion)
        }

        return LegacyV3Snapshot(
            sourceVersion: sourceVersion,
            caffeineEntries: try database.caffeineEntries(),
            drinks: try database.drinks(),
            nicotineEntries: try database.nicotineEntries(),
            profiles: try database.profiles(),
            checkIns: try database.checkIns(),
            drinkMetadata: try database.drinkMetadata(),
            outboxItems: try database.outboxItems()
        )
    }

    private enum ReaderError: LocalizedError {
        case unsupportedTables
        case integrityCheckFailed
        case unsupportedVersion(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedTables:
                "The SQLite tables do not match the supported CafeineX V3 layout."
            case .integrityCheckFailed:
                "SQLite reported that the historical store is not structurally sound."
            case let .unsupportedVersion(version):
                "Historical recovery supports version 3.0.0 only; found \(version)."
            }
        }
    }
}

private nonisolated final class SQLiteReadDatabase {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        let result = sqlite3_open_v2(
            url.path,
            &handle,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard result == SQLITE_OK, handle != nil else {
            let message = handle.flatMap { sqlite3_errmsg($0) }.map(String.init(cString:))
                ?? "Unknown SQLite error"
            sqlite3_close(handle)
            handle = nil
            throw SQLiteReaderError.openFailed(message)
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    func tableNames() throws -> Set<String> {
        var names: Set<String> = []
        try rows("SELECT name FROM sqlite_master WHERE type = 'table'") { statement in
            names.insert(try requiredText(statement, 0))
        }
        return names
    }

    func quickCheck() throws -> Bool {
        var result: String?
        try rows("PRAGMA quick_check") { statement in
            result = try requiredText(statement, 0)
        }
        return result == "ok"
    }

    func sourceVersion() throws -> String {
        var version: String?
        try rows("SELECT Z_PLIST FROM Z_METADATA LIMIT 1") { statement in
            let data = try requiredData(statement, 0)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
            guard let metadata = plist as? [String: Any],
                  let identifiers = metadata["NSStoreModelVersionIdentifiers"] as? [String],
                  identifiers.count == 1 else {
                throw SQLiteReaderError.invalidMetadata
            }
            version = identifiers[0]
        }
        guard let version else { throw SQLiteReaderError.invalidMetadata }
        return version
    }

    func caffeineEntries() throws -> [LegacyV3Snapshot.CaffeineValue] {
        var values: [LegacyV3Snapshot.CaffeineValue] = []
        try rows(
            "SELECT ZID, ZDRINKNAME, ZCAFFEINEMG, ZCONSUMEDAT, ZSOURCERAWVALUE, ZHEALTHKITUUIDSTRING, ZCREATEDAT FROM ZCAFFEINEENTRY"
        ) { statement in
            let amount = sqlite3_column_double(statement, 2)
            guard amount.isFinite, amount > 0 else {
                throw SQLiteReaderError.invalidValue("CaffeineEntry.caffeineMG")
            }
            values.append(
                .init(
                    id: try requiredUUID(statement, 0),
                    drinkName: try requiredText(statement, 1),
                    caffeineMG: amount,
                    consumedAt: try requiredDate(statement, 3),
                    sourceRawValue: try requiredText(statement, 4),
                    healthKitUUIDString: optionalText(statement, 5),
                    createdAt: try requiredDate(statement, 6)
                )
            )
        }
        try requireUnique(values.map(\.id), label: "CaffeineEntry.id")
        return values
    }

    func drinks() throws -> [LegacyV3Snapshot.DrinkValue] {
        var values: [LegacyV3Snapshot.DrinkValue] = []
        try rows(
            "SELECT ZID, ZNAME, ZCAFFEINEMG, ZCATEGORYRAWVALUE, ZISFAVORITE, ZCREATEDAT FROM ZDRINK"
        ) { statement in
            let amount = sqlite3_column_double(statement, 2)
            guard amount.isFinite, amount > 0 else {
                throw SQLiteReaderError.invalidValue("Drink.caffeineMG")
            }
            values.append(
                .init(
                    id: try requiredUUID(statement, 0),
                    name: try requiredText(statement, 1),
                    caffeineMG: amount,
                    categoryRawValue: try requiredText(statement, 3),
                    isFavorite: sqlite3_column_int(statement, 4) != 0,
                    createdAt: try requiredDate(statement, 5)
                )
            )
        }
        try requireUnique(values.map(\.id), label: "Drink.id")
        return values
    }

    func nicotineEntries() throws -> [LegacyV3Snapshot.NicotineValue] {
        var values: [LegacyV3Snapshot.NicotineValue] = []
        try rows(
            "SELECT ZID, ZPRODUCTRAWVALUE, ZQUANTITY, ZUNITRAWVALUE, ZUSEDAT, ZSOURCERAWVALUE, ZNOTE, ZCREATEDAT FROM ZNICOTINEENTRY"
        ) { statement in
            let quantity = sqlite3_column_double(statement, 2)
            guard quantity.isFinite, quantity > 0 else {
                throw SQLiteReaderError.invalidValue("NicotineEntry.quantity")
            }
            values.append(
                .init(
                    id: try requiredUUID(statement, 0),
                    productRawValue: try requiredText(statement, 1),
                    quantity: quantity,
                    unitRawValue: try requiredText(statement, 3),
                    usedAt: try requiredDate(statement, 4),
                    sourceRawValue: try requiredText(statement, 5),
                    note: optionalText(statement, 6),
                    createdAt: try requiredDate(statement, 7)
                )
            )
        }
        try requireUnique(values.map(\.id), label: "NicotineEntry.id")
        return values
    }

    func profiles() throws -> [LegacyV3Snapshot.ProfileValue] {
        var values: [LegacyV3Snapshot.ProfileValue] = []
        try rows(
            "SELECT ZID, ZDISPLAYNAME, ZAVATARDATA, ZGOALRAWVALUE, ZCREATEDAT, ZUPDATEDAT, ZSYNCIDENTIFIER, ZSYNCREVISION, ZLASTSYNCEDAT FROM ZUSERPROFILE"
        ) { statement in
            let syncRevision = Int(sqlite3_column_int64(statement, 7))
            guard syncRevision >= 0 else {
                throw SQLiteReaderError.invalidValue("UserProfile.syncRevision")
            }
            values.append(
                .init(
                    id: try requiredUUID(statement, 0),
                    displayName: try requiredText(statement, 1),
                    avatarData: optionalData(statement, 2),
                    goalRawValue: try requiredText(statement, 3),
                    createdAt: try requiredDate(statement, 4),
                    updatedAt: try requiredDate(statement, 5),
                    syncIdentifier: try requiredUUID(statement, 6),
                    syncRevision: syncRevision,
                    lastSyncedAt: try optionalDate(statement, 8)
                )
            )
        }
        try requireUnique(values.map(\.id), label: "UserProfile.id")
        try requireUnique(values.map(\.syncIdentifier), label: "UserProfile.syncIdentifier")
        return values
    }

    func checkIns() throws -> [LegacyV3Snapshot.CheckInValue] {
        var values: [LegacyV3Snapshot.CheckInValue] = []
        try rows("SELECT ZID, ZDAY, ZCREATEDAT FROM ZAWARENESSCHECKIN") { statement in
            values.append(
                .init(
                    id: try requiredUUID(statement, 0),
                    day: try requiredDate(statement, 1),
                    createdAt: try requiredDate(statement, 2)
                )
            )
        }
        try requireUnique(values.map(\.id), label: "AwarenessCheckIn.id")
        return values
    }

    func drinkMetadata() throws -> [LegacyV3Snapshot.DrinkMetadataValue] {
        var values: [LegacyV3Snapshot.DrinkMetadataValue] = []
        try rows(
            "SELECT ZDRINKID, ZISARCHIVED, ZUSECOUNT, ZLASTUSEDAT, ZUPDATEDAT FROM ZDRINKMETADATA"
        ) { statement in
            let useCount = Int(sqlite3_column_int64(statement, 2))
            guard useCount >= 0 else {
                throw SQLiteReaderError.invalidValue("DrinkMetadata.useCount")
            }
            values.append(
                .init(
                    drinkID: try requiredUUID(statement, 0),
                    isArchived: sqlite3_column_int(statement, 1) != 0,
                    useCount: useCount,
                    lastUsedAt: try optionalDate(statement, 3),
                    updatedAt: try requiredDate(statement, 4)
                )
            )
        }
        try requireUnique(values.map(\.drinkID), label: "DrinkMetadata.drinkID")
        return values
    }

    func outboxItems() throws -> [LegacyV3Snapshot.OutboxValue] {
        var values: [LegacyV3Snapshot.OutboxValue] = []
        try rows("SELECT ZENTRYID, ZCREATEDAT FROM ZHEALTHSYNCOUTBOXITEM") { statement in
            values.append(
                .init(
                    entryID: try requiredUUID(statement, 0),
                    createdAt: try requiredDate(statement, 1)
                )
            )
        }
        try requireUnique(values.map(\.entryID), label: "HealthSyncOutboxItem.entryID")
        return values
    }

    private func rows(
        _ sql: String,
        consume: (OpaquePointer) throws -> Void
    ) throws {
        guard let handle else { throw SQLiteReaderError.closedDatabase }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw SQLiteReaderError.queryFailed(String(cString: sqlite3_errmsg(handle)))
        }
        defer { sqlite3_finalize(statement) }

        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                try consume(statement)
            case SQLITE_DONE:
                return
            default:
                throw SQLiteReaderError.queryFailed(String(cString: sqlite3_errmsg(handle)))
            }
        }
    }

    private func requiredUUID(_ statement: OpaquePointer, _ index: Int32) throws -> UUID {
        let data = try requiredData(statement, index)
        guard data.count == 16 else {
            throw SQLiteReaderError.invalidValue("UUID blob")
        }
        let bytes = [UInt8](data)
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private func requiredText(_ statement: OpaquePointer, _ index: Int32) throws -> String {
        guard let value = optionalText(statement, index) else {
            throw SQLiteReaderError.invalidValue("Required text")
        }
        return value
    }

    private func optionalText(_ statement: OpaquePointer, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let bytes = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: bytes)
    }

    private func requiredData(_ statement: OpaquePointer, _ index: Int32) throws -> Data {
        guard let data = optionalData(statement, index) else {
            throw SQLiteReaderError.invalidValue("Required data")
        }
        return data
    }

    private func optionalData(_ statement: OpaquePointer, _ index: Int32) -> Data? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        let count = Int(sqlite3_column_bytes(statement, index))
        guard count > 0, let bytes = sqlite3_column_blob(statement, index) else {
            return Data()
        }
        return Data(bytes: bytes, count: count)
    }

    private func requiredDate(_ statement: OpaquePointer, _ index: Int32) throws -> Date {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else {
            throw SQLiteReaderError.invalidValue("Required date")
        }
        let interval = sqlite3_column_double(statement, index)
        guard interval.isFinite else {
            throw SQLiteReaderError.invalidValue("Date interval")
        }
        return Date(timeIntervalSinceReferenceDate: interval)
    }

    private func optionalDate(_ statement: OpaquePointer, _ index: Int32) throws -> Date? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return try requiredDate(statement, index)
    }

    private func requireUnique<T: Hashable>(_ values: [T], label: String) throws {
        guard Set(values).count == values.count else {
            throw SQLiteReaderError.invalidValue("Duplicate \(label)")
        }
    }

    private enum SQLiteReaderError: LocalizedError {
        case openFailed(String)
        case closedDatabase
        case queryFailed(String)
        case invalidMetadata
        case invalidValue(String)

        var errorDescription: String? {
            switch self {
            case let .openFailed(message): "SQLite could not open the historical store: \(message)."
            case .closedDatabase: "The historical SQLite database was already closed."
            case let .queryFailed(message): "A historical SQLite query failed: \(message)."
            case .invalidMetadata: "The store does not contain recognizable Core Data version metadata."
            case let .invalidValue(value): "The historical store contains an invalid \(value)."
            }
        }
    }
}
