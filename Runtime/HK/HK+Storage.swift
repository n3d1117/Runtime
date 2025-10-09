//
//  HKStorage.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import Foundation

protocol HealthKitStoring {
    func cacheWorkouts(_ workouts: [RunWorkout])
    func get(for id: UUID) -> RunWorkout?
    func getAll() -> [RunWorkout]
    func clear()
}

final class HealthKitStorage: HealthKitStoring {

    static let shared = HealthKitStorage()

    private let defaults: UserDefaults
    private let key = "cachedRunWorkouts"
    private let queue = DispatchQueue(label: "com.ned.runtime.healthkitstorage", attributes: .concurrent)

    private var cachedWorkouts: [RunWorkout]
    private var cachedWorkoutsByID: [UUID: RunWorkout]

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode([RunWorkout].self, from: data)
        {
            self.cachedWorkouts = decoded
            self.cachedWorkoutsByID = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        } else {
            self.cachedWorkouts = []
            self.cachedWorkoutsByID = [:]
        }
    }

    func cacheWorkouts(_ workouts: [RunWorkout]) {
        queue.sync(flags: .barrier) {
            cachedWorkouts = workouts
            cachedWorkoutsByID = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
            persist(workouts)
        }
    }

    func get(for id: UUID) -> RunWorkout? {
        queue.sync {
            cachedWorkoutsByID[id]
        }
    }

    func getAll() -> [RunWorkout] {
        queue.sync {
            cachedWorkouts
        }
    }

    func clear() {
        queue.sync(flags: .barrier) {
            cachedWorkouts = []
            cachedWorkoutsByID = [:]
            defaults.removeObject(forKey: key)
        }
    }

    private func persist(_ workouts: [RunWorkout]) {
        defaults.set(try? JSONEncoder().encode(workouts), forKey: key)
    }
}
