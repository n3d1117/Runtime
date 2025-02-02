//
//  WorkoutMiniChartView.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI
import Charts

struct WorkoutMiniChartView: View {
    
    let workout: RunWorkout
    
    var body: some View {
        Chart {
            ForEach(Array(workout.splits.enumerated()), id: \.element.id) { index, split in
                AreaMark(
                    x: .value("Split #", index),
                    y: .value("Duration", split.duration.inSeconds)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.red.secondary)
            }
        }
        .chartYScale(domain: [
            (workout.splits.min(by: { $0.duration < $1.duration })?.duration.inSeconds ?? .zero) - 15,
            workout.splits.max(by: { $0.duration < $1.duration })?.duration.inSeconds ?? .zero
        ])
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    WorkoutMiniChartView(workout: .mock)
}
