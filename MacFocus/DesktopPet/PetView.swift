import SwiftUI

/// Desktop companion: a single nice sprite + gentle procedural idle motion.
/// Tapping plays a short action clip (when those frames exist) and a speech line.
/// Hosted in an NSPanel, so `engine` and `loc` are passed in explicitly rather
/// than read from the SwiftUI environment.
struct PetView: View {
    let character: GameCharacter
    @ObservedObject var engine: TimerEngine
    @ObservedObject var loc: LocalizationManager
    var onClose: () -> Void = {}

    @State private var startDate = Date()
    @State private var clip: PetClip? = nil
    @State private var clipStart = Date()
    @State private var pokeLine: String? = nil
    @State private var hovering = false

    // MARK: - Action clip definitions (frame-name suffix + hold seconds)

    enum PetClip {
        case eatApple, sword, chop
        var frames: [(String, Double)] {
            switch self {
            case .eatApple: return [("apple_hold", 0.45), ("apple_bite", 0.55), ("apple_bite", 0.35)]
            case .sword:    return [("sword_up", 0.35), ("sword_slash", 0.35), ("sword_slash", 0.2)]
            case .chop:     return [("apple_hold", 0.3), ("apple_chop", 0.75)]
            }
        }
        var total: Double { frames.reduce(0) { $0 + $1.1 } }
    }

    private var lines: [String] { (1...6).map { loc("pet.line.\($0)") } }

    private var timerBubble: String? {
        guard engine.isRunning else { return nil }
        let mins = Int(ceil(Double(engine.remaining) / 60.0))
        switch engine.phase {
        case .focus:                  return String(format: loc("pet.focusRemain"), mins)
        case .shortBreak, .longBreak: return String(format: loc("pet.breakRemain"), mins)
        case .idle:                   return nil
        }
    }
    private var bubbleText: String? { pokeLine ?? timerBubble }

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(startDate)
            let s = sample(at: t)

            ZStack(alignment: .top) {
                if let bubbleText {
                    bubble(bubbleText).offset(y: -2).zIndex(1)
                }
                VStack(spacing: 0) {
                    Spacer(minLength: bubbleText == nil ? 0 : 52)
                    spriteImage(named: s.frame)
                        .frame(width: 160, height: 160)
                        .scaleEffect(x: s.scaleX, y: s.scaleY, anchor: .bottom)
                        .offset(x: s.dx, y: s.dy)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 6)
                        .contentShape(Rectangle())
                        .onTapGesture { poke() }
                }
            }
            .frame(width: 200, height: 230)
        }
        .overlay(alignment: .topTrailing) {
            if hovering {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16)).foregroundStyle(.white.opacity(0.85)).shadow(radius: 2)
                }.buttonStyle(.plain).padding(6).transition(.opacity)
            }
        }
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
    }

    // MARK: - 每幀計算(frame 名 + 變形 + 胸前晃動振幅)

    private func sample(at t: Double)
        -> (frame: String, dx: Double, dy: Double, rot: Double, scaleX: Double, scaleY: Double, jiggle: Double) {

        // 1) 動作 clip 進行中 → 換成該動作的姿勢幀(純換圖,不做位移/旋轉)。
        //    目前動作幀尚未重產,缺幀會 fallback 回 idle(看起來就是站著)。
        if let clip {
            let e = Date().timeIntervalSince(clipStart)
            if e < clip.total {
                var acc = 0.0, name = clip.frames.first!.0
                for (f, d) in clip.frames { acc += d; if e < acc { name = f; break } }
                return (name, 0, 0, 0, 1, 1, 0)
            }
        }

        // 2) 待機:只做非常輕微的呼吸起伏,不旋轉、不亂跳、不扭曲。
        let breath = sin(t * 2 * .pi / 3.0)
        return ("idle", 0, breath * -1.2, 0, 1, 1 + breath * 0.012, 0)
    }

    // MARK: - 圖片(找不到該動作幀就退回 idle / 基本立繪)

    private func spriteImage(named state: String) -> some View {
        let candidates = ["pet_\(character.id)_\(state)", "pet_\(character.id)_idle", "pet_\(character.id)"]
        let name = candidates.first { NSImage(named: $0) != nil }
        return Group {
            if let name {
                Image(name).resizable().interpolation(.high).aspectRatio(contentMode: .fit)
            } else {
                Circle().fill(character.swatch.gradient)
                    .overlay(Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(.white.opacity(0.8)))
                    .frame(width: 120, height: 120)
            }
        }
    }

    private func bubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background((pokeLine != nil ? Theme.accent : Theme.primary).gradient,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 170)
            .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
            .id(text)
    }

    // MARK: - Interaction: tapping plays a random action clip + a speech line.

    private func poke() {
        play([.eatApple, .sword, .chop].randomElement()!)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { pokeLine = lines.randomElement() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.3)) { pokeLine = nil }
        }
    }

    private func play(_ c: PetClip) {
        clip = c; clipStart = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + c.total) { if clip == c { clip = nil } }
    }
}
