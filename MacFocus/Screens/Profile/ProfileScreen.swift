import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var purchases: PurchaseStore
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Avatar = current companion
                if let p = progress.partner {
                    CharacterPortrait(character: p)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.heroGradient, lineWidth: 3))
                }
                Text(loc("profile.name"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lv. \(progress.level) · \(String(format: "%.1f", progress.totalFocusHours)) \(loc("unit.hours"))")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                XPBar(level: progress.level, progress: progress.levelProgress,
                      xpInto: progress.xpIntoLevel, xpSpan: progress.xpForNextLevel)
                    .frame(maxWidth: 320)

                proCard
                    .frame(maxWidth: 360)

                // Member sign-in (Firebase wired up later)
                VStack(spacing: 12) {
                    Text(loc("profile.cloudSync"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(loc("profile.cloudDesc"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PrimaryButton(title: loc("profile.signInApple"), systemImage: "apple.logo",
                                  gradient: LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                                           startPoint: .top, endPoint: .bottom)) {
                        // TODO: Firebase Auth + Sign in with Apple
                    }
                    PrimaryButton(title: loc("profile.signInEmail"), systemImage: "envelope.fill") {
                        // TODO: Firebase Auth
                    }
                }
                .padding(18)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: 360)

                Text("v1.0 · MacFocus")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary.opacity(0.6))
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchases).environmentObject(loc)
        }
    }

    @ViewBuilder private var proCard: some View {
        if purchases.isPro {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                Text(loc("pro.member"))
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Text("PRO").font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.goldGradient, in: Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        } else {
            Button { showPaywall = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill").foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(loc("pro.upgrade"))
                            .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text(loc("pro.tagline"))
                            .font(.system(size: 11, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
    }
}
