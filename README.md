# CafeineX - WatchOS Caffeine Tracking App

## Overview
CafeineX is a sophisticated WatchOS application designed to help users track their daily caffeine intake directly from their Apple Watch. Built with SwiftUI and leveraging modern iOS frameworks, this app provides a seamless and intuitive way to monitor caffeine consumption throughout the day.

## Features
- Real-time caffeine intake tracking
- Native WatchOS experience
- HealthKit integration for health data synchronization
- SwiftData implementation for efficient data management
- Visual progress tracking of daily caffeine consumption
- Customizable beverage catalog
- Daily intake limits and notifications

## Technologies Used
- SwiftUI
- SwiftData
- HealthKit
- Combine
- XCTest for unit and UI testing

## Architecture
The app follows the MVVM (Model-View-ViewModel) architecture pattern with the following components:
- **Models**: Handles data structures and business logic
- **Views**: User interface components
- **ViewModels**: Business logic and state management
- **Services**: Data management and external integrations
- **Repositories**: Data persistence layer

## Requirements
- WatchOS 10.0+
- Xcode 15.0+
- Swift 5.9+

## Installation
1. Clone the repository
```bash
git clone https://github.com/beltradini/CafeineX.git
```
2. Open `CafeineX.xcodeproj` in Xcode and run on a Watch simulator/device
3. (Optional) Build the Swift package: `Packages/CafeineXCore`
	- This package contains the reusable core models and utilities

## Testing
The project includes comprehensive unit tests and UI tests:
- Unit tests for data repositories and sync services
- UI tests for critical user interactions
- Mock implementations for testing isolation

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

### Modularization
This repo is being modularized to support growth and reuse:
- `Packages/CafeineXCore`: Swift Package with core models, protocols, and utilities (no UI)
- `CafeineX Watch App`: WatchOS app that consumes the package and hosts SwiftUI views

Benefits:
- Clear separation of concerns (domain vs. app/UI)
- Faster builds and easier testing
- Reuse core in future iOS/watchOS extensions

To add the package to Xcode, go to File > Add Packages... and select the local path `Packages/CafeineXCore`.

## License
This project is licensed under the MIT License - see the LICENSE file for details

## Author
Alejandro Beltrán

## Acknowledgments
- Apple Developer Documentation
- SwiftUI Community
- HealthKit Documentation

---
*Note: This project is part of my iOS development portfolio, showcasing modern iOS development practices and WatchOS capabilities.*
