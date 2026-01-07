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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero, pinnedViews: [.sectionHeaders]) {
                ForEach(workouts) { workout in
                    Section {
                        VStack {
                            RunWorkoutView(workout: workout)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            
                            if isFirstWorkoutInMonth(workout), workout != workouts.last, sortOption == .recent {
                                Wave(strength: 4, frequency: 45)
                                    .stroke(.secondary, lineWidth: 0.5)
                                    .frame(maxWidth: .infinity, maxHeight: 30)
                                    .padding(.top, 5)
                                    .padding(.bottom)
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
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                    }
                }
            }
            .padding(.top, 10)
        }
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
