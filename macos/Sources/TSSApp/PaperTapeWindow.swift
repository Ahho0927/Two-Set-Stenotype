import SwiftUI

struct PaperTapeWindow: View {
    @ObservedObject var model: AppModel

    private static let keyOrder = Array("1234567890-=QAZWSXEDCRFVTGYHBUJNIKMOLP;'/.,[]")
    private static let cellWidth: CGFloat = 15
    private static let rowWidth = CGFloat(keyOrder.count) * cellWidth

    var body: some View {
        tape
            .padding(18)
            .frame(minWidth: 560, minHeight: 320)
            .background(Color(nsColor: .windowBackgroundColor))
    }

    private var tape: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    PaperTapeKeyHeader(keyOrder: Self.keyOrder, cellWidth: Self.cellWidth)
                    Rectangle()
                        .fill(Color.white.opacity(0.28))
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
            }
            .background(Color(nsColor: .black))
            .overlay {
                Rectangle()
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
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
            .foregroundStyle(.white.opacity(0.48))
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
                    .foregroundStyle(.white.opacity(0.48))
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
                    .foregroundStyle(.white)
                    .frame(width: cellWidth, height: 28)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("paper_tape.accessibility", record.stroke))
    }
}
