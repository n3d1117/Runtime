//
//  HealthKitManager.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import HealthKit

actor HealthKitManager {
    
    enum HealthKitError: Error {
        case unavailable
    }
    
    static let shared = HealthKitManager()
    
    private let store: HKHealthStore
    
    private init() {
        store = HKHealthStore()
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: [
            .workoutType(),
            .distanceWalkingRunningType()
        ])
    }
    
    func fetchRunWorkouts() async throws -> [RunWorkout] {
        let runWorkouts: [HKWorkout] = try await store.query(
            type: .workoutType(),
            predicate: .running
        )
        
        let uncachedWorkouts = runWorkouts
            .filter { HealthKitStorage.shared.get(for: $0.uuid) == nil }
        
        let cachedWorkouts = runWorkouts
            .compactMap { HealthKitStorage.shared.get(for: $0.uuid) }
        
        var finalWorkouts = cachedWorkouts
        
        try await withThrowingTaskGroup(of: (HKWorkout, [HKWorkoutEvent]).self) { group in
            for workout in uncachedWorkouts {
                group.addTask { [store] in
                    let samples: [HKQuantitySample] = try await store.query(
                        type: .distanceWalkingRunningType(),
                        predicate: .from(workout)
                    )
                    return (workout, workout.splits(from: samples))
                }
            }
            
            for try await (workout, splits) in group {
                if let workout = RunWorkout(from: workout, splits: splits) {
                    finalWorkouts.append(workout)
                }
            }
        }
        
        // not needed maybe?
        finalWorkouts = finalWorkouts
            .sorted { $0.dateInterval.start > $1.dateInterval.start }
        
        HealthKitStorage.shared.cacheWorkouts(finalWorkouts)
        
        return finalWorkouts
    }
}
