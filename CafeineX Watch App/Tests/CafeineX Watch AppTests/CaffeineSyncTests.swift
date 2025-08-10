//
//  CaffeineSyncTests.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import XCTest
@testable import CafeineX_Watch_App

final class CaffeineSyncServiceTests: XCTestCase {
    func testSynchronize_importsNewEntriesFromHealthKit() {
        // Arrange
        let localEntry = CaffeineEntry(id: UUID(), date: Date(), beverageName: "Coffee", caffeineMg: 100)
        let hkEntry = CaffeineEntry(id: UUID(), date: Date(), beverageName: "Tea", caffeineMg: 50)
        
        let mockRepo = MockCaffeineDataRepository()
        mockRepo.entries = [localEntry]
        
        let mockHealthKit = MockHealthKitService()
        mockHealthKit.fetchedEntries = [hkEntry]
        
        let syncService = CaffeineSyncService(
            healthKitService: mockHealthKit,
            dataRepository: mockRepo
        )
        
        // Act
        let expectation = self.expectation(description: "Sync completed")
        syncService.synchronize { result in
            // Assert
            XCTAssertTrue(mockRepo.entries.contains(where: { $0.id == hkEntry.id }))
            XCTAssertEqual(mockRepo.entries.count, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testSynchronize_exportsNewEntriesToHealthKit() {
        // Arrange
        let localEntry = CaffeineEntry(id: UUID(), date: Date(), beverageName: "Coffee", caffeineMg: 100)
        
        let mockRepo = MockCaffeineDataRepository()
        mockRepo.entries = [localEntry]
        
        let mockHealthKit = MockHealthKitService()
        mockHealthKit.fetchedEntries = [] // HealthKit vacío
        
        let syncService = CaffeineSyncService(
            healthKitService: mockHealthKit,
            dataRepository: mockRepo
        )
        
        // Act
        let expectation = self.expectation(description: "Sync completed")
        syncService.synchronize { result in
            // Assert
            XCTAssertTrue(mockHealthKit.savedEntries.contains(where: { $0.id == localEntry.id }))
            XCTAssertEqual(mockHealthKit.savedEntries.count, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testSynchronize_avoidsDuplicates() {
        // Arrange
        let entry = CaffeineEntry(id: UUID(), date: Date(), beverageName: "Coffee", caffeineMg: 100)
        
        let mockRepo = MockCaffeineDataRepository()
        mockRepo.entries = [entry]
        
        let mockHealthKit = MockHealthKitService()
        mockHealthKit.fetchedEntries = [entry] // Mismo ID, debería evitar duplicado
        
        let syncService = CaffeineSyncService(
            healthKitService: mockHealthKit,
            dataRepository: mockRepo
        )
        
        // Act
        let expectation = self.expectation(description: "Sync completed")
        syncService.synchronize { result in
            // Assert
            XCTAssertEqual(mockRepo.entries.filter { $0.id == entry.id }.count, 1)
            XCTAssertEqual(mockHealthKit.savedEntries.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
}
