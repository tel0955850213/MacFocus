import Foundation
import SwiftUI

/// 玩家持久狀態的單一真實來源。本地用 UserDefaults 持久化;
/// 之後接 Firebase 時,只要在 load()/save() 加上雲端同步即可(local-first)。
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var xp: Int = 0
    @Published private(set) var coins: Int = 0
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var sessions: [FocusSession] = []
    @Published private(set) var unlockedIds: Set<String> = []
    @Published var partnerId: String? = nil

    /// 抽卡剛解鎖的新角色 — 由 UI 觀察以播放揭曉動畫。
    @Published var pendingReveal: GameCharacter? = nil

    private var lastFocusDay: Date? = nil
    private let defaultsKey = "macfocus.progress.v1"
    let drawCost = 100

    init() { load() }

    // MARK: - Derived

    var level: Int { Self.level(forXP: xp) }
    var xpIntoLevel: Int { xp - Self.xpThreshold(forLevel: level) }
    var xpForNextLevel: Int { Self.xpThreshold(forLevel: level + 1) - Self.xpThreshold(forLevel: level) }
    var levelProgress: Double {
        let span = xpForNextLevel
        return span > 0 ? Double(xpIntoLevel) / Double(span) : 0
    }
    var totalFocusMinutes: Int { sessions.reduce(0) { $0 + $1.minutes } }
    var totalFocusHours: Double { Double(totalFocusMinutes) / 60.0 }

    func isUnlocked(_ c: GameCharacter) -> Bool { unlockedIds.contains(c.id) }
    var partner: GameCharacter? { partnerId.flatMap { CharacterCatalog.character(id: $0) } }

    // MARK: - Mutations

    /// 完成一段專注後呼叫。回傳本次新解鎖(因時數門檻)的角色,供慶祝畫面使用。
    @discardableResult
    func recordCompletedFocus(minutes: Int) -> [GameCharacter] {
        sessions.append(FocusSession(date: Date(), minutes: minutes))
        xp += minutes * 2
        coins += minutes
        updateStreak()
        let newlyUnlocked = checkTimeGatedUnlocks()
        if partnerId == nil { partnerId = CharacterCatalog.gachaPool.first?.id }
        save()
        return newlyUnlocked
    }

    /// 花金幣抽一張卡。金幣不足回傳 nil。
    func drawGacha() -> GameCharacter? {
        guard coins >= drawCost else { return nil }
        coins -= drawCost
        let pool = CharacterCatalog.gachaPool
        let total = pool.reduce(0.0) { $0 + $1.rarity.drawWeight }
        var roll = Double.random(in: 0..<total)
        var picked = pool.last!
        for c in pool {
            roll -= c.rarity.drawWeight
            if roll < 0 { picked = c; break }
        }
        // 已擁有則退還部分金幣(碎片轉換),仍展示該角色。
        if unlockedIds.contains(picked.id) {
            coins += drawCost / 2
        } else {
            unlockedIds.insert(picked.id)
        }
        pendingReveal = picked
        save()
        return picked
    }

    func setPartner(_ c: GameCharacter) {
        guard isUnlocked(c) else { return }
        partnerId = c.id
        save()
    }

    private func updateStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        defer { lastFocusDay = today }
        guard let last = lastFocusDay else { currentStreak = 1; bestStreak = max(bestStreak, 1); return }
        let lastDay = cal.startOfDay(for: last)
        if cal.isDate(lastDay, inSameDayAs: today) { return } // 今天已記過
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        currentStreak = cal.isDate(lastDay, inSameDayAs: yesterday) ? currentStreak + 1 : 1
        bestStreak = max(bestStreak, currentStreak)
    }

    private func checkTimeGatedUnlocks() -> [GameCharacter] {
        let hours = totalFocusHours
        var unlocked: [GameCharacter] = []
        for c in CharacterCatalog.timeGated where c.unlockHours <= hours && !unlockedIds.contains(c.id) {
            unlockedIds.insert(c.id)
            unlocked.append(c)
        }
        return unlocked
    }

    // MARK: - Level curve

    /// 升下一級所需累積 XP:平滑遞增曲線。
    static func xpThreshold(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (level - 1) * (level - 1) * 100
    }

    static func level(forXP xp: Int) -> Int {
        var lvl = 1
        while xpThreshold(forLevel: lvl + 1) <= xp { lvl += 1 }
        return lvl
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var xp: Int; var coins: Int; var currentStreak: Int; var bestStreak: Int
        var sessions: [FocusSession]; var unlockedIds: [String]
        var partnerId: String?; var lastFocusDay: Date?
    }

    private func save() {
        let snap = Snapshot(xp: xp, coins: coins, currentStreak: currentStreak,
                            bestStreak: bestStreak, sessions: sessions,
                            unlockedIds: Array(unlockedIds), partnerId: partnerId,
                            lastFocusDay: lastFocusDay)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            // 首次啟動:送兩張入門 N 卡。
            unlockedIds = Set(CharacterCatalog.gachaPool.prefix(2).map { $0.id })
            partnerId = unlockedIds.first
            return
        }
        xp = snap.xp; coins = snap.coins
        currentStreak = snap.currentStreak; bestStreak = snap.bestStreak
        sessions = snap.sessions; unlockedIds = Set(snap.unlockedIds)
        partnerId = snap.partnerId; lastFocusDay = snap.lastFocusDay
    }

#if DEBUG
    func _debugGrant(coins: Int) { self.coins += coins; save() }
#endif
}
