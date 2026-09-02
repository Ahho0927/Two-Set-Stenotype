import AppKit
import Combine
import SwiftUI

struct ToggleShortcutRecorder: View {
    @ObservedObject var model: AppModel
    @StateObject private var state = ToggleShortcutRecorderState()

    var body: some View {
        HStack(spacing: 10) {
            Text(L10n.string("general.shortcut"))
                .font(.callout)
                .foregroundStyle(.secondary)

            if state.isRecording {
                Text(L10n.string("shortcut.recording"))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.indigo)
            } else {
                ShortcutKeycaps(labels: model.toggleShortcut.keycapLabels)
            }

            Button {
                state.isRecording ? stopRecording() : startRecording()
            } label: {
                Image(systemName: state.isRecording ? "xmark" : "pencil")
            }
            .buttonStyle(.borderless)
            .help(L10n.string("shortcut.edit"))
            .accessibilityLabel(L10n.string("shortcut.edit"))

            Button {
                stopRecording()
                model.setToggleShortcut(.default)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help(L10n.string("shortcut.reset"))
            .accessibilityLabel(L10n.string("shortcut.reset"))
            .disabled(model.toggleShortcut == .default && !state.isRecording)
        }
        .fixedSize(horizontal: true, vertical: false)
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        stopRecording()
        state.isRecording = true
        state.message = nil
        model.setShortcutRecording(true)
        state.eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }
            guard let key = KeyCodeMapper.hidKey(for: event.keyCode), !key.isModifier else {
                return nil
            }
            let modifiers = shortcutModifiers(from: event.modifierFlags)
            guard !modifiers.isEmpty else {
                state.message = L10n.string("shortcut.modifier_required")
                return nil
            }
            model.setToggleShortcut(ToggleShortcut(key: key, modifiers: modifiers))
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let eventMonitor = state.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            state.eventMonitor = nil
        }
        if state.isRecording {
            state.isRecording = false
            model.setShortcutRecording(false)
        }
    }

    private func shortcutModifiers(from flags: NSEvent.ModifierFlags) -> ShortcutModifiers {
        var modifiers: ShortcutModifiers = []
        if flags.contains(.function) { modifiers.insert(.function) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        return modifiers
    }
}

struct ShortcutKeycaps: View {
    let labels: [String]
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: compact ? 9 : 12, weight: .semibold, design: .rounded))
                    .frame(minWidth: compact ? 17 : 22, minHeight: compact ? 17 : 22)
                    .padding(.horizontal, compact ? 2 : 3)
                    .background(
                        Color(nsColor: .controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(labels.joined(separator: " + "))
    }
}

@MainActor
private final class ToggleShortcutRecorderState: ObservableObject {
    @Published var isRecording = false
    @Published var message: String?
    var eventMonitor: Any?
}
