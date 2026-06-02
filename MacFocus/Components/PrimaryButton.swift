import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var gradient: LinearGradient = Theme.heroGradient
    var enabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            guard enabled else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.bold)
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: Theme.primary.opacity(enabled ? 0.45 : 0), radius: 14, y: 6)
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = p }
        }, perform: {})
    }
}
