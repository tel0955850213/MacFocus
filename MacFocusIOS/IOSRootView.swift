import SwiftUI

enum IOSAppTab: String, CaseIterable, Identifiable {
    case timer, collection, gacha, stats, profile, settings

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .timer: return "nav.timer"
        case .collection: return "nav.collection"
        case .gacha: return "nav.gacha"
        case .stats: return "nav.stats"
        case .profile: return "nav.profile"
        case .settings: return "nav.settings"
        }
    }

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .collection: return "square.grid.2x2.fill"
        case .gacha: return "bolt.fill"
        case .stats: return "chart.bar.fill"
        case .profile: return "person.crop.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct IOSRootView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("macfocus.onboarded") private var onboarded = false
    @State private var tab: IOSAppTab

    init() {
        #if DEBUG
        let argument = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--screenshot-tab=") }
        let rawValue = argument?.split(separator: "=", maxSplits: 1).last.map(String.init)
        _tab = State(initialValue: rawValue.flatMap(IOSAppTab.init(rawValue:)) ?? .timer)
        #else
        _tab = State(initialValue: .timer)
        #endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                tabletLayout
            } else {
                phoneLayout
            }
        }
        .tint(Theme.primaryHi)
        .overlay { revealOverlay }
        .overlay { onboardingOverlay }
    }

    private var phoneLayout: some View {
        TabView(selection: $tab) {
            ForEach(IOSAppTab.allCases) { item in
                NavigationStack {
                    destination(for: item)
                        .background(Theme.backgroundGradient.ignoresSafeArea())
                }
                .tabItem { Label(loc(item.labelKey), systemImage: item.icon) }
                .tag(item)
            }
        }
    }

    private var tabletLayout: some View {
        NavigationSplitView {
            List {
                ForEach(IOSAppTab.allCases) { item in
                    Button {
                        tab = item
                    } label: {
                        Label(loc(item.labelKey), systemImage: item.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(tab == item ? Theme.primary.opacity(0.32) : Color.clear)
                }
            }
            .navigationTitle("Focus Arcana")
            .scrollContentBackground(.hidden)
            .background(Theme.sidebarGradient)
        } detail: {
            destination(for: tab)
                .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func destination(for item: IOSAppTab) -> some View {
        switch item {
        case .timer: TimerScreen()
        case .collection: CollectionScreen()
        case .gacha: GachaScreen()
        case .stats: StatsScreen()
        case .profile: ProfileScreen()
        case .settings: SettingsScreen()
        }
    }

    @ViewBuilder
    private var revealOverlay: some View {
        if let reveal = progress.pendingReveal {
            GachaRevealView(character: reveal) {
                withAnimation { progress.pendingReveal = nil }
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var onboardingOverlay: some View {
        if !onboarded {
            OnboardingView { onboarded = true }
                .transition(.opacity)
        }
    }
}
