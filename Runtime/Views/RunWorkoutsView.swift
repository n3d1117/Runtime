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
    
    @State private var pinnedStates: [RunWorkout: Bool] = [:]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero, pinnedViews: [.sectionHeaders]) {
                ForEach(workouts) { workout in
                    Section {
                        VStack {
                            RunWorkoutView(workout: workout)
                                .padding(.horizontal)
                            
                            let a = workouts.filter {
                                Calendar.current.isDate(
                                    $0.dateInterval.start,
                                    equalTo: workout.dateInterval.start,
                                    toGranularity: .month
                                )
                            }.min {
                                $0.dateInterval.start < $1.dateInterval.start
                            }
                            
                            if a == workout, workout != workouts.last, sortOption == .recent {
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
                        
                        RunWorkoutHeaderView(workout: workout, isFastest: isFastest, isSecondFastest: isSecondFastest, isThirdFastest: isThirdFastest)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .if(pinnedStates[workout] ?? false) {
                                $0.background(.regularMaterial)
                            }
                            .if(!(pinnedStates[workout] ?? false)) {
                                $0.background(.background)
                            }
                            .onGeometryChange(for: CGFloat.self) {
                                $0.frame(in: .named("scroll")).minY
                            } action: { minY in
                                pinnedStates[workout] = minY <= 2.0
                            }
                    }
                }
            }
            .padding(.top, 10)
        }
        .coordinateSpace(name: "scroll")
    }
}
