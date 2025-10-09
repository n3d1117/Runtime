//
//  RunWorkoutsView.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI

struct RunWorkoutsView: View {
    
    let workouts: [RunWorkout]
    let sortOption: ContentViewModel.SortOption
    
    @State private var headerOffsets: [RunWorkout: CGFloat] = [:]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero, pinnedViews: [.sectionHeaders]) {
                ForEach(workouts) { workout in
                    Section {
                        VStack {
                            RunWorkoutView(workout: workout)
                                .padding(.horizontal)
                            
                            if isFirstWorkoutInMonth(workout), workout != workouts.last, sortOption == .recent {
                                Wave(strength: 4, frequency: 45)
                                    .stroke(.secondary, lineWidth: 0.5)
                                    .frame(maxWidth: .infinity, maxHeight: 30)
                                    .padding(.top)
                                    .padding(.bottom, 5)
                            }
                        }
                        .padding(.bottom, 10)
                    } header: {
                        let isFastest = workouts.filter { $0.totalDuration < workout.totalDuration }.isEmpty
                        let isSecondFastest = workouts.filter { $0.totalDuration < workout.totalDuration }.count == 1
                        let isThirdFastest = workouts.filter { $0.totalDuration < workout.totalDuration }.count == 2
                        let offset = headerOffsets[workout] ?? .greatestFiniteMagnitude
                        let pinThreshold: CGFloat = 2
                        let fadeRange: CGFloat = 10
                        let normalized = (offset - pinThreshold) / fadeRange
                        let clamped = min(max(normalized, 0), 1)
                        let pinnedProgress = 1 - clamped
                        let baseOpacity = Double(clamped)
                        let pinnedOpacity = Double(pinnedProgress)
                        
                        RunWorkoutHeaderView(workout: workout, isFastest: isFastest, isSecondFastest: isSecondFastest, isThirdFastest: isThirdFastest)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background {
                                ZStack {
                                    Rectangle()
                                        .fill(.background)
                                        .opacity(baseOpacity)
                                    Rectangle()
                                        .fill(.regularMaterial)
                                        .opacity(pinnedOpacity)
                                }
                            }
                            .onGeometryChange(for: CGFloat.self) {
                                $0.frame(in: .named("scroll")).minY
                            } action: { minY in
                                headerOffsets[workout] = minY
                            }
                    }
                }
            }
            .padding(.top, 10)
        }
        .coordinateSpace(name: "scroll")
    }
    
    private func isFirstWorkoutInMonth(_ workout: RunWorkout) -> Bool {
        workouts
            .filter {
                Calendar.current.isDate(
                    $0.dateInterval.start,
                    equalTo: workout.dateInterval.start,
                    toGranularity: .month
                )
            }
            .min(by: { $0.dateInterval.start < $1.dateInterval.start }) == workout
    }
}
