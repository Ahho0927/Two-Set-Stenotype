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
        case .general: "slider.horizontal.3"
        case .dictionaries: "books.vertical"
        case .captureKeys: "keyboard"
        case .recentStrokes: "clock.arrow.circlepath"
        }
    }
}

@MainActor
private final class SettingsNavigationState: ObservableObject {
    @Published var selection: SettingsSection? = .general
}

@MainActor
private final class DictionarySelectionState: ObservableObject {
    @Published var selectedID: UUID?
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @StateObject private var navigation = SettingsNavigationState()

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(model: model, selection: $navigation.selection)
                .navigationSplitViewColumnWidth(min: 190, ideal: 208, max: 236)
        } detail: {
            detail(for: navigation.selection ?? .general)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 860, minHeight: 520)
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

private struct SettingsSidebar: View {
    @ObservedObject var model: AppModel
    @Binding var selection: SettingsSection?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 42, height: 42)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("TSS")
                        .font(.system(size: 17, weight: .semibold))
                    Text(L10n.string("app.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            List(SettingsSection.allCases, selection: $selection) { section in
                HStack(spacing: 10) {
                    Image(systemName: section.systemImage)
                        .frame(width: 18)
                        .foregroundStyle(selection == section ? Color.indigo : Color.secondary)
                    Text(section.title)
                        .foregroundStyle(.primary)
                }
                    .tag(section)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .listRowInsets(.init(top: 3, leading: 10, bottom: 3, trailing: 10))
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider()
            HStack(spacing: 8) {
                Circle()
                    .fill(model.isEnabled ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.string(model.isEnabled ? "steno.on" : "steno.off"))
                        .font(.caption.weight(.medium))
                    ShortcutKeycaps(labels: model.toggleShortcut.keycapLabels, compact: true)
                }
                Spacer()
            }
            .padding(14)
            .accessibilityElement(children: .combine)
        }
        .background(.ultraThinMaterial)
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPageHeader(section: .general)
                StenoModePanel(model: model)

                HStack(alignment: .top, spacing: 16) {
                    accessibilityPanel
                    displayPanel
                }
                .frame(minHeight: 136)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var accessibilityPanel: some View {
        SettingsPanel(title: L10n.string("general.accessibility"), systemImage: "hand.raised") {
            HStack(spacing: 12) {
                Image(systemName: model.accessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(model.accessibilityTrusted ? .green : .orange)
                    .accessibilityLabel(
                        L10n.string(model.accessibilityTrusted ? "accessibility.granted" : "accessibility.required")
                    )

                Button {
                    model.refreshAccessibilityStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help(L10n.string("accessibility.refresh"))
                .accessibilityLabel(L10n.string("accessibility.refresh"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var displayPanel: some View {
        SettingsPanel(title: L10n.string("general.app_display"), systemImage: "macwindow") {
            Toggle(
                L10n.string("general.show_dock"),
                isOn: Binding(
                    get: { model.showsDockIcon },
                    set: { model.setShowsDockIcon($0) }
                )
            )
            .disabled(model.showsDockIcon && !model.showsMenuBarIcon)

            Toggle(
                L10n.string("general.show_menu_bar"),
                isOn: Binding(
                    get: { model.showsMenuBarIcon },
                    set: { model.setShowsMenuBarIcon($0) }
                )
            )
            .disabled(model.showsMenuBarIcon && !model.showsDockIcon)
        }
    }
}

private struct StenoModePanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.indigo.opacity(0.14))
                Image(systemName: model.isEnabled ? "keyboard.fill" : "keyboard")
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(.indigo)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 13) {
                Text(L10n.string("steno.mode"))
                    .font(.title2.weight(.semibold))
                ToggleShortcutRecorder(model: model)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 12)

            Toggle(
                L10n.string(model.isEnabled ? "steno.toggle_on" : "steno.toggle_off"),
                isOn: Binding(
                    get: { model.isEnabled },
                    set: { model.setEnabled($0) }
                )
            )
            .toggleStyle(.switch)
            .font(.headline)
            .accessibilityLabel(L10n.string("steno.mode"))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.12), Color.indigo.opacity(0.045)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.indigo.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct DictionarySettingsView: View {
    @ObservedObject var model: AppModel
    @StateObject private var selection = DictionarySelectionState()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsPageHeader(section: .dictionaries)
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 18)

            Group {
                if model.dictionaries.isEmpty {
                    ContentUnavailableView(
                        L10n.string("dictionary.empty.title"),
                        systemImage: "books.vertical",
                        description: Text(L10n.string("dictionary.empty.description"))
                    )
                } else {
                    List(model.dictionaries, selection: $selection.selectedID) { dictionary in
                        HStack(spacing: 12) {
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

                            VStack(alignment: .leading, spacing: 3) {
                                Text(dictionary.name)
                                    .fontWeight(.medium)
                                if let error = dictionary.error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                    .lineLimit(2)
                                }
                            }
                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 5)
                        .tag(dictionary.id)
                        .contentShape(Rectangle())
                    }
                    .listStyle(.inset)
                    .environment(\.defaultMinListRowHeight, 44)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            HStack(spacing: 8) {
                IconActionButton(
                    title: L10n.string("dictionary.add"),
                    systemImage: "plus",
                    prominent: true,
                    action: model.addDictionary
                )
                IconActionButton(
                    title: L10n.string("dictionary.remove"),
                    systemImage: "trash",
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
            .padding(14)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct CaptureKeysView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 20) {
                    SettingsPageHeader(section: .captureKeys)
                    Spacer()
                    KeyboardStateLegend()
                }
                CaptureKeyboardView(model: model)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
        .padding(18)
        .background(Color(nsColor: .underPageBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }

    private func keyboardRow(_ row: [KeyboardKeyDescriptor]) -> some View {
        HStack(spacing: keySpacing) {
            ForEach(row) { key in
                FullKeyboardKey(
                    descriptor: key,
                    isOn: key.option.map(binding(for:))
                )
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
        [.reserved("esc", "esc", width: 50)]
            + (1...12).map { .reserved("f\($0)", "F\($0)") }
    }

    private var numberRow: [KeyboardKeyDescriptor] {
        [.available("grave", option: .grave)]
            + CaptureKeyOption.numberRow.map { .available("number-\($0.token)", option: $0) }
            + [.reserved("delete", "⌫", width: 70)]
    }

    private var topRow: [KeyboardKeyDescriptor] {
        [.reserved("tab", "tab", width: 60)]
            + CaptureKeyOption.topRow.map { .available("top-\($0.token)", option: $0) }
            + [.available("backslash", option: .backslash)]
    }

    private var homeRow: [KeyboardKeyDescriptor] {
        [.reserved("caps", "caps", width: 72)]
            + CaptureKeyOption.homeRow.map { .available("home-\($0.token)", option: $0) }
            + [.reserved("return", "return", width: 82)]
    }

    private var bottomRow: [KeyboardKeyDescriptor] {
        let shift = CaptureKeyOption.bottomRow[0]
        return [.available("left-shift", option: shift, width: 92, label: "⇧")]
            + CaptureKeyOption.bottomRow.dropFirst().map {
                .available("bottom-\($0.token)", option: $0)
            }
            + [.available("right-shift", option: shift, width: 92, label: "⇧")]
    }

    private var modifierRow: [KeyboardKeyDescriptor] {
        [
            .reserved("fn", "fn", width: 45),
            .reserved("control", "⌃", width: 45),
            .reserved("option-left", "⌥", width: 48),
            .reserved("command-left", "⌘", width: 55),
            .available("space", option: .spaceBar, width: 250, label: L10n.string("keys.space")),
            .reserved("command-right", "⌘", width: 55),
            .reserved("option-right", "⌥", width: 48),
            .reserved("left", "←"),
            .reserved("down", "↓"),
            .reserved("up", "↑"),
            .reserved("right", "→"),
        ]
    }
}

private struct KeyboardStateLegend: View {
    var body: some View {
        HStack(spacing: 13) {
            legendItem(
                L10n.string("keys.legend.captured"),
                fill: Color.indigo.opacity(0.78),
                border: Color.indigo
            )
            legendItem(
                L10n.string("keys.legend.passthrough"),
                fill: Color(nsColor: .controlBackgroundColor),
                border: Color.secondary.opacity(0.32)
            )
            legendItem(
                L10n.string("keys.legend.unavailable"),
                fill: Color(nsColor: .controlBackgroundColor).opacity(0.38),
                border: Color.secondary.opacity(0.16)
            )
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem(_ title: String, fill: Color, border: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(fill)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(border, lineWidth: 1)
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
                    isOn.wrappedValue ? Color.indigo.opacity(0.78) : Color(nsColor: .controlBackgroundColor),
                    in: keyShape
                )
                .overlay { keyBorder(selected: isOn.wrappedValue) }
                .shadow(color: .black.opacity(isOn.wrappedValue ? 0.16 : 0.08), radius: 2, y: 1)
                .accessibilityLabel(descriptor.label)
                .accessibilityValue(
                    L10n.string(isOn.wrappedValue ? "keys.capture_on" : "keys.capture_off")
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    Text(descriptor.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.56))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 6, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .padding(4)
                        .accessibilityHidden(true)
                }
                    .frame(width: descriptor.width, height: 39)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.38), in: keyShape)
                    .overlay { keyBorder(selected: false).opacity(0.45) }
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
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.9)
            }
        }
        .foregroundStyle(selected ? Color.white : Color.primary)
        .frame(width: descriptor.width, height: 39)
        .contentShape(Rectangle())
    }

    private func keyBorder(selected: Bool) -> some View {
        keyShape.stroke(
            selected ? Color.indigo : Color.secondary.opacity(0.28),
            lineWidth: 1
        )
    }
}

private struct RecentStrokesView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                SettingsPageHeader(section: .recentStrokes)
                Spacer()
                Button {
                    openWindow(id: SceneIdentifier.paperTape)
                } label: {
                    Label(L10n.string("paper_tape"), systemImage: "macwindow.badge.plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 18)

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

            if !model.recentStrokes.isEmpty {
                Divider()
                HStack {
                    Spacer()
                    IconActionButton(
                        title: L10n.string("history.clear"),
                        systemImage: "trash",
                        role: .destructive,
                        action: model.clearRecentStrokes
                    )
                }
                .padding(14)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
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

private struct SettingsPageHeader: View {
    let section: SettingsSection

    var body: some View {
        Text(section.title)
            .font(.system(size: 27, weight: .bold))
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
            Divider()
            VStack(alignment: .leading, spacing: 11) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.13), lineWidth: 1)
        }
    }
}

private struct IconActionButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole?
    var prominent = false
    let action: () -> Void

    @ViewBuilder
    var body: some View {
        if prominent {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private var button: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
        }
        .help(title)
        .accessibilityLabel(title)
    }
}
