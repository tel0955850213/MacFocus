import Foundation
import SwiftUI

/// Single source of truth for the player's persistent state. Persisted locally via
/// UserDefaults; to add Firebase later, just hook cloud sync into load()/save()
/// (local-first).
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var xp: Int = 0
    @Published private(set) var coins: Int = 0
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var sessions: [FocusSession] = []
    @Published private(set) var unlockedIds: Set<String> = []
    /// Cumulative focus minutes spent with each companion (character id → minutes).
    @Published private(set) var bondXP: [String: Int] = [:]
    @Published private(set) var alternatePoseIDs: Set<String> = []
    @Published var partnerId: String? = nil

    /// A character just unlocked from a draw — observed by the UI to play the reveal.
    @Published var pendingReveal: GameCharacter? = nil

    /// The most recent completed focus segment — observed by TimerScreen to play
    /// confetti/celebration. Rewards themselves are recorded at the App level so
    /// they land even when the main window was never opened.
    struct FocusCompletion: Equatable {
        let id: UUID
        let minutes: Int
    }
    @Published var lastCompletion: FocusCompletion? = nil

    struct BondLevelUp: Equatable, Identifiable {
        let id = UUID()
        let characterID: String
        let level: Int
    }
    @Published var lastBondLevelUp: BondLevelUp? = nil

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
    /// Minutes focused today — used for the daily-goal ring.
    var todayFocusMinutes: Int { sessions.minutes(on: Date()) }

    /// Cumulative focus minutes with a specific companion.
    func bondMinutes(for character: GameCharacter) -> Int { bondXP[character.id, default: 0] }

    /// Bond level 1...10. Level 10 is reached at 1,800 minutes (~30 hours).
    func bondLevel(for character: GameCharacter) -> Int {
        let minutes = bondMinutes(for: character)
        var level = 1
        while level < Self.bondThresholds.count,
              minutes >= Self.bondThresholds[level] {
            level += 1
        }
        return level
    }

    /// Progress through the current level, normalized to 0...1.
    func bondProgress(for character: GameCharacter) -> Double {
        let level = bondLevel(for: character)
        guard level < Self.bondThresholds.count else { return 1 }
        let lower = Self.bondThresholds[level - 1]
        let upper = Self.bondThresholds[level]
        return Double(bondMinutes(for: character) - lower) / Double(upper - lower)
    }

    func bondMinutesToNextLevel(for character: GameCharacter) -> Int? {
        let level = bondLevel(for: character)
        guard level < Self.bondThresholds.count else { return nil }
        return max(0, Self.bondThresholds[level] - bondMinutes(for: character))
    }

    func usesAlternatePose(for character: GameCharacter) -> Bool {
        alternatePoseIDs.contains(character.id)
    }

    func setUsesAlternatePose(_ enabled: Bool, for character: GameCharacter) {
        guard bondLevel(for: character) >= 7 else { return }
        if enabled {
            alternatePoseIDs.insert(character.id)
        } else {
            alternatePoseIDs.remove(character.id)
        }
        save()
    }

    func displayAssetName(for character: GameCharacter) -> String? {
        guard usesAlternatePose(for: character), let base = character.assetName else {
            return character.assetName
        }
        return "\(base)_alt"
    }

    func isUnlocked(_ c: GameCharacter) -> Bool {
        unlockedIds.contains(c.id)
    }
    var partner: GameCharacter? { partnerId.flatMap { CharacterCatalog.character(id: $0) } }

    // MARK: - Mutations

    /// Call after a focus session ends. Returns characters newly unlocked by the
    /// focus-hours threshold, for the celebration screen.
    @discardableResult
    func recordCompletedFocus(minutes: Int, tag: String? = nil) -> [GameCharacter] {
        sessions.append(FocusSession(date: Date(), minutes: minutes, tag: tag))
        xp += minutes * 2
        coins += minutes
        if let partner {
            let previousLevel = bondLevel(for: partner)
            bondXP[partner.id, default: 0] += minutes
            let newLevel = bondLevel(for: partner)
            if newLevel > previousLevel {
                lastBondLevelUp = BondLevelUp(characterID: partner.id, level: newLevel)
            }
        }
        updateStreak()
        let newlyUnlocked = checkTimeGatedUnlocks()
        if partnerId == nil { partnerId = CharacterCatalog.gachaPool.first?.id }
        lastCompletion = FocusCompletion(id: UUID(), minutes: minutes)
        save()
        return newlyUnlocked
    }

    /// Spend coins to draw one card. Returns nil when there aren't enough coins.
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
        // Already owned: refund half the cost (shard conversion) but still show her.
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
        if cal.isDate(lastDay, inSameDayAs: today) { return } // already counted today
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

    /// Total XP required to reach a level — a smooth increasing curve.
    static func xpThreshold(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (level - 1) * (level - 1) * 100
    }

    static func level(forXP xp: Int) -> Int {
        var lvl = 1
        while xpThreshold(forLevel: lvl + 1) <= xp { lvl += 1 }
        return lvl
    }

    /// Cumulative minutes needed to reach each bond level. Index 0 = Level 1.
    static let bondThresholds = [0, 30, 90, 180, 300, 480, 720, 1_020, 1_380, 1_800]

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var xp: Int; var coins: Int; var currentStreak: Int; var bestStreak: Int
        var sessions: [FocusSession]; var unlockedIds: [String]
        var partnerId: String?; var lastFocusDay: Date?
        // Keep every newly added persisted field optional. Older JSON blobs do
        // not contain it; a non-optional field would make decoding fail and
        // silently reset an existing user's progress.
        var bondXP: [String: Int]?
        var alternatePoseIDs: [String]?
    }

    private func save() {
        let snap = Snapshot(xp: xp, coins: coins, currentStreak: currentStreak,
                            bestStreak: bestStreak, sessions: sessions,
                            unlockedIds: Array(unlockedIds), partnerId: partnerId,
                            lastFocusDay: lastFocusDay, bondXP: bondXP,
                            alternatePoseIDs: Array(alternatePoseIDs))
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            // First launch: grant two starter N cards.
            unlockedIds = Set(CharacterCatalog.gachaPool.prefix(2).map { $0.id })
            partnerId = unlockedIds.first
            return
        }
        xp = snap.xp; coins = snap.coins
        currentStreak = snap.currentStreak; bestStreak = snap.bestStreak
        sessions = snap.sessions; unlockedIds = Set(snap.unlockedIds)
        partnerId = snap.partnerId; lastFocusDay = snap.lastFocusDay
        bondXP = snap.bondXP ?? [:]
        alternatePoseIDs = Set(snap.alternatePoseIDs ?? [])
    }

    /// Erase all progress and re-seed the two starter characters.
    func resetAll() {
        xp = 0; coins = 0; currentStreak = 0; bestStreak = 0
        sessions = []; lastFocusDay = nil
        unlockedIds = Set(CharacterCatalog.gachaPool.prefix(2).map { $0.id })
        partnerId = unlockedIds.first
        pendingReveal = nil
        bondXP = [:]
        lastBondLevelUp = nil
        alternatePoseIDs = []
        save()
    }

#if DEBUG
    func _debugGrant(coins: Int) { self.coins += coins; save() }
#endif
}
