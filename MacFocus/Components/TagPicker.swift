import SwiftUI

/// Chooses the intent for the next focus session. The selection is captured by
/// TimerEngine when focus starts, so changing it later cannot rewrite history.
struct TagPicker: View {
    @Binding var selection: String?
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var loc: LocalizationManager
    @State private var newTag = ""
    @State private var showingAddTag = false

    private var tags: [String] {
        FocusTag.allCases.map(\.rawValue) + settings.customTags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(loc("tag.title"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: loc("tag.none"), tag: nil)
                    ForEach(tags, id: \.self) { tag in
                        chip(title: displayName(for: tag), tag: tag)
                            .contextMenu {
                                if settings.customTags.contains(tag) {
                                    Button(role: .destructive) {
                                        settings.removeCustomTag(tag)
                                        if selection == tag { selection = nil }
                                    } label: {
                                        Label(loc("tag.remove"), systemImage: "trash")
                                    }
                                }
                            }
                    }
                    Button {
                        showingAddTag.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Theme.primaryHi)
                            .background(Theme.surfaceHi, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(loc("tag.add"))
                    .popover(isPresented: $showingAddTag, arrowEdge: .bottom) {
                        addTagPopover
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func chip(title: String, tag: String?) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selection = tag
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(selection == tag ? .white : Theme.textSecondary)
                .padding(.horizontal, 13)
                .frame(height: 30)
                .background(selection == tag ? Theme.primary : Theme.surfaceHi,
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var addTagPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("tag.add"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            TextField(loc("tag.placeholder"), text: $newTag)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addTag)
            HStack {
                Spacer()
                Button(loc("common.cancel")) {
                    newTag = ""
                    showingAddTag = false
                }
                Button(loc("tag.save"), action: addTag)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primary)
            }
        }
        .padding(16)
        .frame(width: 240)
        .background(Theme.surface)
    }

    private func addTag() {
        let candidate = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.addCustomTag(candidate)
        if settings.customTags.contains(candidate) { selection = candidate }
        newTag = ""
        showingAddTag = false
    }

    private func displayName(for tag: String) -> String {
        FocusTag(rawValue: tag).map { loc($0.labelKey) } ?? tag
    }
}
