import SwiftUI
import Foundation

/// In-app language selection. `.system` follows the OS preferred language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHant = "zh-Hant"
    case en

    var id: String { rawValue }

    /// Localization key for this language's display name in the settings picker.
    var displayKey: String {
        switch self {
        case .system: return "settings.lang.system"
        case .zhHant: return "settings.lang.zh"
        case .en:     return "settings.lang.en"
        }
    }
}

/// Lightweight, in-app localization. Unlike Apple's String Catalog this lets the
/// user switch language live (no app restart): views observe this object, so
/// changing `language` re-renders every string. Defaults to following the system.
@MainActor
final class LocalizationManager: ObservableObject {
    private static let storeKey = "macfocus.language"

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storeKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storeKey) ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: raw) ?? .system
    }

    /// The language actually used for lookups (resolves `.system` to the OS choice).
    var resolved: AppLanguage {
        guard language == .system else { return language }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .zhHant : .en
    }

    /// Look up a string by key. Falls back to English, then to the key itself.
    /// Call it like a function: `loc("nav.timer")`.
    func callAsFunction(_ key: String) -> String {
        L10n.table[resolved]?[key] ?? L10n.table[.en]?[key] ?? key
    }

    func t(_ key: String) -> String { callAsFunction(key) }
}

/// The string tables. Add a key to BOTH languages.
enum L10n {
    static let table: [AppLanguage: [String: String]] = [
        .zhHant: zhHant,
        .en: en,
    ]

    static let zhHant: [String: String] = [
        // Navigation
        "nav.timer": "專注",
        "nav.collection": "圖鑑",
        "nav.gacha": "抽卡",
        "nav.stats": "統計",
        "nav.profile": "我的",
        "nav.settings": "設定",
        "pet.summon": "召喚桌面夥伴",
        "pet.dismiss": "收起桌面夥伴",

        // Desktop companion lines
        "pet.line.1": "專注一下,我陪你!",
        "pet.line.2": "你今天很棒 ✨",
        "pet.line.3": "再撐一下 🍅",
        "pet.line.4": "我相信你做得到!",
        "pet.line.5": "一起加油 💪",
        "pet.line.6": "看我切蘋果!",
        "pet.focusRemain": "專注中 · 還有 %d 分",
        "pet.breakRemain": "休息中 · 還有 %d 分",

        // Timer
        "timer.subtitle": "專注一下,解鎖你的英雄",
        "timer.start": "開始",
        "timer.pause": "暫停",
        "timer.celebrate": "太棒了!我們又更強了!",
        "phase.focus": "專注中",
        "phase.shortBreak": "短休息",
        "phase.longBreak": "長休息",
        "phase.idle": "準備開始",

        // Collection
        "collection.title": "英雄圖鑑",
        "collection.unlocked": "%d / %d 已解鎖",
        "collection.current": "目前的夥伴",
        "collection.setPartner": "設為專注夥伴",
        "common.close": "關閉",
        "card.locked": "尚未解鎖",
        "card.unknown": "？？？",

        // Gacha
        "gacha.title": "召喚之門",
        "gacha.subtitle": "用專注賺來的金幣召喚新英雄。越稀有越難遇見。",
        "gacha.draw": "召喚(%d 金幣)",
        "gacha.notEnough": "金幣不足",
        "gacha.coins": "目前金幣:%d",
        "gacha.debugGrant": "（測試)+500 金幣",
        "gacha.collect": "收下",

        // Profile
        "profile.name": "專注旅人",
        "profile.cloudSync": "雲端同步",
        "profile.cloudDesc": "登入後進度會自動備份,換裝置也不遺失。",
        "profile.signInApple": "使用 Apple 登入",
        "profile.signInEmail": "使用 Email 登入",
        "profile.cloudComingSoon": "雲端同步即將推出",
        "profile.cloudSoonDesc": "目前所有進度會安全保存在這台 Mac。Firebase 登入與跨裝置同步會在後續版本加入。",

        // Stats
        "stats.title": "專注統計",
        "stats.totalFocus": "累積專注",
        "stats.streak": "連續打卡",
        "stats.best": "最佳紀錄",
        "stats.level": "等級",
        "stats.last7": "過去 7 天",
        "streak.unit": "天連續",
        "unit.hours": "小時",
        "unit.days": "天",
        "axis.day": "日",
        "axis.minutes": "分鐘",

        // Settings
        "settings.title": "設定",
        "settings.language": "語言",
        "settings.lang.system": "跟隨系統",
        "settings.lang.zh": "繁體中文",
        "settings.lang.en": "English",
        "settings.timer": "計時",
        "settings.focusLen": "專注時長",
        "settings.shortBreak": "短休息",
        "settings.longBreak": "長休息",
        "settings.rounds": "幾輪後長休",
        "settings.dailyGoal": "每日目標",
        "settings.notifSound": "通知與音效",
        "settings.completeSound": "完成提示音",
        "settings.systemNotif": "系統通知",
        "settings.sfx": "音效",
        "settings.data": "資料與關於",
        "settings.resetProgress": "重設進度",
        "settings.resetConfirm": "確定要清除所有進度嗎?此動作無法復原。",
        "settings.reset": "清除",
        "settings.version": "版本",
        "settings.github": "GitHub 專案",
        "settings.feedback": "意見回饋",
        "unit.min": "分",
        "unit.rounds": "輪",
        "common.cancel": "取消",

        // Daily goal
        "daily.goal": "今日目標",
        "daily.progress": "%d / %d 分",
        "daily.done": "今日目標達成 🎉",
        "notify.focusComplete": "專注完成",
        "notify.focusBody": "你已專注 %d 分鐘。休息一下吧!",

        // Onboarding
        "onboarding.skip": "略過",
        "onboarding.next": "下一步",
        "onboarding.start": "開始專注",
        "onboarding.1.title": "專注賺取獎勵",
        "onboarding.1.body": "完成番茄鐘專注,累積 XP、金幣與連續天數。",
        "onboarding.2.title": "收集你的英雄",
        "onboarding.2.body": "用金幣抽卡,解鎖稀有角色與限定造型。",
        "onboarding.3.title": "桌面夥伴陪你專注",
        "onboarding.3.body": "把喜歡的角色召喚到桌面,專注時一直陪著你。",

        // Pro / paywall
        "pro.title": "Focus Quest Pro",
        "pro.tagline": "解鎖全部,專注更帶勁",
        "pro.benefit.1": "立即解鎖所有傳說角色",
        "pro.benefit.2": "專注金幣 2 倍",
        "pro.benefit.3": "支持獨立開發 + 專屬徽章",
        "pro.subscribe": "訂閱",
        "pro.restore": "還原購買",
        "pro.current": "你已是 Pro 會員 ✨",
        "pro.upgrade": "升級 Pro",
        "pro.member": "Pro 會員",
        "pro.noProducts": "目前無法載入方案,請稍後再試。",
        "pro.maybeLater": "以後再說",

        // Character titles
        "char.aurora.title": "晨曦遊俠",
        "char.vela.title": "夜風刺客",
        "char.lyra.title": "星詠吟遊者",
        "char.seraphine.title": "潮汐術士",
        "char.ember.title": "烈焰法師",
        "char.noctis.title": "暗影女王",
        "char.celestia.title": "天界執劍者",
        "char.aphrodite.title": "黎明女神",
        // Character taglines
        "char.aurora.tagline": "第一道破曉的光,陪你開始專注。",
        "char.vela.tagline": "安靜俐落,專注時最好的搭檔。",
        "char.lyra.tagline": "用旋律幫你進入心流。",
        "char.seraphine.tagline": "如潮水般綿長的專注力。",
        "char.ember.tagline": "點燃你的鬥志,絕不熄滅。",
        "char.noctis.tagline": "掌控時間,如同掌控暗影。",
        "char.celestia.tagline": "累積 10 小時專注才能召喚的傳說。",
        "char.aphrodite.tagline": "25 小時的鍛鍊,只為與女神相遇。",
    ]

