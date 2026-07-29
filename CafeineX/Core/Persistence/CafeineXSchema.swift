import SwiftData

enum CafeineXSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CaffeineEntry.self, Drink.self]
    }
}

enum CafeineXSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CaffeineEntry.self, Drink.self, NicotineEntry.self]
    }
}

enum CafeineXSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            CaffeineEntry.self,
            Drink.self,
            NicotineEntry.self,
            UserProfile.self,
            AwarenessCheckIn.self,
            DrinkMetadata.self,
            HealthSyncOutboxItem.self,
        ]
    }
}

enum CafeineXMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CafeineXSchemaV1.self, CafeineXSchemaV2.self, CafeineXSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: CafeineXSchemaV1.self,
                toVersion: CafeineXSchemaV2.self
            ),
            .lightweight(
                fromVersion: CafeineXSchemaV2.self,
                toVersion: CafeineXSchemaV3.self
            ),
        ]
    }
}
