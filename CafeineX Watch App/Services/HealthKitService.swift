//
//  HealthKitService.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import HealthKit
import Combine

final class HealthKitService: HealthKitServiceProtocol {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
    
    private let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)!
    
    private init() { }
    
    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [caffeineType], read: [caffeineType]) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func fetchCaffeineEntries(startDate: Date, endDate: Date) async throws -> [CaffeineEntry] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            let query = HKSampleQuery(sampleType: caffeineType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: NSError(domain: "HealthKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid sample type"]))
                    return
                }
                
                let entries = samples.map { sample -> CaffeineEntry in
                    let uuidString = sample.metadata?["CafeineEntryUUID"] as! String
                    let id = UUID(uuidString: uuidString) ?? UUID()
                    let beverageName = sample.metadata?["beverageName"] as? String ?? "Imported"
                    return CaffeineEntry(
                        id: id,
                        date: sample.startDate,
                        beverageName: beverageName,
                        caffeineMg: sample.quantity.doubleValue(for: .gramUnit(with: .milli))
                    )
                }
                continuation.resume(returning: entries)
            }
            healthStore.execute(query)
        }
    }
    
    func saveCaffeineEntry(_ entry: CaffeineEntry) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: entry.caffeineMg)
            let metadata = [ "CafeineEntryUUID": entry.id.uuidString, "beverageName": entry.beverageName ]
            let sample = HKQuantitySample(
                type: caffeineType,
                quantity: quantity,
                start: entry.date,
                end: entry.date,
                metadata: metadata
            )
            healthStore.save(sample) { (success, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
