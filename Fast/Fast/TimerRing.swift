//
//  TimerRing.swift
//  Fast
//
//  Shared circular progress ring component.
//

import SwiftUI

struct TimerRing<Content: View>: View {
    let progress: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            content()
        }
        .frame(width: 260, height: 260)
    }
}
