import AppKit
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case dictionaries
    case captureKeys
    case recentStrokes

    var id: Self { self }

    var title: String {
        switch self {
        case .general: L10n.string("settings.general")
        case .dictionaries: L10n.string("settings.dictionary")
        case .captureKeys: L10n.string("settings.manage_key")
        case .recentStrokes: L10n.string("settings.history")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .dictionaries: "books.vertical"
        case .captureKeys: "keyboard"
        case .recentStrokes: "clock.arrow.circlepath"
        }
    }

    var toolbarIdentifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("app.tss.settings.\(rawValue)")
    }

    var preferredContentSize: NSSize {
        switch self {
        case .general: NSSize(width: 560, height: 390)
        case .dictionaries: NSSize(width: 640, height: 430)
        case .captureKeys: NSSize(width: 700, height: 410)
        case .recentStrokes: NSSize(width: 680, height: 420)
        }
    }

    init?(toolbarIdentifier: NSToolbarItem.Identifier) {
        guard let section = Self.allCases.first(where: { $0.toolbarIdentifier == toolbarIdentifier }) else {
            return nil
        }
        self = section
    }
}

@MainActor
final class SettingsNavigationState: ObservableObject {
    @Published var selection: SettingsSection = .general
}

@MainActor
private final class DictionarySelectionState: ObservableObject {
    @Published var selectedID: UUID?
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var navigation: SettingsNavigationState

    var body: some View {
        detail(for: navigation.selection)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .tint(.indigo)
    }

    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(model: model)
        case .dictionaries:
            DictionarySettingsView(model: model)
        case .captureKeys:
            CaptureKeysView(model: model)
        case .recentStrokes:
            RecentStrokesView(model: model)
        }
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(L10n.string("steno.mode"))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 16)
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { model.isEnabled },
                            set: { model.setEnabled($0) }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel(L10n.string("steno.mode"))
                }

                Divider()

                PreferenceRow(title: L10n.string("general.shortcut")) {
                    ToggleShortcutRecorder(model: model, showsLabel: false)
                }
            }

            HStack(spacing: 12) {
                Text(L10n.string("general.accessibility"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 16)
                Image(systemName: model.accessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.accessibilityTrusted ? .green : .orange)
                    .accessibilityLabel(
                        L10n.string(model.accessibilityTrusted ? "accessibility.granted" : "accessibility.required")
                    )

                Button {
                    model.refreshAccessibilityStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(L10n.string("accessibility.refresh"))
                .accessibilityLabel(L10n.string("accessibility.refresh"))
            }

            PreferenceGroup(title: L10n.string("general.app_display")) {
                Toggle(
                    L10n.string("general.show_dock"),
                    isOn: Binding(
                        get: { model.showsDockIcon },
                        set: { model.setShowsDockIcon($0) }
                    )
                )
                .disabled(model.showsDockIcon && !model.showsMenuBarIcon)
                .frame(minHeight: 25, alignment: .leading)

                Toggle(
                    L10n.string("general.show_menu_bar"),
                    isOn: Binding(
                        get: { model.showsMenuBarIcon },
                        set: { model.setShowsMenuBarIcon($0) }
                    )
                )
                .disabled(model.showsMenuBarIcon && !model.showsDockIcon)
                .frame(minHeight: 25, alignment: .leading)
            }
        }
        .frame(maxWidth: 480, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct PreferenceGroup<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.leading, 2)
        }
    }
}

private struct PreferenceRow<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 16)
            HStack(spacing: 9) {
                content
            }
        }
        .frame(minHeight: 30)
    }
}

