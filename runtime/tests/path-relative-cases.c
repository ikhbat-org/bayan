/* Runs `byn_path_relative` on every case read from stdin and prints one line per case: the result in hex. A case is
 * one line of two space-separated hex fields, from then to. Hex carries bytes that are not UTF-8, which no Bayan
 * string holds, so the runtime's U+FFFD handling is checked against .NET here. With `from` on a root `to` does not share, the
 * result is `to`'s full path, which is how StdPathTests.ShortNamesExpandAsDotNet shows each short-name expansion. */
#include "bayan-rt.h"
#include <stdio.h>
#include <string.h>

static int nibble(char c) {
    return c <= '9' ? c - '0' : c - 'a' + 10;
}

/* Decodes the field at `p` in place and returns its end. */
static char* field(char* p, byn_str* out) {
    char* end = p;
    while (*end && *end != ' ') end++;
    int64_t n = 0;
    for (char* q = p; q < end; q += 2) p[n++] = (char)(nibble(q[0]) * 16 + nibble(q[1]));
    *out = (byn_str){(const uint8_t*)p, n};
    return end;
}

/* Length of the well-formed sequence at `p`, or the length of its maximal invalid subpart as a negative number. */
static int utf8_step(const uint8_t* p, int64_t left) {
    uint8_t b = p[0];
    int need = b < 0x80 ? 1 : b >= 0xC2 && b <= 0xDF ? 2 : b >= 0xE0 && b <= 0xEF ? 3 : b >= 0xF0 && b <= 0xF4 ? 4 : 0;
    if (need == 0) return -1;
    if (need == 1) return 1;
    uint8_t lo = 0x80, hi = 0xBF;
    if (b == 0xE0) lo = 0xA0;
    if (b == 0xED) hi = 0x9F;
    if (b == 0xF0) lo = 0x90;
    if (b == 0xF4) hi = 0x8F;
    for (int j = 1; j < need; j++) {
        if (j >= left || p[j] < lo || p[j] > hi) return -j;
        lo = 0x80; hi = 0xBF;
    }
    return need;
}

int main(void) {
    static char buf[1 << 16];
    while (fgets(buf, sizeof buf, stdin)) {
        size_t len = strlen(buf);
        while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r')) buf[--len] = 0;
        if (len == 0) continue;
        byn_str from, to;
        char* p = field(buf, &from);
        field(p + 1, &to);
        byn_str r = byn_path_relative(from, to, &byn_general, __FILE__, __LINE__);
        /* StdPathTests decodes the runtime's bytes with Encoding.UTF8.GetString, so each maximal invalid subpart is U+FFFD. */
        for (int64_t i = 0; i < r.len;) {
            int n = utf8_step(r.ptr + i, r.len - i);
            if (n > 0) for (int k = 0; k < n; k++) printf("%02x", r.ptr[i + k]);
            else { printf("efbfbd"); n = -n; }
            i += n;
        }
        printf("\n");
    }
    return 0;
}
