# CafeineXCore

Core models, protocols, and utilities for CafeineX.

- Targets: `CafeineXCore`
- Resources: caffeine catalog JSON

## Usage

Add as a Swift Package to your Xcode project, then:

```swift
import CafeineXCore

let catalog = BeverageCatalog()
let items = try catalog.loadDefaults()
```

## Tests

`CafeineXCoreTests` includes a basic test for the catalog loader.
