import SwiftUI

struct CircularTimer: View {
    let progress: Double
    let timeString: String
    let phaseTitle: String
    var tint: LinearGradient = Theme.heroGradient
    var running: Bool = false

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceHi, lineWidth: 22)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(tint, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
                .shadow(color: Theme.accent.opacity(0.5), radius: 10)

            // 進度端點的光點
            Circle()
                .fill(.white)
                .frame(width: 14, height: 14)
                .offset(y: -140)
                .rotationEffect(.degrees(360 * progress))
                .opacity(progress > 0.001 ? 1 : 0)
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: 8) {
                Text(phaseTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Text(timeString)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 300, height: 300)
        .scaleEffect(pulse ? 1.015 : 1)
        .onChange(of: running) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                withAnimation(.default) { pulse = false }
            }
        }
    }
}
