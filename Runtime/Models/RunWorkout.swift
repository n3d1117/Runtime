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
    }
    
    let id: UUID
    let dateInterval: DateInterval
    var totalDistance: Measurement<UnitLength> {
        splits.reduce(.init(value: 0, unit: .meters)) { $0 + $1.distance }
    }
    var totalDuration: Duration {
        .seconds(splits.reduce(.zero) { $0 + $1.duration.inSeconds })
    }
    var splits: [Split]
}

extension RunWorkout {
    static let mock: Self = .init(
        id: UUID(),
        dateInterval: DateInterval(start: Date(), duration: 1800),
        splits: [
            Split(
                dateInterval: DateInterval(start: Date(), duration: 343),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(343)
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(343), duration: 348),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(348)
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(348), duration: 375),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(375)
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(375), duration: 372),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(372)
            ),
            Split(
                dateInterval: DateInterval(start: Date().addingTimeInterval(372), duration: 361),
                distance: Measurement(value: 1000, unit: .meters),
                duration: Duration.seconds(361)
            )
        ]
    )
}
