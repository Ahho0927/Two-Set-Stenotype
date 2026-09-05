#ifndef CASTOR_CORE_H
#define CASTOR_CORE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CastorEngine CastorEngine;
typedef struct { uint8_t *ptr; size_t len; } CastorBuffer;
typedef struct { uint16_t key_code; uint8_t state; uint8_t is_repeat; } CastorKeyEvent;
typedef struct {
    uint8_t disposition;
    uint8_t completion;
    uint8_t needs_context;
    uint8_t reserved;
    uint64_t pending_id;
    CastorBuffer detail;
} CastorKeyDecision;
typedef struct {
    const uint8_t *text_ptr;
    size_t text_len;
    uint8_t confidence;
    uint8_t selection;
    uint8_t was_truncated;
    uint8_t reserved;
} CastorTextContext;
typedef struct {
    uint8_t status;
    uint8_t delete_selection;
    uint8_t output_kind;
    uint8_t basic_key;
    uint32_t delete_before;
    CastorBuffer text;
    CastorBuffer stroke;
} CastorResolveResult;
typedef struct {
    uint8_t ok;
    uint8_t reserved[3];
    uint32_t count;
    CastorBuffer detail;
} CastorOperationResult;

CastorEngine *castor_engine_new(void);
void castor_engine_free(CastorEngine *engine);
void castor_buffer_free(CastorBuffer buffer);
CastorKeyDecision castor_engine_process_key(CastorEngine *engine, CastorKeyEvent event);
CastorResolveResult castor_engine_resolve(CastorEngine *engine, uint64_t pending_id, const CastorTextContext *context);
CastorOperationResult castor_engine_replace_dictionaries(CastorEngine *engine, const uint8_t *json_ptr, size_t json_len);
CastorOperationResult castor_engine_set_captured_keys(CastorEngine *engine, const uint16_t *keys_ptr, size_t keys_len);
void castor_engine_reset_input(CastorEngine *engine);
uint8_t castor_engine_interrupt(CastorEngine *engine);

#ifdef __cplusplus
}
#endif
#endif

