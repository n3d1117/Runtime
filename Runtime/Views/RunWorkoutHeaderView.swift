//
//  RunWorkoutHeaderView.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI

struct RunWorkoutHeaderView: View {

    let workout: RunWorkout
    let isFastest: Bool
    let isSecondFastest: Bool
    let isThirdFastest: Bool
    
    var body: some View {
        HStack {
            Text(workout.dateInterval.start, style: .date)
                .font(.title2)
                .fontWeight(.medium)
            + Text("  ")
            + Text(workout.dateInterval)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isFastest {
                Text("🥇")
            } else if isSecondFastest {
                Text("🥈")
            } else if isThirdFastest {
                Text("🥉")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
