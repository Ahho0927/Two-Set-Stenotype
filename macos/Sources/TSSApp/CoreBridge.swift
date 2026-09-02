import CTSSCore
import Foundation

struct BridgeError: LocalizedError, Sendable {
    let message: String
    var errorDescription: String? { message }
}

final class CoreBridge: @unchecked Sendable {
    private let handle: OpaquePointer

    init() {
        guard let engine = tss_engine_new() else {
            fatalError("Unable to create TSS core engine")
        }
        handle = engine
    }

    deinit {
        tss_engine_free(handle)
    }

    func process(key: HIDKey, isDown: Bool, isRepeat: Bool) -> EngineKeyDecision {
        let raw = tss_engine_process_key(
            handle,
            TssKeyEvent(
                key_code: key.rawValue,
                state: isDown ? 0 : 1,
                is_repeat: isRepeat ? 1 : 0
            )
        )
        let detail = consume(raw.detail)
        let completion: EngineCompletion
        switch raw.completion {
        case 0:
            completion = .none
        case 1:
            completion = .completed(CompletedStrokeInfo(
                id: raw.pending_id,
                stroke: detail,
                needsContext: raw.needs_context != 0
            ))
        case 2:
            completion = .cancelled(detail)
        default:
            completion = .invalid(detail)
        }
        return EngineKeyDecision(suppress: raw.disposition != 0, completion: completion)
    }

    func resolve(_ stroke: CompletedStrokeInfo, context: CursorContext?) -> StrokeResolution {
        let raw: TssResolveResult
        if let context {
            let contextBytes = Array(context.precedingText.utf8)
            raw = contextBytes.withUnsafeBufferPointer { bytes in
                var ffiContext = TssTextContext(
                    text_ptr: bytes.baseAddress,
                    text_len: bytes.count,
                    confidence: context.confidence.rawValue,
                    selection: context.selection.rawValue,
                    was_truncated: context.wasTruncated ? 1 : 0,
                    reserved: 0
                )
                return tss_engine_resolve(handle, stroke.id, &ffiContext)
            }
        } else {
            raw = tss_engine_resolve(handle, stroke.id, nil)
        }

        let outputText = consume(raw.text)
        let resolvedStroke = consume(raw.stroke)
        let status = ResolutionStatus(rawValue: raw.status) ?? .expired
        let plan: EngineEditPlan?
        switch raw.output_kind {
        case 1:
            plan = EngineEditPlan(
                deleteSelection: raw.delete_selection != 0,
                deleteBefore: Int(raw.delete_before),
                output: .text(outputText)
            )
        case 2:
            if let key = BasicKeyAction(rawValue: raw.basic_key) {
                plan = EngineEditPlan(
                    deleteSelection: raw.delete_selection != 0,
                    deleteBefore: Int(raw.delete_before),
                    output: .key(key)
                )
            } else {
                plan = nil
            }
        default:
            plan = nil
        }
        return StrokeResolution(
            status: status,
            stroke: resolvedStroke.isEmpty ? stroke.stroke : resolvedStroke,
            plan: plan
        )
    }

    func replaceDictionaries(_ dictionaries: [(id: UUID, name: String, json: String)]) throws -> Int {
        let payload = dictionaries.map {
            ["id": $0.id.uuidString, "name": $0.name, "json": $0.json]
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let raw = data.withUnsafeBytes { bytes in
            tss_engine_replace_dictionaries(
                handle,
                bytes.bindMemory(to: UInt8.self).baseAddress,
                bytes.count
            )
        }
        let detail = consume(raw.detail)
        guard raw.ok != 0 else {
            throw BridgeError(
                message: detail.isEmpty ? L10n.string("dictionary.load_failed") : detail
            )
        }
        return Int(raw.count)
    }

    func setCapturedKeys(_ keys: Set<HIDKey>) throws {
        let values = keys.map(\.rawValue)
        let raw = values.withUnsafeBufferPointer { buffer in
            tss_engine_set_captured_keys(
                handle,
                buffer.baseAddress,
                buffer.count
            )
        }
        let detail = consume(raw.detail)
        guard raw.ok != 0 else {
            throw BridgeError(
                message: detail.isEmpty ? L10n.string("capture.apply_failed") : detail
            )
        }
    }

    func resetInput() {
        tss_engine_reset_input(handle)
    }

    @discardableResult
    func interrupt() -> Bool {
        tss_engine_interrupt(handle) != 0
    }

    private func consume(_ buffer: TssBuffer) -> String {
        guard let pointer = buffer.ptr, buffer.len > 0 else {
            tss_buffer_free(buffer)
            return ""
        }
        let data = Data(bytes: pointer, count: buffer.len)
        tss_buffer_free(buffer)
        return String(decoding: data, as: UTF8.self)
    }
}
