//
//  ContentViewModel.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import Foundation
import Observation

@MainActor
@Observable
class ContentViewModel {

    private enum DefaultsKey {
        static let filterOptions = "ContentViewModel.filterOptions"
    }

    private static let defaultFilterOptions: Set<FiterOption> = [.hidePartialSplits, .fiveK]
    
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
    private(set) var filterOptions: Set<FiterOption> = defaultFilterOptions {
        didSet {
            sortAndFilter()
            persistFilterOptions()
        }
    }
    
    private let healthKitManager: HealthKitManaging
    private let healthKitStorage: HealthKitStoring
    private let insightsEngine: InsightsEngine
    private let userDefaults: UserDefaults
    
    init(
        healthKitManager: HealthKitManaging = HealthKitManager.shared,
        healthKitStorage: HealthKitStoring = HealthKitStorage.shared,
        insightsEngine: InsightsEngine? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.healthKitManager = healthKitManager
        self.healthKitStorage = healthKitStorage
        self.insightsEngine = insightsEngine ?? InsightsEngine()
        self.userDefaults = userDefaults
        self.filterOptions = Self.loadFilterOptions(from: userDefaults)
        
        #if targetEnvironment(simulator)
        workouts = RunWorkout.mockShowWorkouts
        #else
        workouts = healthKitStorage.getAll()
        #endif

        _ = self.insightsEngine.loadCachedInsights()
    }
    
    func fetchWorkouts() async {
        #if targetEnvironment(simulator)
        workouts = RunWorkout.mockShowWorkouts
        return
        #endif

        do {
            try await healthKitManager.requestAuthorization()
            let fetchedWorkouts = try await healthKitManager.fetchRunWorkouts()
            if fetchedWorkouts != workouts {
                workouts = fetchedWorkouts
                await insightsEngine.generateInsights(for: filteredWorkouts)
            }
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

    private func persistFilterOptions() {
        userDefaults.set(filterOptions.map(\.rawValue), forKey: DefaultsKey.filterOptions)
    }

    private static func loadFilterOptions(from userDefaults: UserDefaults) -> Set<FiterOption> {
        guard let rawValues = userDefaults.array(forKey: DefaultsKey.filterOptions) as? [String] else {
            return defaultFilterOptions
        }

        return Set(rawValues.compactMap(FiterOption.init(rawValue:)))
    }
    
    func clearCache() {
        healthKitStorage.clear()
        workouts = []
        insightsEngine.clearCache()
    }

    var insightsText: String? {
        insightsEngine.insightsText
    }

    var isGeneratingInsights: Bool {
        insightsEngine.isGeneratingInsights
    }

    var shouldShowInsightsCard: Bool {
        insightsEngine.isModelAvailable
    }
}