private struct DictionarySettingsView: View {
    @ObservedObject var model: AppModel
    @StateObject private var selection = DictionarySelectionState()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if model.dictionaries.isEmpty {
                    ContentUnavailableView(
                        L10n.string("dictionary.empty.title"),
                        systemImage: "books.vertical",
                        description: Text(L10n.string("dictionary.empty.description"))
                    )
                } else {
                    List(model.dictionaries, selection: $selection.selectedID) { dictionary in
                        HStack(spacing: 10) {
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { dictionary.enabled },
                                    set: { model.setDictionaryEnabled(id: dictionary.id, enabled: $0) }
                                )
                            )
                            .labelsHidden()
                            .accessibilityLabel(
                                L10n.format("dictionary.use_accessibility", dictionary.name)
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(dictionary.name)
                                if let error = dictionary.error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .lineLimit(2)
                                }
                            }
                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 3)
                        .tag(dictionary.id)
                        .contentShape(Rectangle())
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 38)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 20)

            HStack(spacing: 5) {
                IconActionButton(
                    title: L10n.string("dictionary.add"),
                    systemImage: "plus",
                    action: model.addDictionary
                )
                IconActionButton(
                    title: L10n.string("dictionary.remove"),
                    systemImage: "minus",
                    role: .destructive
                ) {
                    if let selectedID = selection.selectedID {
                        model.removeDictionary(id: selectedID)
                        selection.selectedID = nil
                    }
                }
                .disabled(selection.selectedID == nil)
                IconActionButton(
                    title: L10n.string("dictionary.reload"),
                    systemImage: "arrow.clockwise",
                    action: model.reloadDictionaries
                )

                Spacer()
                Text(model.dictionaryStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

private struct CaptureKeysView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            KeyboardStateLegend()
                .frame(maxWidth: .infinity, alignment: .trailing)

            CaptureKeyboardView(model: model)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct KeyboardKeyDescriptor: Identifiable {
    let id: String
    let label: String
    let width: CGFloat
    let option: CaptureKeyOption?

    static func available(
        _ id: String,
        option: CaptureKeyOption,
        width: CGFloat = 37,
        label: String? = nil
    ) -> Self {
        Self(id: id, label: label ?? option.label, width: width, option: option)
    }

    static func reserved(_ id: String, _ label: String, width: CGFloat = 37) -> Self {
        Self(id: id, label: label, width: width, option: nil)
    }
}

private struct CaptureKeyboardView: View {
    @ObservedObject var model: AppModel
    private let keySpacing: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            keyboardRow(functionRow)
            keyboardRow(numberRow)
            keyboardRow(topRow)
            keyboardRow(homeRow)
            keyboardRow(bottomRow)
            keyboardRow(modifierRow)
        }
        .padding(14)
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.66), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }

    private func keyboardRow(_ row: [KeyboardKeyDescriptor]) -> some View {
        HStack(spacing: keySpacing) {
            ForEach(row) { key in
                FullKeyboardKey(descriptor: key, isOn: key.option.map(binding(for:)))
            }
        }
    }

    private func binding(for option: CaptureKeyOption) -> Binding<Bool> {
        Binding(
            get: { model.isCaptureTokenEnabled(option.token) },
            set: { model.setCaptureToken(option.token, enabled: $0) }
        )
    }

    private var functionRow: [KeyboardKeyDescriptor] {
        [.reserved("esc", "esc", width: 51)]
            + (1...12).map { .reserved("f\($0)", "F\($0)", width: 42.5) }
    }

    private var numberRow: [KeyboardKeyDescriptor] {
        [.available("grave", option: .grave)]
            + CaptureKeyOption.numberRow.map { .available("number-\($0.token)", option: $0) }
            + [.reserved("delete", "⌫", width: 75)]
    }

    private var topRow: [KeyboardKeyDescriptor] {
        [.reserved("tab", "tab", width: 70)]
            + CaptureKeyOption.topRow.map { .available("top-\($0.token)", option: $0) }
            + [.available("backslash", option: .backslash, width: 42)]
    }

    private var homeRow: [KeyboardKeyDescriptor] {
        [.reserved("caps", "caps", width: 72)]
            + CaptureKeyOption.homeRow.map { .available("home-\($0.token)", option: $0) }
            + [.reserved("return", "return", width: 82)]
    }

    private var bottomRow: [KeyboardKeyDescriptor] {
        let shift = CaptureKeyOption.bottomRow[0]
        return [.available("left-shift", option: shift, width: 98, label: "⇧")]
            + CaptureKeyOption.bottomRow.dropFirst().map {
                .available("bottom-\($0.token)", option: $0)
            }
            + [.available("right-shift", option: shift, width: 98, label: "⇧")]
    }

    private var modifierRow: [KeyboardKeyDescriptor] {
        [
            .reserved("fn", "fn", width: 45),
            .reserved("control", "⌃", width: 45),
            .reserved("option-left", "⌥", width: 48),
            .reserved("command-left", "⌘", width: 55),
            .available("space", option: .spaceBar, width: 295, label: L10n.string("keys.space")),
            .reserved("command-right", "⌘", width: 55),
            .reserved("option-right", "⌥", width: 48),
        ]
    }
}

