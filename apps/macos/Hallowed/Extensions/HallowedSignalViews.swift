import SwiftUI

struct HallowedSignalOrb: View {
    let color: Color
    let symbol: String
    var isActive: Bool = true
    var size: CGFloat = 64

    var body: some View {
        TimelineView(.animation) { context in
            let pulse = isActive ? pulseValue(at: context.date) : 0
            ZStack {
                Circle()
                    .fill(color.opacity(0.14 + pulse * 0.08))
                    .frame(width: size, height: size)
                    .scaleEffect(1 + pulse * 0.18)
                    .blur(radius: 10)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.42)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.78, height: size * 0.78)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.26), radius: 24, x: 0, y: 10)

                Image(systemName: symbol)
                    .font(.system(size: size * 0.28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
            }
            .frame(width: size * 1.28, height: size * 1.28)
        }
        .accessibilityHidden(true)
    }

    private func pulseValue(at date: Date) -> CGFloat {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.8) / 2.8
        return CGFloat((sin(phase * .pi * 2 - .pi / 2) + 1) / 2)
    }
}

struct HallowedWaveform: View {
    let color: Color
    var isActive: Bool = true
    var barCount: Int = 7

    var body: some View {
        TimelineView(.animation) { context in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(color.opacity(isActive ? 0.76 : 0.34))
                        .frame(width: 3, height: barHeight(for: index, at: context.date))
                }
            }
            .frame(height: 20)
        }
        .accessibilityHidden(true)
    }

    private func barHeight(for index: Int, at date: Date) -> CGFloat {
        guard isActive else { return 8 }
        let phase = date.timeIntervalSinceReferenceDate * 2.4 + Double(index) * 0.68
        let normalized = (sin(phase) + 1) / 2
        return 6 + CGFloat(normalized) * 14
    }
}
