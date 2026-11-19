/* Replays StdEnvTests' exported rows (spec 019 T26, format at csharp/tests/Bayan.Tests/StdPathTests.cs `Export`) through
 * `byn_env_get`, one stdin line each. `set <name> <value>` sets the variable to the field's bytes; `get <name>` prints the result as
 * the export does: `null` when unset, `host` when the name (cut at a NUL, as getenv sees it) was not set by a `set` line, else the
 * hex of the value. POSIX only: a Windows value is UTF-16. */
#include "bayan-rt.h"
#include <stdio.h>
#include <stdlib.h>
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

/* One line of stdin without its line end, in a buffer that grows; NULL at the end. */
static char* line(void) {
    static char* buf;
    static size_t cap;
    size_t n = 0;
    int c;
    while ((c = getchar()) != EOF && c != '\n') {
        if (n + 1 >= cap) {
            cap = cap ? cap * 2 : 1 << 16;
            buf = (char*)realloc(buf, cap);
            if (!buf) exit(2);
        }
        buf[n++] = (char)c;
    }
    if (c == EOF && n == 0) return NULL;
    if (!buf) buf = (char*)calloc(1, 1);
    while (n > 0 && buf[n - 1] == '\r') n--;
    buf[n] = 0;
    return buf;
}

int main(void) {
    static char* set[256];
    int nset = 0;
    char* l;
    while ((l = line())) {
        if (strncmp(l, "set ", 4) == 0) {
            byn_str name, value;
            char* p = field(l + 4, &name);
            field(p + 1, &value);
            char* n = (char*)malloc((size_t)name.len + 1);
            char* v = (char*)malloc((size_t)value.len + 1);
            memcpy(n, name.ptr, (size_t)name.len);
            n[name.len] = 0;
            memcpy(v, value.ptr, (size_t)value.len);
            v[value.len] = 0;
            if (setenv(n, v, 1) != 0 || nset == 256) return 2;
            set[nset++] = n;
            free(v);
        } else if (strncmp(l, "get ", 4) == 0) {
            byn_str name, r;
            field(l + 4, &name);
            if (!byn_env_get(name, &r, &byn_general)) { printf("null\n"); continue; }
            int known = 0;
            for (int i = 0; i < nset && !known; i++) known = strlen(set[i]) == strnlen((const char*)name.ptr, (size_t)name.len) &&
                memcmp(set[i], name.ptr, strlen(set[i])) == 0;
            if (!known) { printf("host\n"); continue; }
            for (int64_t i = 0; i < r.len; i++) printf("%02x", r.ptr[i]);
            printf("\n");
        } else if (*l) {
            fprintf(stderr, "unknown row: %.80s\n", l);
            return 2;
        }
    }
    return 0;
}
