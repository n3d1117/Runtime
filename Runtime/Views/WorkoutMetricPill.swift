//
//  WorkoutMetricPill.swift
//  Runtime
//
//  Created by ned on 09/10/25.
//

import SwiftUI

struct WorkoutMetricPill: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
                    .font(.footnote.weight(.medium))
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.semibold).lowercaseSmallCaps())
                    .foregroundStyle(tint)
                    .fixedSize()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}