    static let en: [String: String] = [
        // Navigation
        "nav.timer": "Focus",
        "nav.collection": "Collection",
        "nav.gacha": "Summon",
        "nav.stats": "Stats",
        "nav.profile": "Profile",
        "nav.settings": "Settings",
        "pet.summon": "Summon companion",
        "pet.dismiss": "Dismiss companion",

        // Desktop companion lines
        "pet.line.1": "Let's focus — I'm right here!",
        "pet.line.2": "You're doing great today ✨",
        "pet.line.3": "Hang in there 🍅",
        "pet.line.4": "I know you can do it!",
        "pet.line.5": "Let's push on together 💪",
        "pet.line.6": "Watch me slice an apple!",
        "pet.focusRemain": "Focusing · %d min left",
        "pet.breakRemain": "On a break · %d min left",

        // Timer
        "timer.subtitle": "Focus a little, unlock your heroes",
        "timer.start": "Start",
        "timer.pause": "Pause",
        "timer.celebrate": "Awesome! We grew stronger again!",
        "phase.focus": "Focusing",
        "phase.shortBreak": "Short Break",
        "phase.longBreak": "Long Break",
        "phase.idle": "Ready to start",

        // Collection
        "collection.title": "Hero Collection",
        "collection.unlocked": "%d / %d unlocked",
        "collection.current": "Current companion",
        "collection.setPartner": "Set as companion",
        "common.close": "Close",
        "card.locked": "Locked",
        "card.unknown": "???",

        // Gacha
        "gacha.title": "Gate of Summoning",
        "gacha.subtitle": "Spend focus-earned coins to summon new heroes. The rarer they are, the harder to meet.",
        "gacha.draw": "Summon (%d coins)",
        "gacha.notEnough": "Not enough coins",
        "gacha.coins": "Coins: %d",
        "gacha.debugGrant": "(Debug) +500 coins",
        "gacha.collect": "Collect",

        // Profile
        "profile.name": "Focus Traveler",
        "profile.cloudSync": "Cloud Sync",
        "profile.cloudDesc": "Sign in to back up your progress and keep it across devices.",
        "profile.signInApple": "Sign in with Apple",
        "profile.signInEmail": "Sign in with Email",
        "profile.cloudComingSoon": "Cloud sync is coming soon",
        "profile.cloudSoonDesc": "Your progress is safely stored on this Mac for now. Firebase sign-in and cross-device sync will arrive in a later release.",

        // Stats
        "stats.title": "Focus Stats",
        "stats.totalFocus": "Total Focus",
        "stats.streak": "Day Streak",
        "stats.best": "Best",
        "stats.level": "Level",
        "stats.last7": "Last 7 days",
        "streak.unit": "day streak",
        "unit.hours": "hrs",
        "unit.days": "days",
        "axis.day": "Day",
        "axis.minutes": "Minutes",

        // Settings
        "settings.title": "Settings",
        "settings.language": "Language",
        "settings.lang.system": "Follow system",
        "settings.lang.zh": "繁體中文",
        "settings.lang.en": "English",
        "settings.timer": "Timer",
        "settings.focusLen": "Focus length",
        "settings.shortBreak": "Short break",
        "settings.longBreak": "Long break",
        "settings.rounds": "Rounds before long break",
        "settings.dailyGoal": "Daily goal",
        "settings.notifSound": "Notifications & Sound",
        "settings.completeSound": "Completion sound",
        "settings.systemNotif": "System notifications",
        "settings.sfx": "Sound effects",
        "settings.data": "Data & About",
        "settings.resetProgress": "Reset progress",
        "settings.resetConfirm": "Erase all progress? This cannot be undone.",
        "settings.reset": "Erase",
        "settings.version": "Version",
        "settings.github": "GitHub project",
        "settings.feedback": "Send feedback",
        "unit.min": "min",
        "unit.rounds": "rounds",
        "common.cancel": "Cancel",

        // Daily goal
        "daily.goal": "Today's goal",
        "daily.progress": "%d / %d min",
        "daily.done": "Daily goal reached 🎉",
        "notify.focusComplete": "Focus complete",
        "notify.focusBody": "You focused for %d minutes. Time for a break!",

        // Onboarding
        "onboarding.skip": "Skip",
        "onboarding.next": "Next",
        "onboarding.start": "Start focusing",
        "onboarding.1.title": "Focus to earn rewards",
        "onboarding.1.body": "Complete Pomodoro sessions to earn XP, coins, and daily streaks.",
        "onboarding.2.title": "Collect your heroes",
        "onboarding.2.body": "Spend coins on draws to unlock rare characters and limited looks.",
        "onboarding.3.title": "A companion on your desktop",
        "onboarding.3.body": "Summon a favorite to your desktop to keep you company while you focus.",

        // Pro / paywall
        "pro.title": "Focus Quest Pro",
        "pro.tagline": "Unlock everything, focus harder",
        "pro.benefit.1": "Instantly unlock all legendary characters",
        "pro.benefit.2": "Earn 2× focus coins",
        "pro.benefit.3": "Support indie development + a supporter badge",
        "pro.subscribe": "Subscribe",
        "pro.restore": "Restore purchases",
        "pro.current": "You're a Pro member ✨",
        "pro.upgrade": "Upgrade to Pro",
        "pro.member": "Pro member",
        "pro.noProducts": "Plans can't be loaded right now. Please try again later.",
        "pro.maybeLater": "Maybe later",

        // Character titles
        "char.aurora.title": "Dawn Ranger",
        "char.vela.title": "Night Assassin",
        "char.lyra.title": "Starsong Bard",
        "char.seraphine.title": "Tide Sorceress",
        "char.ember.title": "Flame Mage",
        "char.noctis.title": "Shadow Queen",
        "char.celestia.title": "Celestial Swordmaiden",
        "char.aphrodite.title": "Dawn Goddess",
        // Character taglines
        "char.aurora.tagline": "The first light of dawn, here to start your focus.",
        "char.vela.tagline": "Quiet and sharp — your best partner while you focus.",
        "char.lyra.tagline": "Melodies that ease you into flow.",
        "char.seraphine.tagline": "Focus as steady and long as the tides.",
        "char.ember.tagline": "Ignites your drive and never lets it fade.",
        "char.noctis.tagline": "Commands time the way she commands the shadows.",
        "char.celestia.tagline": "A legend you can summon after 10 focus hours.",
        "char.aphrodite.tagline": "25 hours of training, just to meet the goddess.",
    ]
}
