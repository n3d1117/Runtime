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

class HealthKitStorage: HealthKitStoring {

    static let shared = HealthKitStorage()
    private let key = "cachedRunWorkouts"
    
    private init() { }
    
    func cacheWorkouts(_ workouts: [RunWorkout]) {
        UserDefaults.standard.set(
            try? JSONEncoder().encode(workouts),
            forKey: key
        )
    }
    
    func get(for id: UUID) -> RunWorkout? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return (try? JSONDecoder().decode([RunWorkout].self, from: data))?.first { $0.id == id }
    }
    
    func getAll() -> [RunWorkout] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return (try? JSONDecoder().decode([RunWorkout].self, from: data)) ?? []
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
