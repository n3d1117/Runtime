//
//  RunWorkoutView.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI

struct RunWorkoutView: View {
    
    let workout: RunWorkout
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 8) {
                if workout.hasMetrics {
                    HStack(spacing: 10) {
                        if let pace = workout.averagePace {
                            WorkoutMetricPill(
                                icon: "figure.run",
                                label: "Avg Pace",
                                value: "\(pace.paceString)/km",
                                tint: .orange
                            )
                        }
                        if let heartRate = workout.averageHeartRate {
                            WorkoutMetricPill(
                                icon: "heart.fill",
                                label: "Avg HR",
                                value: "\(Int(heartRate.rounded()))bpm",
                                tint: .red
                            )
                        }
                        if let kilocalories = workout.totalKilocalories {
                            WorkoutMetricPill(
                                icon: "flame.fill",
                                label: "Energy",
                                value: "\(Int(kilocalories.rounded()))kcal",
                                tint: .purple
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
                    
                    Divider()
                        .padding(.vertical, 3)
                }
                
                let averageHeartRateText = workout.averageHeartRate.map { "\(Int($0.rounded()))bpm" } ?? "—"

                HStack(alignment: .lastTextBaseline) {
                    Text("#")
                        .frame(minWidth: 40, alignment: .leading)
                    
                    Text("Time")
                        .frame(minWidth: 70, alignment: .leading)
                    
                    Text("Distance")
                        .frame(minWidth: 80, alignment: .leading)
                    
                    Text("Avg Heart Rate")
                        .frame(minWidth: 80, alignment: .leading)
                }
                .foregroundStyle(.secondary)
                .font(.callout.smallCaps())
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(Array(workout.splits.enumerated()), id: \.element.id) { index, split in
                    HStack {
                        Text("\(index + 1)")
                            .font(.callout.weight(.regular).smallCaps())
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 40, alignment: .leading)
                        
                        Text(split.duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))
                            .foregroundStyle(.yellow)
                            .frame(minWidth: 70, alignment: .leading)
                        
                        Text(split.distance.formatted())
                            .foregroundStyle(.green)
                            .frame(minWidth: 80, alignment: .leading)
                        
                        Text(averageHeartRateText)
                            .foregroundStyle(.red)
                            .frame(minWidth: 80, alignment: .leading)
                    }
                    .font(.system(.title3, design: .rounded).weight(.semibold).lowercaseSmallCaps())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                    .padding(.vertical, 3)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("Tot")
                        .font(.callout.weight(.regular).smallCaps())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 40, alignment: .leading)
                    
                    Text(workout.totalDuration.formatted(.time(pattern: .minuteSecond)))
                        .foregroundStyle(.yellow)
                        .frame(minWidth: 70, alignment: .leading)
                    
                    Text(
                        workout.totalDistance.formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .road,
                                numberFormatStyle: .number.precision(.fractionLength(0...2))
                            )
                        )
                    )
                    .foregroundStyle(.green)
                    .frame(minWidth: 80, alignment: .leading)
                    
                    WorkoutMiniChartView(workout: workout)
                        .frame(width: 110, height: 30)
                        .offset(y: 5)
                }
                .font(.system(.title2, design: .rounded).weight(.semibold).lowercaseSmallCaps())
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
            }
            .padding(.horizontal)
        }
        .fontDesign(.rounded)
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    RunWorkoutView(workout: .mock)
}
