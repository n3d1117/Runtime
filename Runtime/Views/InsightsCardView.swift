//
//  InsightsCardView.swift
//  Runtime
//
//  Created by ned on 01/08/26.
//

import SwiftUI

struct InsightsCardView: View {
    let text: String
    let isGenerating: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "apple.intelligence")
                    .symbolRenderingMode(.multicolor)
                Text("Insights")
                    .font(.headline)
                Spacer()
                Button(action: { withAnimation(.bouncy) { isExpanded.toggle() } }) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
                }
                .buttonStyle(.plain)
            }

            if isGenerating {
                Text("Generating...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else {
                Text(.init(text))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(isExpanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemBackground)
                .opacity(0.85)
                .cornerRadius(16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .purple.opacity(0.35), radius: 8, x: 0, y: 0)
        .shadow(color: .purple.opacity(0.15), radius: 18, x: 0, y: 0)
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.bouncy) {
                isExpanded.toggle()
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isGenerating)
    }
}