private struct KeyboardStateLegend: View {
    var body: some View {
        HStack(spacing: 13) {
            legendItem(
                L10n.string("keys.legend.captured"),
                fill: Color.indigo.opacity(0.12),
                border: Color.indigo.opacity(0.76)
            )
            legendItem(
                L10n.string("keys.legend.passthrough"),
                fill: Color(nsColor: .controlBackgroundColor),
                border: Color.secondary.opacity(0.3)
            )
            legendItem(
                L10n.string("keys.legend.unavailable"),
                fill: Color(nsColor: .controlBackgroundColor).opacity(0.36),
                border: Color.secondary.opacity(0.14),
                locked: true
            )
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem(
        _ title: String,
        fill: Color,
        border: Color,
        locked: Bool = false
    ) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(fill)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(border, lineWidth: 1)
                }
                .overlay {
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 15, height: 12)
            Text(title)
        }
    }
}

private struct FullKeyboardKey: View {
    let descriptor: KeyboardKeyDescriptor
    let isOn: Binding<Bool>?

    var body: some View {
        Group {
            if let isOn, let option = descriptor.option {
                Toggle(isOn: isOn) {
                    keyLabel(option: option, selected: isOn.wrappedValue)
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
                .background(
                    isOn.wrappedValue ? Color.indigo.opacity(0.11) : Color(nsColor: .controlBackgroundColor),
                    in: keyShape
                )
                .overlay { keyBorder(selected: isOn.wrappedValue) }
                .shadow(color: .black.opacity(0.07), radius: 1.5, y: 1)
                .accessibilityLabel(descriptor.label)
                .accessibilityValue(
                    L10n.string(isOn.wrappedValue ? "keys.capture_on" : "keys.capture_off")
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    Text(descriptor.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 6, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.38))
                        .padding(4)
                        .accessibilityHidden(true)
                }
                .frame(width: descriptor.width, height: 39)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.35), in: keyShape)
                .overlay { keyBorder(selected: false).opacity(0.42) }
                .help(L10n.string("keys.unavailable"))
                .accessibilityLabel("\(descriptor.label), \(L10n.string("keys.unavailable"))")
            }
        }
    }

    private var keyShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
    }

    @ViewBuilder
    private func keyLabel(option: CaptureKeyOption, selected: Bool) -> some View {
        VStack(spacing: 1) {
            Text(descriptor.label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            if option.token != descriptor.label {
                Text(option.token)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(selected ? Color.indigo.opacity(0.82) : Color.secondary)
            }
        }
        .foregroundStyle(selected ? Color.indigo : Color.primary)
        .frame(width: descriptor.width, height: 39)
        .contentShape(Rectangle())
    }

    private func keyBorder(selected: Bool) -> some View {
        keyShape.stroke(
            selected ? Color.indigo.opacity(0.78) : Color.secondary.opacity(0.28),
            lineWidth: selected ? 1.5 : 1
        )
    }
}

private struct RecentStrokesView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if model.recentStrokes.isEmpty {
                    ContentUnavailableView(
                        L10n.string("history.empty.title"),
                        systemImage: "waveform.path",
                        description: Text(L10n.string("history.empty.description"))
                    )
                } else {
                    RecentStrokeResultsTable(records: model.recentStrokes)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            HStack(spacing: 8) {
                Button {
                    PaperTapeWindowController.shared.show(model: model)
                } label: {
                    Label(L10n.string("paper_tape"), systemImage: "macwindow.badge.plus")
                }
                .buttonStyle(.bordered)

                Spacer()

                if !model.recentStrokes.isEmpty {
                    IconActionButton(
                        title: L10n.string("history.clear"),
                        systemImage: "trash",
                        role: .destructive,
                        action: model.clearRecentStrokes
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
    }
}

private struct RecentStrokeResultsTable: View {
    let records: [StrokeRecord]

    var body: some View {
        Table(records) {
            TableColumn(L10n.string("history.column.status")) { record in
                Image(systemName: record.successful ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(record.successful ? .green : .orange)
                    .accessibilityLabel(
                        L10n.string(record.successful ? "history.success" : "history.failure")
                    )
            }
            .width(48)
            TableColumn(L10n.string("history.column.stroke")) { record in
                Text(record.stroke.isEmpty ? "—" : record.stroke)
                    .font(.body.monospaced())
            }
            .width(min: 100, ideal: 130, max: 180)
            TableColumn(L10n.string("history.column.result")) { record in
                Text(record.result)
                    .lineLimit(1)
            }
            TableColumn(L10n.string("history.column.time")) { record in
                Text(record.date, style: .time)
                    .foregroundStyle(.secondary)
            }
            .width(min: 86, ideal: 98, max: 120)
        }
        .tableStyle(.inset)
    }
}

private struct IconActionButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .frame(width: 14, height: 14)
        }
        .buttonStyle(.bordered)
        .help(title)
        .accessibilityLabel(title)
    }
}
