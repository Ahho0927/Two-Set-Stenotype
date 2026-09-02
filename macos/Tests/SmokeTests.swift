import CoreGraphics
import Foundation

@main
struct TSSSwiftSmokeTests {
    static func main() {
        check(KeyCodeMapper.hidKey(for: 18) == .digit1, "number key mapping")
        check(KeyCodeMapper.hidKey(for: 39) == .quote, "quote key mapping")
        check(KeyCodeMapper.hidKey(for: 44) == .slash, "slash key mapping")
        check(KeyCodeMapper.hidKey(for: 27) == .minus, "minus key mapping")
        check(KeyCodeMapper.hidKey(for: 24) == .equal, "equal key mapping")
        check(KeyCodeMapper.hidKey(for: 43) == .comma, "comma key mapping")
        check(KeyCodeMapper.hidKey(for: 47) == .period, "period key mapping")
        check(KeyCodeMapper.hidKey(for: 49) == .space, "space key mapping")
        check(KeyCodeMapper.hidKey(for: 56) == .leftShift, "left shift mapping")
        check(KeyCodeMapper.hidKey(for: 60) == .rightShift, "right shift mapping")
        var modifierTransitions = ModifierTransitionTracker()
        check(
            modifierTransitions.transition(key: .leftShift, groupIsActive: true),
            "left shift flagsChanged down"
        )
        check(
            modifierTransitions.transition(key: .rightShift, groupIsActive: true),
            "right shift flagsChanged down while left shift is held"
        )
        check(
            !modifierTransitions.transition(key: .leftShift, groupIsActive: true),
            "left shift flagsChanged up while right shift remains held"
        )
        check(
            !modifierTransitions.transition(key: .rightShift, groupIsActive: false),
            "right shift flagsChanged up"
        )
        check(CaptureKeyOption.defaultTokens.contains(","), "comma is captured by default")
        check(CaptureKeyOption.defaultTokens.contains("."), "period is captured by default")
        check(CaptureKeyOption.all.contains(.grave), "grave key is available for capture")
        check(CaptureKeyOption.all.contains(.backslash), "backslash key is available for capture")
        check(!CaptureKeyOption.defaultTokens.contains("`"), "grave key starts disabled")
        check(!CaptureKeyOption.defaultTokens.contains("\\"), "backslash key starts disabled")
        check(ToggleShortcut.default.key == .t, "default toggle shortcut key")
        check(
            ToggleShortcut.default.modifiers == .function,
            "default toggle shortcut modifier"
        )
        check(ToggleShortcut.default.displayName == "fn + T", "toggle shortcut display name")

        do {
            let mainDictionary = try String(
                contentsOf: URL(fileURLWithPath: "examples/main.json"),
                encoding: .utf8
            )
            let hangulDictionary = try String(
                contentsOf: URL(fileURLWithPath: "examples/main_hangul.json"),
                encoding: .utf8
            )
            let bundledCore = CoreBridge()
            let count = try bundledCore.replaceDictionaries([
                (id: UUID(), name: "main.json", json: mainDictionary),
                (id: UUID(), name: "main_hangul.json", json: hangulDictionary),
            ])
            check(count > 0, "bundled example dictionaries load together")
        } catch {
            fatalError("Smoke test failed: bundled example dictionaries: \(error)")
        }

        let core = CoreBridge()
        do {
            let count = try core.replaceDictionaries([(
                id: UUID(),
                name: "smoke.json",
                json: #"{"_":" "}"#
            )])
            check(count == 1, "FFI dictionary load")
        } catch {
            fatalError("Smoke test failed: FFI dictionary load: \(error)")
        }
        check(core.process(key: .space, isDown: true, isRepeat: false).suppress, "FFI key down")
        let spaceUp = core.process(key: .space, isDown: false, isRepeat: false)
        guard case let .completed(completedSpace) = spaceUp.completion else {
            fatalError("Smoke test failed: FFI stroke completion")
        }
        let spaceResolution = core.resolve(completedSpace, context: nil)
        check(spaceResolution.status == .matched, "FFI stroke resolution")
        check(spaceResolution.plan?.output == .text(" "), "FFI text output")

        var tracker = TextTracker()
        let context = CursorContext(
            precedingText: "사람   ",
            confidence: .authoritative,
            selection: .nonEmpty,
            wasTruncated: false
        )
        tracker.apply(
            EngineEditPlan(
                deleteSelection: true,
                deleteBefore: 3,
                output: .text("은")
            ),
            basedOn: context,
            processIdentifier: 42
        )
        check(
            tracker.context(for: 42)?.precedingText == "사람은",
            "selection replacement and whitespace deletion"
        )

        tracker.apply(
            EngineEditPlan(
                deleteSelection: false,
                deleteBefore: 0,
                output: .key(.tab)
            ),
            basedOn: nil,
            processIdentifier: 42
        )
        check(tracker.context(for: 42) == nil, "basic key invalidates tracker")

        var strokeTracker = TextTracker()
        strokeTracker.apply(
            EngineEditPlan(
                deleteSelection: false,
                deleteBefore: 0,
                output: .text("사람")
            ),
            basedOn: nil,
            processIdentifier: 7
        )
        check(
            strokeTracker.context(for: 7) == CursorContext(
                precedingText: "사람",
                confidence: .tracked,
                selection: .none,
                wasTruncated: true
            ),
            "stroke output bootstraps context without accessibility"
        )
        strokeTracker.apply(
            EngineEditPlan(
                deleteSelection: false,
                deleteBefore: 0,
                output: .text(" ")
            ),
            basedOn: nil,
            processIdentifier: 7
        )
        strokeTracker.applyPassedBackspace(processIdentifier: 7)
        strokeTracker.applyPassedTab(processIdentifier: 7)
        check(
            strokeTracker.context(for: 7)?.precedingText == "사람\t",
            "passed backspace and tab update tracked context"
        )

        let fallbackCore = CoreBridge()
        do {
            _ = try fallbackCore.replaceDictionaries([(
                id: UUID(),
                name: "fallback.json",
                json: #"{"T":{"condition":"previousHangulBatchim","batchim":{"text":"은","deleteBefore":true},"noBatchim":{"text":"는","deleteBefore":true}},"R":{"replaceBatchim":"ㅂ","text":"니다"}}"#
            )])
        } catch {
            fatalError("Smoke test failed: fallback dictionary load: \(error)")
        }

        _ = fallbackCore.process(key: .t, isDown: true, isRepeat: false)
        let noContextConditionalUp = fallbackCore.process(key: .t, isDown: false, isRepeat: false)
        guard case let .completed(noContextConditionalStroke) = noContextConditionalUp.completion else {
            fatalError("Smoke test failed: no-context conditional stroke completion")
        }
        let noContextConditional = fallbackCore.resolve(noContextConditionalStroke, context: nil)
        check(noContextConditional.status == .matched, "conditional fallback resolves without context")
        check(noContextConditional.plan?.output == .text("는"), "conditional fallback uses noBatchim")

        _ = fallbackCore.process(key: .r, isDown: true, isRepeat: false)
        let noContextReplacementUp = fallbackCore.process(key: .r, isDown: false, isRepeat: false)
        guard case let .completed(noContextReplacementStroke) = noContextReplacementUp.completion else {
            fatalError("Smoke test failed: no-context replacement stroke completion")
        }
        let noContextReplacement = fallbackCore.resolve(noContextReplacementStroke, context: nil)
        check(noContextReplacement.status == .matched, "batchim fallback resolves without context")
        check(noContextReplacement.plan?.output == .text("ㅂ니다"), "batchim fallback uses literal text")

        _ = fallbackCore.process(key: .t, isDown: true, isRepeat: false)
        let fallbackUp = fallbackCore.process(key: .t, isDown: false, isRepeat: false)
        guard case let .completed(fallbackStroke) = fallbackUp.completion,
              let trackedContext = strokeTracker.context(for: 7)
        else {
            fatalError("Smoke test failed: tracked context stroke completion")
        }
        let fallbackResolution = fallbackCore.resolve(fallbackStroke, context: trackedContext)
        check(fallbackResolution.status == .matched, "tracked context resolves conditional stroke")
        check(fallbackResolution.plan?.output == .text("은"), "tracked context detects batchim")

        _ = fallbackCore.process(key: .r, isDown: true, isRepeat: false)
        let replacementUp = fallbackCore.process(key: .r, isDown: false, isRepeat: false)
        guard case let .completed(replacementStroke) = replacementUp.completion else {
            fatalError("Smoke test failed: batchim replacement stroke completion")
        }
        let replacementContext = CursorContext(
            precedingText: "간",
            confidence: .tracked,
            selection: .none,
            wasTruncated: false
        )
        let replacementResolution = fallbackCore.resolve(
            replacementStroke,
            context: replacementContext
        )
        check(replacementResolution.status == .matched, "batchim replacement resolves")
        check(replacementResolution.plan?.deleteBefore == 1, "batchim replacement deletes syllable")
        check(replacementResolution.plan?.output == .text("갑니다"), "batchim replacement output")
        print("Swift smoke tests passed")
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else {
            fatalError("Smoke test failed: \(name)")
        }
    }
}
