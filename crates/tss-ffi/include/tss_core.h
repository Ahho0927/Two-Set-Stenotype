#ifndef TSS_CORE_H
#define TSS_CORE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TssEngine TssEngine;

typedef struct {
    uint8_t *ptr;
    size_t len;
} TssBuffer;

typedef struct {
    uint16_t key_code;
    uint8_t state;
    uint8_t is_repeat;
} TssKeyEvent;

typedef struct {
    uint8_t disposition;
    uint8_t completion;
    uint8_t needs_context;
    uint8_t reserved;
    uint64_t pending_id;
    TssBuffer detail;
} TssKeyDecision;

typedef struct {
    const uint8_t *text_ptr;
    size_t text_len;
    uint8_t confidence;
    uint8_t selection;
    uint8_t was_truncated;
    uint8_t reserved;
} TssTextContext;

typedef struct {
    uint8_t status;
    uint8_t delete_selection;
    uint8_t output_kind;
    uint8_t basic_key;
    uint32_t delete_before;
    TssBuffer text;
    TssBuffer stroke;
} TssResolveResult;

typedef struct {
    uint8_t ok;
    uint8_t reserved[3];
    uint32_t count;
    TssBuffer detail;
} TssOperationResult;

TssEngine *tss_engine_new(void);
void tss_engine_free(TssEngine *engine);
void tss_buffer_free(TssBuffer buffer);

TssKeyDecision tss_engine_process_key(TssEngine *engine, TssKeyEvent event);
TssResolveResult tss_engine_resolve(
    TssEngine *engine,
    uint64_t pending_id,
    const TssTextContext *context
);
TssOperationResult tss_engine_replace_dictionaries(
    TssEngine *engine,
    const uint8_t *json_ptr,
    size_t json_len
);
TssOperationResult tss_engine_set_captured_keys(
    TssEngine *engine,
    const uint16_t *keys_ptr,
    size_t keys_len
);
void tss_engine_reset_input(TssEngine *engine);
uint8_t tss_engine_interrupt(TssEngine *engine);

#ifdef __cplusplus
}
#endif

#endif
