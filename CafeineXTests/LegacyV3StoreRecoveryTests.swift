import Foundation
import SQLite3
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct LegacyV3StoreRecoveryTests {
    @Test func sanitisedUnknownV3StoreIsBackedUpAndRecoveredIntoV4() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")
        try makeSanitisedV3Fixture(at: storeURL)

        let container = try CafeineXStoreFactory.makePersistentContainer(
            storeURL: storeURL
        )
        let context = container.mainContext

        let caffeine = try context.fetch(FetchDescriptor<CaffeineEntry>())
        let drinks = try context.fetch(FetchDescriptor<Drink>())
        let nicotine = try context.fetch(FetchDescriptor<NicotineEntry>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let checkIns = try context.fetch(FetchDescriptor<AwarenessCheckIn>())
        let details = try context.fetch(FetchDescriptor<DrinkDetails>())
        let outbox = try context.fetch(FetchDescriptor<HealthSyncOutboxItem>())

        #expect(caffeine.count == 1)
        #expect(caffeine[0].id == UUID(uuidString: "00112233-4455-6677-8899-AABBCCDDEEFF"))
        #expect(caffeine[0].drinkName == "Fixture Espresso")
        #expect(caffeine[0].healthKitUUIDString == "11111111-2222-3333-4444-555555555555")
        #expect(drinks.count == 1)
        #expect(drinks[0].isFavorite)
        #expect(nicotine.count == 1)
        #expect(nicotine[0].product == .pouch)
        #expect(profiles.count == 1)
        #expect(profiles[0].displayName == "Fixture User")
        #expect(profiles[0].avatarData == Data([0xCA, 0xFE]))
        #expect(checkIns.count == 1)
        #expect(details.count == 1)
        #expect(details[0].drink?.id == drinks[0].id)
        #expect(details[0].isArchived)
        #expect(details[0].useCount == 7)
        #expect(outbox.count == 1)

        let recoveryRoot = directory.appending(
            path: "CafeineX Store Recovery",
            directoryHint: .isDirectory
        )
        let backups = try FileManager.default.contentsOfDirectory(
            at: recoveryRoot,
            includingPropertiesForKeys: nil
        )
        #expect(backups.count == 1)
        let backup = try #require(backups.first)
        #expect(
            FileManager.default.fileExists(
                atPath: backup.appending(path: "default.store").path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: backup.appending(path: "recovery-manifest.json").path
            )
        )
    }

    @Test func realHistoricalStoreRecoversWhenFixturePathIsProvided() throws {
        guard let fixturePath = ProcessInfo.processInfo.environment[
            "CAFEINEX_LEGACY_V3_STORE"
        ] else {
            return
        }

        let sourceURL = URL(filePath: fixturePath)
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")
        try copyStoreFamily(from: sourceURL, to: storeURL)

        let container = try CafeineXStoreFactory.makePersistentContainer(
            storeURL: storeURL
        )
        let context = container.mainContext

        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<Drink>()) == 5)
        #expect(try context.fetchCount(FetchDescriptor<NicotineEntry>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<AwarenessCheckIn>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DrinkDetails>()) == 5)

        let profile = try #require(
            context.fetch(FetchDescriptor<UserProfile>()).first
        )
        #expect(profile.displayName == "Alex")
        #expect(profile.avatarData?.isEmpty == false)
    }

    @Test func unsupportedStoreIsRejectedWithoutCreatingRecoveryBackup() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")
        try makeSanitisedV3Fixture(at: storeURL, sourceVersion: "9.0.0")

        #expect(throws: Error.self) {
            try CafeineXStoreFactory.makePersistentContainer(storeURL: storeURL)
        }

        #expect(FileManager.default.fileExists(atPath: storeURL.path))
        #expect(try fixtureRowCount(in: "ZCAFFEINEENTRY", storeURL: storeURL) == 1)
        #expect(try fixtureRowCount(in: "ZUSERPROFILE", storeURL: storeURL) == 1)
        #expect(
            !FileManager.default.fileExists(
                atPath: directory.appending(
                    path: "CafeineX Store Recovery",
                    directoryHint: .isDirectory
                ).path
            )
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "CafeineXLegacyRecoveryTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func copyStoreFamily(from sourceURL: URL, to destinationURL: URL) throws {
        for suffix in ["", "-wal", "-shm"] {
            let source = suffix.isEmpty
                ? sourceURL
                : URL(filePath: sourceURL.path + suffix)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let destination = suffix.isEmpty
                ? destinationURL
                : URL(filePath: destinationURL.path + suffix)
            try FileManager.default.copyItem(at: source, to: destination)
        }
    }

    private func makeSanitisedV3Fixture(
        at storeURL: URL,
        sourceVersion: String = "3.0.0"
    ) throws {
        var database: OpaquePointer?
        guard sqlite3_open(storeURL.path, &database) == SQLITE_OK,
              let database else {
            throw FixtureError.sqlite("Could not create fixture database")
        }
        defer { sqlite3_close(database) }

        let metadata = try PropertyListSerialization.data(
            fromPropertyList: [
                "NSStoreModelVersionIdentifiers": [sourceVersion],
                "NSStoreType": "SQLite",
            ],
            format: .binary,
            options: 0
        )

        try execute(
            """
            CREATE TABLE Z_METADATA (Z_VERSION INTEGER PRIMARY KEY, Z_UUID VARCHAR(255), Z_PLIST BLOB);
            CREATE TABLE ZCAFFEINEENTRY (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZCAFFEINEMG FLOAT, ZCONSUMEDAT TIMESTAMP, ZCREATEDAT TIMESTAMP, ZDRINKNAME VARCHAR, ZHEALTHKITUUIDSTRING VARCHAR, ZSOURCERAWVALUE VARCHAR, ZID BLOB);
            CREATE TABLE ZDRINK (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZISFAVORITE INTEGER, ZCAFFEINEMG FLOAT, ZCREATEDAT TIMESTAMP, ZCATEGORYRAWVALUE VARCHAR, ZNAME VARCHAR, ZID BLOB);
            CREATE TABLE ZNICOTINEENTRY (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZCREATEDAT TIMESTAMP, ZQUANTITY FLOAT, ZUSEDAT TIMESTAMP, ZNOTE VARCHAR, ZPRODUCTRAWVALUE VARCHAR, ZSOURCERAWVALUE VARCHAR, ZUNITRAWVALUE VARCHAR, ZID BLOB);
            CREATE TABLE ZUSERPROFILE (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZSYNCREVISION INTEGER, ZCREATEDAT TIMESTAMP, ZLASTSYNCEDAT TIMESTAMP, ZUPDATEDAT TIMESTAMP, ZDISPLAYNAME VARCHAR, ZGOALRAWVALUE VARCHAR, ZID BLOB, ZSYNCIDENTIFIER BLOB, ZAVATARDATA BLOB);
            CREATE TABLE ZAWARENESSCHECKIN (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZCREATEDAT TIMESTAMP, ZDAY TIMESTAMP, ZID BLOB);
            CREATE TABLE ZDRINKMETADATA (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZISARCHIVED INTEGER, ZUSECOUNT INTEGER, ZLASTUSEDAT TIMESTAMP, ZUPDATEDAT TIMESTAMP, ZDRINKID BLOB);
            CREATE TABLE ZHEALTHSYNCOUTBOXITEM (Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZCREATEDAT TIMESTAMP, ZENTRYID BLOB);
            """,
            database: database
        )
        try execute(
            "INSERT INTO Z_METADATA VALUES (1, 'fixture', X'\(metadata.hexString)')",
            database: database
        )
        try execute(
            """
            INSERT INTO ZCAFFEINEENTRY VALUES (1,1,1,64,700000000,700000001,'Fixture Espresso','11111111-2222-3333-4444-555555555555','healthKit',X'00112233445566778899AABBCCDDEEFF');
            INSERT INTO ZDRINK VALUES (1,2,1,1,64,700000002,'espresso','Fixture Espresso',X'102132435465768798A9BACBDCEDFE0F');
            INSERT INTO ZNICOTINEENTRY VALUES (1,3,1,700000003,4,700000004,'Fixture note','pouch','manual','milligrams',X'2031425364758697A8B9CADBECFD0E1F');
            INSERT INTO ZUSERPROFILE VALUES (1,4,1,3,700000005,NULL,700000006,'Fixture User','protectSleep',X'30415263748596A7B8C9DAEBFC0D1E2F',X'405162738495A6B7C8D9EAFB0C1D2E3F',X'CAFE');
            INSERT INTO ZAWARENESSCHECKIN VALUES (1,5,1,700000007,699926400,X'5061728394A5B6C7D8E9FA0B1C2D3E4F');
            INSERT INTO ZDRINKMETADATA VALUES (1,6,1,1,7,700000008,700000009,X'102132435465768798A9BACBDCEDFE0F');
            INSERT INTO ZHEALTHSYNCOUTBOXITEM VALUES (1,7,1,700000010,X'00112233445566778899AABBCCDDEEFF');
            """,
            database: database
        )
    }

    private func execute(_ sql: String, database: OpaquePointer) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) }
                ?? "Unknown SQLite error"
            sqlite3_free(errorMessage)
            throw FixtureError.sqlite(message)
        }
    }

    private func fixtureRowCount(in table: String, storeURL: URL) throws -> Int {
        var database: OpaquePointer?
        guard sqlite3_open_v2(
            storeURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        ) == SQLITE_OK, let database else {
            throw FixtureError.sqlite("Could not reopen fixture database")
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            "SELECT COUNT(*) FROM \(table)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK, let statement else {
            throw FixtureError.sqlite("Could not count fixture rows")
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw FixtureError.sqlite("Fixture count query returned no row")
        }
        return Int(sqlite3_column_int64(statement, 0))
    }

    private enum FixtureError: Error {
        case sqlite(String)
    }
}

private extension Data {
    nonisolated var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }
}
