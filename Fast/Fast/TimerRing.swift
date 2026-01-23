//
//  TimerRing.swift
//  Fast
//
//  Shared circular progress ring component.
//

import SwiftUI

/// A donut-shaped region for capturing gestures only on the ring area
struct RingShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        return path
    }
}

struct TimerRing<Content: View>: View {
    let progress: CGFloat
    let dialGesture: AnyGesture<DragGesture.Value>?
    @ViewBuilder let content: () -> Content

    init(progress: CGFloat, dialGesture: AnyGesture<DragGesture.Value>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.progress = progress
        self.dialGesture = dialGesture
        self.content = content
    }

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

            // Gesture overlay - only captures touches on the ring area (75-145pt from center)
            if let gesture = dialGesture {
                RingShape(innerRadius: 75, outerRadius: 145)
                    .fill(Color.clear)
                    .contentShape(RingShape(innerRadius: 75, outerRadius: 145))
                    .gesture(gesture)
            }
        }
        .frame(width: 260, height: 260)
    }
}
