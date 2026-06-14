import SwiftUI

/// First-launch onboarding. Three pages explaining the focus loop, the
/// collection/gacha, and the desktop companion. Manual paging (macOS has no
/// page-style TabView). Completion is persisted by the caller.
struct OnboardingView: View {
    @EnvironmentObject var loc: LocalizationManager
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page { let icon: String; let titleKey: String; let bodyKey: String; let tint: Color }
    private var pages: [Page] {
        [
            .init(icon: "timer", titleKey: "onboarding.1.title", bodyKey: "onboarding.1.body", tint: Theme.primaryHi),
            .init(icon: "square.grid.2x2.fill", titleKey: "onboarding.2.title", bodyKey: "onboarding.2.body", tint: Theme.gold),
            .init(icon: "pawprint.fill", titleKey: "onboarding.3.title", bodyKey: "onboarding.3.body", tint: Theme.accent),
        ]
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            LinearGradient(colors: [Theme.primary.opacity(0.25), .clear],
                           startPoint: .top, endPoint: .center).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(loc("onboarding.skip")) { finish() }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(20)
                }

                Spacer()

                let p = pages[page]
                ZStack {
                    Circle().fill(p.tint.opacity(0.18)).frame(width: 150, height: 150)
                    Image(systemName: p.icon)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(p.tint)
                }
                .id(page)
                .transition(.scale.combined(with: .opacity))

                Text(loc(p.titleKey))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 28)
                Text(loc(p.bodyKey))
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .padding(.top, 10)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.primaryHi : Theme.surfaceHi)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 22)

                PrimaryButton(title: page == pages.count - 1 ? loc("onboarding.start") : loc("onboarding.next"),
                              systemImage: page == pages.count - 1 ? "play.fill" : "arrow.right") {
                    if page == pages.count - 1 { finish() }
                    else { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { page += 1 } }
                }
                .frame(maxWidth: 280)
                .padding(.bottom, 44)
            }
        }
    }

    private func finish() { withAnimation(.easeOut(duration: 0.3)) { onFinish() } }
}
