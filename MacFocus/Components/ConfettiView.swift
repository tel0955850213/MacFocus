import SwiftUI

/// 純 SwiftUI 粒子彩帶。將 `burst` 設為新值即觸發一次噴發。
struct ConfettiView: View {
    var burst: Int

    private let colors: [Color] = [Theme.primary, Theme.accent, Theme.gold, Theme.mint, Theme.primaryHi]

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { _, _ in } // placeholder so TimelineView retains; particles drawn below
        }
        .overlay(ConfettiLayer(burst: burst, colors: colors))
        .allowsHitTesting(false)
    }
}

private struct ConfettiLayer: View {
    var burst: Int
    let colors: [Color]
    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var color: Color
        var size: CGFloat
        var delay: Double
        var rotation: Double
        var drift: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    FallingPiece(piece: p, height: geo.size.height, width: geo.size.width)
                }
            }
            .onChange(of: burst) { _, _ in spawn(in: geo.size) }
        }
    }

    private func spawn(in size: CGSize) {
        pieces = (0..<70).map { _ in
            Piece(x: CGFloat.random(in: 0...size.width),
                  color: colors.randomElement()!,
                  size: CGFloat.random(in: 6...12),
                  delay: Double.random(in: 0...0.3),
                  rotation: Double.random(in: 0...360),
                  drift: CGFloat.random(in: -60...60))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { pieces = [] }
    }
}

private struct FallingPiece: View {
    let piece: ConfettiLayer.Piece
    let height: CGFloat
    let width: CGFloat
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.5)
            .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
            .position(x: piece.x + (animate ? piece.drift : 0),
                      y: animate ? height + 40 : -40)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 2.2).delay(piece.delay)) { animate = true }
            }
    }
}
