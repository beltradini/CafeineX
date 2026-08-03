# CafeineX Privacy Manifest Audit

Date: 2026-08-01

## Result

CafeineX includes a valid privacy manifest at `CafeineX/PrivacyInfo.xcprivacy`.
The Release archive contains an identical copy at the root of `CafeineX.app`.

Declared behavior:

- Tracking: disabled.
- Tracking domains: none.
- Collected data types: none.
- Required-reason API category: `NSPrivacyAccessedAPICategoryUserDefaults`.
- Approved reason: `CA92.1`, for preferences available only to CafeineX.

## Source inventory

Direct `UserDefaults` access is limited to:

- `AppearanceStore`: selected app appearance.
- `CaffeineSensitivityStore`: selected sensitivity profile.
- `SleepScheduleStore`: bedtime and caffeine cutoff preferences.

No Swift Package Manager dependencies, embedded third-party frameworks, static
third-party libraries, analytics SDKs, advertising SDKs, or tracking domains
were found in the application target.

The linked frameworks in the archived executable are Apple system frameworks
and Swift runtime libraries, including SwiftUI, SwiftData, HealthKit, PhotosUI,
Foundation, and UIKit.

## Xcode validation

- `plutil` validation: passed.
- Release archive without signing: passed.
- Release archive with automatic local signing: passed.
- Store validation build step: passed.
- Manifest copied into archived application: passed.
- Source and archived manifests are byte-for-byte identical: passed.
- Xcode Organizer Privacy Report: generated and visually reviewed.

The Organizer report is a blank one-page PDF. This is consistent with the
manifest declaring no collected-data categories and no tracking domains. The
required-reason API declaration remains visible in `PrivacyInfo.xcprivacy` and
is not rendered as a collected-data category in this report.

The generated PDF was reviewed and then moved out of the application source
repository with the other release artifacts. It contains a blank page because
there are no collected-data categories or tracking domains to render.

## Revalidation gate

Repeat this audit whenever CafeineX adds an SDK, app extension, widget, Live
Activity, App Intent target, networking, analytics, crash reporting, CloudKit,
an account system, or another required-reason API.

For a future archive:

1. Archive the Release scheme.
2. Open Organizer.
3. Control-click the CafeineX archive.
4. Choose **Generate Privacy Report**.
5. Confirm that the report and every bundled privacy manifest match the current
   data flow and App Store Connect privacy answers.

## Apple references

- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Describing use of required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Required-reason API submission requirement](https://developer.apple.com/news/upcoming-requirements/?id=05012024a)
