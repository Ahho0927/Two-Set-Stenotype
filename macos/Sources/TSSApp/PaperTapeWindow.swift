import AppKit
import SwiftUI

@MainActor
final class PaperTapeWindowController {
    static let shared = PaperTapeWindowController()

    private var windowController: NSWindowController?

    private init() {}

    func show(model: AppModel) {
        if let window = windowController?.window {
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(rootView: PaperTapeWindow(model: model))
        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.string("paper_tape")
        window.identifier = NSUserInterfaceItemIdentifier("paper-tape")
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: PaperTapeWindow.contentWidth, height: 460))
        window.contentMinSize = NSSize(width: PaperTapeWindow.contentWidth, height: 320)
        window.contentMaxSize = NSSize(width: PaperTapeWindow.contentWidth, height: 1_200)
        window.backgroundColor = .white
        window.isReleasedWhenClosed = false
        window.center()

        let controller = NSWindowController(window: window)
        windowController = controller
        NSApplication.shared.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}

struct PaperTapeWindow: View {
    @ObservedObject var model: AppModel

    private static let keyOrder = Array("1234567890-=QAZWSXEDCRFVTGYHBUJNIKMOLP;'/.,[]")
    private static let cellWidth: CGFloat = 15
    private static let horizontalPadding: CGFloat = 18
    private static let rowWidth = CGFloat(keyOrder.count) * cellWidth
    static let contentWidth = rowWidth + horizontalPadding * 2

    var body: some View {
        tape
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, 18)
            .frame(width: Self.contentWidth)
            .frame(minHeight: 320)
            .background(Color.white)
    }

    private var tape: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                PaperTapeKeyHeader(keyOrder: Self.keyOrder, cellWidth: Self.cellWidth)
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 1)

                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        if model.recentStrokes.isEmpty {
                            PaperTapeEmptyView(
                                width: Self.rowWidth,
                                height: max(220, geometry.size.height - 30)
                            )
                        } else {
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(Array(model.recentStrokes.reversed())) { record in
                                    PaperTapeStrokeRow(
                                        record: record,
                                        keyOrder: Self.keyOrder,
                                        cellWidth: Self.cellWidth
                                    )
                                    .id(record.id)
                                }
                            }
                            .padding(.vertical, 8)
                            .frame(width: Self.rowWidth, alignment: .leading)
                        }
                    }
                    .onAppear { scrollToLatest(using: proxy, animated: false) }
                    .onChange(of: model.recentStrokes.first?.id) { _, _ in
                        scrollToLatest(using: proxy, animated: true)
                    }
                }
            }
            .frame(width: Self.rowWidth, height: geometry.size.height)
            .background(Color.white)
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.28), lineWidth: 1)
            }
        }
    }

    private func scrollToLatest(using proxy: ScrollViewProxy, animated: Bool) {
        guard let latest = model.recentStrokes.first else { return }
        let action = { proxy.scrollTo(latest.id, anchor: .bottom) }
        if animated {
            withAnimation(.easeOut(duration: 0.16), action)
        } else {
            action()
        }
    }
}

private struct PaperTapeEmptyView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text(L10n.string("paper_tape.empty"))
            .font(.callout)
            .foregroundStyle(.black)
            .frame(width: width, height: height)
    }
}

private struct PaperTapeKeyHeader: View {
    let keyOrder: [Character]
    let cellWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(keyOrder.enumerated()), id: \.offset) { _, key in
                Text(String(key))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black)
                    .frame(width: cellWidth, height: 28)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PaperTapeStrokeRow: View {
    let record: StrokeRecord
    let keyOrder: [Character]
    let cellWidth: CGFloat

    private var pressed: Set<Character> {
        Set(record.stroke)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(keyOrder.enumerated()), id: \.offset) { _, key in
                Text(pressed.contains(key) ? String(key) : " ")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .frame(width: cellWidth, height: 28)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("paper_tape.accessibility", record.stroke))
    }
}
