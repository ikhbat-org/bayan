/* Replays StdEnvTests' exported rows (spec 019 T26, format at csharp/tests/Bayan.Tests/StdPathTests.cs `Export`) through
 * `byn_env_get`, one stdin line each. `set <name> <value>` sets the variable to the field's bytes; `get <name>` prints the result as
 * the export does: `null` when unset, `host` when the name (cut at a NUL, as getenv sees it) was not set by a `set` line, else the
 * hex of the value. On Windows a `set` goes through SetEnvironmentVariableW from UTF-8, the block `byn_env_get` reads, and a
 * name counts as set whatever its case, as the block matches it. */
#include "bayan-rt.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>

/* The UTF-8 string `s` as a NUL-terminated wide string from malloc. */
static wchar_t* wide(const char* s) {
    int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
    wchar_t* w = (wchar_t*)malloc(sizeof(wchar_t) * (size_t)(n > 0 ? n : 1));
    if (!w) exit(2);
    if (n <= 0 || MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n) != n) w[0] = 0;
    return w;
}
#endif

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
#ifdef _WIN32
            wchar_t* wn = wide(n);
            wchar_t* wv = wide(v);
            BOOL ok = SetEnvironmentVariableW(wn, wv);
            free(wn);
            free(wv);
            if (!ok || nset == 256) return 2;
#else
            if (setenv(n, v, 1) != 0 || nset == 256) return 2;
#endif
            set[nset++] = n;
            free(v);
        } else if (strncmp(l, "get ", 4) == 0) {
            byn_str name, r;
            field(l + 4, &name);
            if (!byn_env_get(name, &r, &byn_general)) { printf("null\n"); continue; }
            int known = 0;
#ifdef _WIN32
            size_t k = strnlen((const char*)name.ptr, (size_t)name.len);
            char* cut = (char*)malloc(k + 1);
            if (!cut) return 2;
            memcpy(cut, name.ptr, k);
            cut[k] = 0;
            wchar_t* wc = wide(cut);
            for (int i = 0; i < nset && !known; i++) {
                wchar_t* ws = wide(set[i]);
                known = CompareStringOrdinal(ws, -1, wc, -1, TRUE) == CSTR_EQUAL;
                free(ws);
            }
            free(wc);
            free(cut);
#else
            for (int i = 0; i < nset && !known; i++) known = strlen(set[i]) == strnlen((const char*)name.ptr, (size_t)name.len) &&
                memcmp(set[i], name.ptr, strlen(set[i])) == 0;
#endif
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
