//
//  HK+Utils.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import HealthKit

extension HKObjectType {
    static func distanceWalkingRunningType() -> HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
    
    static func heartRateType() -> HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    }
    
    static func activeEnergyBurnedType() -> HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    }
}

extension NSPredicate: @retroactive @unchecked Sendable {
    static let running = HKQuery.predicateForWorkouts(with: .running)
    static func from(_ workout: HKWorkout) -> NSPredicate {
        HKQuery.predicateForObjects(from: workout)
    }
}

extension NSSortDescriptor: @retroactive @unchecked Sendable {
    static let byDate = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
}

extension Int {
    static let noLimit = HKObjectQueryNoLimit
}

extension HKHealthStore {
    func query<T>(
        type: HKSampleType,
        predicate: NSPredicate?,
        limit: Int = .noLimit,
        sortDescriptors: [NSSortDescriptor]? = [.byDate]
    ) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let results = results as? [T] {
                    continuation.resume(returning: results)
                } else {
                    continuation.resume(returning: [])
                }
            }
            execute(query)
        }
    }
    
    func statistics(
        quantityType: HKQuantityType,
        predicate: NSPredicate?,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics)
                }
            }
            execute(query)
        }
    }
}

extension HKWorkout {
    /// Returns splits computed from the given samples (with pause time removed),
    /// for the specified target distance (in meters)
    func splits(from samples: [HKQuantitySample], targetDistance: Double = 1000.0) -> [HKWorkoutEvent] {
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
        
        var splits = [HKWorkoutEvent]()
        var currentDistance = 0.0
        var currentActiveDuration: TimeInterval = 0
        var previousEndDate = startDate
        var segmentStartTime = startDate
        
        for sample in sortedSamples {
            // If there’s a gap between the previous sample and this one,
            // add its effective active time (wall time minus paused time).
            if sample.startDate > previousEndDate {
                currentActiveDuration += effectiveActiveTime(at: sample.startDate) - effectiveActiveTime(at: previousEndDate)
            }
            
            let sampleDistance = sample.quantity.doubleValue(for: HKUnit.meter())
            let sampleStart = max(sample.startDate, startDate)
            let sampleActiveDuration = effectiveActiveTime(at: sample.endDate) - effectiveActiveTime(at: sampleStart)
            
            var remainingDistance = sampleDistance
            var remainingActiveDuration = sampleActiveDuration
            
            // Consume the sample. If it crosses one or more target distance boundaries, split out those portions.
            while remainingDistance > 0 {
                let distanceNeeded = targetDistance - currentDistance
                if remainingDistance >= distanceNeeded {
                    let fraction = distanceNeeded / remainingDistance
                    let activeForNeeded = remainingActiveDuration * fraction
                    currentDistance += distanceNeeded
                    currentActiveDuration += activeForNeeded
                    
                    // Add the split
                    let eventInterval = DateInterval(start: segmentStartTime, duration: currentActiveDuration)
                    let metadata = ["distance": targetDistance, "duration": currentActiveDuration]
                    let split = HKWorkoutEvent(type: .segment, dateInterval: eventInterval, metadata: metadata)
                    splits.append(split)
                    
                    // Prepare for the next segment
                    segmentStartTime = eventInterval.end
                    remainingDistance -= distanceNeeded
                    remainingActiveDuration -= activeForNeeded
                    currentDistance = 0
                    currentActiveDuration = 0
                } else {
                    currentDistance += remainingDistance
                    currentActiveDuration += remainingActiveDuration
                    remainingDistance = 0
                    remainingActiveDuration = 0
                }
            }
            
            previousEndDate = sample.endDate
        }
        
        // Add a final split if there’s any distance remaining
        if currentDistance > 0 {
            let eventInterval = DateInterval(start: segmentStartTime, duration: currentActiveDuration)
            let metadata = ["distance": currentDistance, "duration": currentActiveDuration]
            let split = HKWorkoutEvent(type: .segment, dateInterval: eventInterval, metadata: metadata)
            splits.append(split)
        }
        
        return splits
    }
    
    // MARK: - Effective Active Time Calculation
    
    /// Returns the active time elapsed from the workout’s start until the given date,
    /// subtracting any time during which the workout was paused.
    private func effectiveActiveTime(at date: Date) -> TimeInterval {
        let elapsed = date.timeIntervalSince(startDate)
        let paused = totalPausedTime(in: DateInterval(start: startDate, end: date))
        return elapsed - paused
    }
    
    /// Returns the total paused time (in seconds) overlapping the given interval,
    /// as determined from the workout’s events.
    private func totalPausedTime(in interval: DateInterval) -> TimeInterval {
        guard let workoutEvents, !workoutEvents.isEmpty else { return 0 }
        
        var total: TimeInterval = 0
        var pauseStart: Date? = nil
        
        for event in workoutEvents {
            switch event.type {
            case .pause:
                pauseStart = event.dateInterval.start
            case .resume:
                if let pauseStart {
                    let pauseInterval = DateInterval(start: pauseStart, end: event.dateInterval.end)
                    if let overlap = pauseInterval.intersection(with: interval) {
                        total += overlap.duration
                    }
                }
                pauseStart = nil
            default:
                break
            }
        }
        
        return total
    }
}

// Glue

extension RunWorkout {
    init?(
        from workout: HKWorkout,
        splits: [HKWorkoutEvent],
        averageHeartRate: Double?,
        totalEnergyBurned: Measurement<UnitEnergy>?
    ) {
        guard workout.workoutActivityType == .running else {
            return nil
        }
        
        let splitModels = splits.compactMap { RunWorkout.Split(from: $0) }
        self.id = workout.uuid
        self.dateInterval = DateInterval(start: workout.startDate, end: workout.endDate)
        self.averageHeartRate = averageHeartRate
        self.totalEnergyBurned = totalEnergyBurned
        self.averagePace = RunWorkout.estimateAveragePace(from: splitModels)
            ?? RunWorkout.estimateAveragePace(from: workout)
        self.splits = splitModels
    }
}

extension RunWorkout.Split {
    init?(from workoutEvent: HKWorkoutEvent) {
        guard workoutEvent.type == .segment,
              let distance = workoutEvent.metadata?["distance"] as? Double,
              let duration = workoutEvent.metadata?["duration"] as? TimeInterval else {
            return nil
        }
        self.dateInterval = workoutEvent.dateInterval
        self.distance = Measurement(value: distance, unit: .meters)
        self.duration = .seconds(duration)
    }
}

private extension RunWorkout {
    static func estimateAveragePace(from splits: [Split]) -> Duration? {
        let totalDistanceMeters = splits
            .map { $0.distance.converted(to: .meters).value }
            .reduce(0, +)
        let totalSeconds = splits
            .map(\.duration.inSeconds)
            .reduce(0, +)
        
        guard totalDistanceMeters > 0, totalSeconds > 0 else { return nil }
        let secondsPerMeter = Double(totalSeconds) / totalDistanceMeters
        return .seconds(secondsPerMeter * 1000)
    }
    
    static func estimateAveragePace(from workout: HKWorkout) -> Duration? {
        guard let totalDistanceQuantity = workout.totalDistance else {
            return nil
        }
        let totalMeters = totalDistanceQuantity.doubleValue(for: .meter())
        guard totalMeters > 0 else { return nil }
        let secondsPerMeter = workout.duration / totalMeters
        guard secondsPerMeter.isFinite else { return nil }
        return .seconds(secondsPerMeter * 1000)
    }
}
