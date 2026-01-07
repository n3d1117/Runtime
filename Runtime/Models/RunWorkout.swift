//
//  RunWorkout.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import Foundation

struct RunWorkout: Identifiable, Hashable, Codable {
    struct Split: Identifiable, Hashable, Codable {
        var id: UUID = UUID()
        let dateInterval: DateInterval
        let distance: Measurement<UnitLength>
        let duration: Duration
        let averageHeartRate: Double?
    }
    
    let id: UUID
    let dateInterval: DateInterval
    let averagePace: Duration?
    let averageHeartRate: Double?
    let totalEnergyBurned: Measurement<UnitEnergy>?
    var totalDistance: Measurement<UnitLength> {
        splits.reduce(.init(value: 0, unit: .meters)) { $0 + $1.distance }
    }
    var totalDuration: Duration {
        .seconds(splits.reduce(.zero) { $0 + $1.duration.inSeconds })
    }
    var totalKilocalories: Double? {
        totalEnergyBurned?.converted(to: .kilocalories).value
    }
    var hasMetrics: Bool {
        averagePace != nil || averageHeartRate != nil || totalKilocalories != nil
    }
    var splits: [Split]
}

extension RunWorkout {
    static let mock: Self = .init(
        id: UUID(),
        dateInterval: DateInterval(start: Date(), duration: 1800),
        averagePace: .seconds(270),
        averageHeartRate: 152,
        totalEnergyBurned: Measurement(value: 480, unit: .kilocalories),
        splits: [
            Split(
                dateInterval: DateInterval(start: Date(), duration: 343),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(343),
                averageHeartRate: 150
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(343), duration: 348),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(348),
                averageHeartRate: 150
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(348), duration: 375),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(375),
                averageHeartRate: 150
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(375), duration: 372),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(372),
                averageHeartRate: 150
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(372), duration: 361),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(361),
                averageHeartRate: 150
            )
        ]
    )
}

extension RunWorkout {
    static var mockShowWorkouts: [RunWorkout] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return [
            mockWorkout(
                start: startOfDay.addingTimeInterval(-3600 * 4),
                paceSeconds: 270,
                heartRate: 158,
                energy: 520,
                splitDurations: [320, 315, 310, 305, 300]
            ),
            mockWorkout(
                start: startOfDay.addingTimeInterval(-3600 * 10),
                paceSeconds: 258,
                heartRate: 165,
                energy: 540,
                splitDurations: [310, 305, 300, 295, 290]
            ),
            mockWorkout(
                start: startOfDay.addingTimeInterval(-86400 - 3600 * 2),
                paceSeconds: 292,
                heartRate: 149,
                energy: 480,
                splitDurations: [335, 330, 328, 325, 320]
            )
        ]
    }

    private static func mockWorkout(
        start: Date,
        paceSeconds: TimeInterval,
        heartRate: Double,
        energy: Double,
        splitDurations: [TimeInterval]
    ) -> RunWorkout {
        let splits = mockSplits(start: start, durations: splitDurations)
        let totalDuration = splitDurations.reduce(0, +)
        return .init(
            id: UUID(),
            dateInterval: DateInterval(start: start, duration: totalDuration),
            averagePace: .seconds(paceSeconds),
            averageHeartRate: heartRate,
            totalEnergyBurned: Measurement(value: energy, unit: UnitEnergy.kilocalories),
            splits: splits
        )
    }

    private static func mockSplits(start: Date, durations: [TimeInterval]) -> [Split] {
        var currentStart = start
        var splits: [Split] = []
        for (index, duration) in durations.enumerated() {
            let interval = DateInterval(start: currentStart, duration: duration)
            splits.append(
                .init(
                    dateInterval: interval,
                    distance: .init(value: 1000, unit: UnitLength.meters),
                    duration: .seconds(duration),
                    averageHeartRate: 150 + Double(index)
                )
            )
            currentStart = interval.end
        }
        return splits
    }
}
