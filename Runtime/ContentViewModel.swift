//
//  ContentViewModel.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import Observation

@Observable
class ContentViewModel {
    
    enum SortOption: String, CaseIterable {
        case recent
        case fastest
        
        var title: String {
            switch self {
            case .recent: return "Most Recent"
            case .fastest: return "Fastest"
            }
        }
        
        var icon: String {
            switch self {
            case .recent: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
            case .fastest: return "flame"
            }
        }
    }
    
    enum FiterOption: String, CaseIterable {
        case hidePartialSplits
        case fiveK
        
        var title: String {
            switch self {
            case .hidePartialSplits: return "Hide Partial Splits"
            case .fiveK: return "At Least 5K"
            }
        }
    }
    
    private(set) var filteredWorkouts: [RunWorkout] = []
    
    private var workouts: [RunWorkout] = [] {
        didSet { sortAndFilter() }
    }
    
    var sortOption: SortOption = .recent {
        didSet { sortAndFilter() }
    }
    private(set) var filterOptions: Set<FiterOption> = [.hidePartialSplits, .fiveK] {
        didSet { sortAndFilter() }
    }
    
    private let healthKitManager: HealthKitManaging
    private let healthKitStorage: HealthKitStoring
    
    init(
        healthKitManager: HealthKitManaging = HealthKitManager.shared,
        healthKitStorage: HealthKitStoring = HealthKitStorage.shared
    ) {
        self.healthKitManager = healthKitManager
        self.healthKitStorage = healthKitStorage
        #if targetEnvironment(simulator)
        workouts = RunWorkout.mockShowWorkouts
        #else
        workouts = healthKitStorage.getAll()
        #endif
    }
    
    func fetchWorkouts() async {
        #if targetEnvironment(simulator)
        workouts = RunWorkout.mockShowWorkouts
        return
        #endif

        do {
            try await healthKitManager.requestAuthorization()
            workouts = try await healthKitManager.fetchRunWorkouts()
        } catch {
            print(error)
        }
    }
    
    func applySortOption(_ option: SortOption) {
        sortOption = option
    }
    
    func applyFilterOption(_ option: FiterOption) {
        if filterOptions.contains(option) {
            filterOptions.remove(option)
        } else {
            filterOptions.insert(option)
        }
    }
    
    func sortAndFilter() {
        var finalWorkouts = workouts
        
        for option in filterOptions {
            switch option {
            case .hidePartialSplits:
                finalWorkouts = finalWorkouts.map { workout in
                    var workout = workout
                    workout.splits = workout.splits.filter { $0.distance.value >= 1000 }
                    return workout
                }
            case .fiveK:
                finalWorkouts = finalWorkouts.filter {
                    $0.splits.filter { $0.distance.value >= 1000 }.count >= 5
                }
            }
        }
        
        switch sortOption {
        case .recent:
            finalWorkouts.sort { $0.dateInterval.start > $1.dateInterval.start }
        case .fastest:
            finalWorkouts.sort { $0.totalDuration < $1.totalDuration }
        }
        
        filteredWorkouts = finalWorkouts
    }
    
    func clearCache() {
        healthKitStorage.clear()
        workouts = []
    }
}
