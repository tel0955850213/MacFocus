import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case timer, collection, gacha, stats, profile
    var id: String { rawValue }
    var label: String {
        switch self {
        case .timer: return "專注"
        case .collection: return "圖鑑"
        case .gacha: return "抽卡"
        case .stats: return "統計"
        case .profile: return "我的"
        }
    }
    var icon: String {
        switch self {
        case .timer: return "timer"
        case .collection: return "square.grid.2x2.fill"
        case .gacha: return "sparkles"
        case .stats: return "chart.bar.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var pet: PetController
    @EnvironmentObject var engine: TimerEngine
    @State private var tab: AppTab = .timer

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    switch tab {
                    case .timer: TimerScreen()
                    case .collection: CollectionScreen()
                    case .gacha: GachaScreen()
                    case .stats: StatsScreen()
                    case .profile: ProfileScreen()
                    }
                }
            }
        }
        .overlay {
            if let reveal = progress.pendingReveal {
                GachaRevealView(character: reveal) {
                    withAnimation { progress.pendingReveal = nil }
                }
                .transition(.opacity)
            }
        }
    }

    private var sidebar: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Quest")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.primaryHi)
                    .padding(.horizontal, 14).padding(.top, 18).padding(.bottom, 12)

                ForEach(AppTab.allCases) { t in
                    SidebarRow(tab: t, selected: tab == t) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tab = t }
                    }
                }
                Spacer()
                petToggle.padding(.horizontal, 14)
                coinPill.padding(14)
            }
        }
        .onChange(of: progress.partnerId) { _, _ in pet.refreshIfShowing() }
    }

    private var petToggle: some View {
        Button {
            pet.toggle(progress: progress, engine: engine)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: pet.isShowing ? "pawprint.fill" : "pawprint")
                    .foregroundStyle(pet.isShowing ? Theme.accent : Theme.textSecondary)
                Text(pet.isShowing ? "收起桌面夥伴" : "召喚桌面夥伴")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(pet.isShowing ? .white : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pet.isShowing ? Theme.accent.opacity(0.18) : Theme.surfaceHi))
        }
        .buttonStyle(.plain)
        .disabled(progress.partner == nil)
    }

    private var coinPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "bitcoinsign.circle.fill").foregroundStyle(Theme.gold)
            Text("\(progress.coins)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceHi, in: Capsule())
    }
}

private struct SidebarRow: View {
    let tab: AppTab
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22)
                Text(tab.label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(selected ? .white : Theme.textSecondary)
            .padding(.vertical, 10).padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Theme.primary.opacity(0.9) : .clear))
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}
