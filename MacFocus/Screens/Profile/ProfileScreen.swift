import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // 頭像 = 目前夥伴
                if let p = progress.partner {
                    CharacterPortrait(character: p)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.heroGradient, lineWidth: 3))
                }
                Text("專注旅人")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lv. \(progress.level) · 累積 \(String(format: "%.1f", progress.totalFocusHours)) 小時")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                XPBar(level: progress.level, progress: progress.levelProgress,
                      xpInto: progress.xpIntoLevel, xpSpan: progress.xpForNextLevel)
                    .frame(maxWidth: 320)

                // 會員登入(Firebase 之後接上)
                VStack(spacing: 12) {
                    Text("雲端同步")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("登入後進度會自動備份,換裝置也不遺失。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PrimaryButton(title: "使用 Apple 登入", systemImage: "apple.logo",
                                  gradient: LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                                           startPoint: .top, endPoint: .bottom)) {
                        // TODO: Firebase Auth + Sign in with Apple
                    }
                    PrimaryButton(title: "使用 Email 登入", systemImage: "envelope.fill") {
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
    }
}
