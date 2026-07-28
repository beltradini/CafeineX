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

enum CafeineXMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CafeineXSchemaV1.self, CafeineXSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: CafeineXSchemaV1.self,
                toVersion: CafeineXSchemaV2.self
            ),
        ]
    }
}
