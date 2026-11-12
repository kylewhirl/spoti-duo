// Strict, allocation-free parser for OfflineError.proto. No string fields escape.
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
static inline bool SGOfflineVarint(const uint8_t *b, size_t n, size_t *p, uint64_t *v) {
    *v = 0;
    for (unsigned i = 0; i < 10; ++i) {
        if (*p >= n) return false;
        uint8_t c = b[(*p)++];
        if (i == 9 && c > 1) return false;
        *v |= (uint64_t)(c & 127) << (7 * i);
        if (!(c & 128)) return true;
    }
    return false;
}
static inline bool SGOfflineErrorCode(const uint8_t *b, size_t n, int64_t *code) {
    if (!b || !code || !n || n > 65536) return false;
    size_t p = 0; bool found = false; uint64_t result = 0;
    for (unsigned fields = 0; p < n; ++fields) {
        if (fields >= 1024) return false;
        uint64_t tag, value;
        if (!SGOfflineVarint(b, n, &p, &tag) || !(tag >> 3) || (tag >> 3) > 0x1fffffff) return false;
        unsigned wire = tag & 7;
        if ((tag >> 3) == 1) {
            if (found || wire != 0 || !SGOfflineVarint(b, n, &p, &result)) return false;
            found = true; continue;
        }
        switch (wire) {
            case 0: if (!SGOfflineVarint(b, n, &p, &value)) return false; break;
            case 1: if (n-p < 8) return false; p += 8; break;
            case 2:
                if (!SGOfflineVarint(b, n, &p, &value) || value > n-p) return false;
                p += (size_t)value; break;
            case 5: if (n-p < 4) return false; p += 4; break;
            default: return false;
        }
    }
    if (!found) return false;
    memcpy(code, &result, sizeof result);
    return true;
}
