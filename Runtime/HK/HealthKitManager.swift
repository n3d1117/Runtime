//
//  HealthKitManager.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import HealthKit

protocol HealthKitManaging {
    func requestAuthorization() async throws
    func fetchRunWorkouts() async throws -> [RunWorkout]
}

actor HealthKitManager: HealthKitManaging {
    
    enum HealthKitError: Error {
        case unavailable
    }
    
    static let shared = HealthKitManager(storage: HealthKitStorage.shared)
    
    private let store: HKHealthStore
    private let storage: HealthKitStoring
    
    init(storage: HealthKitStoring) {
        self.store = HKHealthStore()
        self.storage = storage
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: [
            .workoutType(),
            .distanceWalkingRunningType(),
            .heartRateType(),
            .activeEnergyBurnedType()
        ])
    }
    
    func fetchRunWorkouts() async throws -> [RunWorkout] {
        let runWorkouts: [HKWorkout] = try await store.query(
            type: .workoutType(),
            predicate: .running
        )
        
        let uncachedWorkouts = runWorkouts
            .filter { storage.get(for: $0.uuid) == nil }
        
        let cachedWorkouts = runWorkouts
            .compactMap { storage.get(for: $0.uuid) }
        
        var finalWorkouts = cachedWorkouts
        
        try await withThrowingTaskGroup(of: (HKWorkout, [HKWorkoutEvent], Double?, Measurement<UnitEnergy>?).self) { group in
            for workout in uncachedWorkouts {
                group.addTask { [store] in
                    async let samples: [HKQuantitySample] = store.query(
                        type: .distanceWalkingRunningType(),
                        predicate: .from(workout)
                    )
                    async let heartRateStats: HKStatistics? = store.statistics(
                        quantityType: .heartRateType(),
                        predicate: .from(workout),
                        options: .discreteAverage
                    )
                    async let energyStats: HKStatistics? = store.statistics(
                        quantityType: .activeEnergyBurnedType(),
                        predicate: .from(workout),
                        options: .cumulativeSum
                    )
                    let splits = workout.splits(from: try await samples)
                    let heartRate = try await heartRateStats?
                        .averageQuantity()?
                        .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let energyMeasurement = try await energyStats?
                        .sumQuantity()
                        .map {
                            Measurement(
                                value: $0.doubleValue(for: .kilocalorie()),
                                unit: UnitEnergy.kilocalories
                            )
                        }
                    return (workout, splits, heartRate, energyMeasurement)
                }
            }
            
            for try await (workout, splits, heartRate, energy) in group {
                if let workout = RunWorkout(
                    from: workout,
                    splits: splits,
                    averageHeartRate: heartRate,
                    totalEnergyBurned: energy
                ) {
                    finalWorkouts.append(workout)
                }
            }
        }
        
        finalWorkouts = finalWorkouts
            .sorted { $0.dateInterval.start > $1.dateInterval.start }
        
        storage.cacheWorkouts(finalWorkouts)
        
        return finalWorkouts
    }
}
