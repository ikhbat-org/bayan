/* Replays StdPathTests' exported rows (spec 019 T26, format at csharp/tests/Bayan.Tests/StdPathTests.cs `Export`) through the
 * runtime's `Path` functions, one stdin line each: `isRooted`, `fileName`, `directoryName`, `fullPath`, `relative <from> <to>`,
 * `combine <a> <b>` and `combineAll <part>...`, each argument a hex field. It prints `true`/`false`, `null` for a missing directory
 * name, else the result in hex. With `--unmask` it instead copies stdin (a `.expected` file) with each working-directory marker
 * (`@CWD@`, `@CWD-n@`, `@CWDREL@`, `@CWDREL-n@`, `@CWDTAIL-a-b@`, `@UP@`, `@UP+k@`, `@UP-k@`) replaced by the hex of its value here. */
#include "bayan-rt.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <direct.h>
#define getcwd _getcwd
#define SEP "\\"
#else
#include <unistd.h>
#define SEP "/"
#endif

static int nibble(char c) {
    return c <= '9' ? c - '0' : c - 'a' + 10;
}

/* The Windows fixture was exported with the working directory on C:. When it is on another drive here, that drive's letter and C
 * trade places (either case) wherever a letter is followed by `:`, in every argument and in every printed result, the cwd markers'
 * root included: a path that takes the current drive (`\x`) then prints C: on any drive, and a C: argument names the current drive
 * as it did on wp1. A row whose arguments are all fully qualified (`X:\`, `X:/`, or two leading separators) does not depend on the
 * current drive and is replayed as exported, since moving it to this drive would look its short names (`C:\PROGRA~1`) up on a
 * drive that lacks them. Off Windows, and on C:, nothing changes. */
static char drive = 'C';
static int trade;

static uint8_t swap(uint8_t c, uint8_t next) {
    if (!trade || next != ':') return c;
    uint8_t up = c >= 'a' && c <= 'z' ? (uint8_t)(c - 32) : c, low = (uint8_t)(c - up);
    if (up == 'C') return (uint8_t)(drive + low);
    if (up == drive) return (uint8_t)('C' + low);
    return c;
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

static int sep(uint8_t c) {
    return c == '\\' || c == '/';
}

/* Sets `trade` for a row with arguments `s[0..n)` and applies it to them in place (they point into the line buffer). */
static void trade_row(byn_str* s, int64_t n) {
    trade = 0;
    if (drive == 'C') return;
    for (int64_t k = 0; k < n; k++) {
        const uint8_t* p = s[k].ptr;
        int64_t len = s[k].len;
        int full = (len >= 3 && ((p[0] | 32) >= 'a' && (p[0] | 32) <= 'z') && p[1] == ':' && sep(p[2])) ||
                   (len >= 2 && sep(p[0]) && sep(p[1]));
        if (!full) trade = 1;
    }
    for (int64_t k = 0; k < n; k++)
        for (int64_t i = 0; i + 1 < s[k].len; i++) ((uint8_t*)s[k].ptr)[i] = swap(s[k].ptr[i], s[k].ptr[i + 1]);
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

static void hex(byn_str s) {
    for (int64_t i = 0; i < s.len; i++) printf("%02x", swap(s.ptr[i], i + 1 < s.len ? s.ptr[i + 1] : 0));
}

static void hexc(const char* s) {
    hex((byn_str){(const uint8_t*)s, (int64_t)strlen(s)});
}

/* The working directory's root and components. */
static char root[8];
static char* parts[512];
static int depth;

/* Prints the hex of components [from, to) joined by the separator. */
static void join(int from, int to) {
    for (int i = from; i < to; i++) {
        if (i > from) hexc(SEP);
        hexc(parts[i]);
    }
}

/* Prints `l` with each marker replaced by the hex of its value (StdPathTests.Unmask). */
static void unmask(const char* l) {
    for (const char* p = l; *p;) {
        const char* end = *p == '@' ? strchr(p + 1, '@') : NULL;
        if (!end) { putchar(*p++); continue; }
        char name[16] = {0};
        const char* q = p + 1;
        size_t k = 0;
        while (q < end && *q >= 'A' && *q <= 'Z' && k < sizeof name - 1) name[k++] = *q++;
        long a = 0, b = 0;
        if (q < end && (*q == '-' || *q == '+')) a = strtol(q, (char**)&q, 10);
        if (q < end && *q == '-') b = strtol(q + 1, (char**)&q, 10);
        if (q != end) { fprintf(stderr, "bad marker: %.40s\n", p); exit(2); }
        if (strcmp(name, "UP") == 0) {
            for (long i = 0; i < depth + a; i++) { if (i > 0) hexc(SEP); hexc(".."); }
        } else if (strcmp(name, "CWD") == 0) { hexc(root); join(0, depth + (int)a); }
        else if (strcmp(name, "CWDREL") == 0) join(0, depth + (int)a);
        else if (strcmp(name, "CWDTAIL") == 0) join(depth + (int)a, depth - (int)b);
        else { fprintf(stderr, "bad marker: %.40s\n", p); exit(2); }
        p = end + 1;
    }
    putchar('\n');
}

int main(int argc, char** argv) {
    char* l;
#ifdef _WIN32
    {
        static char cwd[4096];
        if (!getcwd(cwd, sizeof cwd)) return 2;
        if (cwd[0] >= 'a' && cwd[0] <= 'z') drive = (char)(cwd[0] - 32);
        else if (cwd[0] >= 'A' && cwd[0] <= 'Z') drive = cwd[0];
    }
#endif
    if (argc > 1 && strcmp(argv[1], "--unmask") == 0) {
        static char cwd[4096];
        if (!getcwd(cwd, sizeof cwd)) return 2;
        char* p = cwd;
#ifdef _WIN32
        memcpy(root, cwd, 3);
        p += 3;
#else
        strcpy(root, "/");
#endif
        for (char* t = strtok(p, "/\\"); t && depth < 512; t = strtok(NULL, "/\\")) parts[depth++] = t;
        trade = 1;
        while ((l = line())) unmask(l);
        return 0;
    }
    while ((l = line())) {
        if (!*l) continue;
        char* sp = strchr(l, ' ');
        size_t oplen = sp ? (size_t)(sp - l) : strlen(l);
#define IS(s) (oplen == strlen(s) && strncmp(l, s, oplen) == 0)
        byn_str a = {0}, b = {0};
        trade = 0;
        if (sp && !IS("combineAll")) {
            char* p = field(sp + 1, &a);
            if (*p) field(p + 1, &b);
            byn_str ab[2] = {a, b};
            trade_row(ab, b.ptr ? 2 : 1);
        }
        if (IS("isRooted")) printf(byn_path_is_rooted(a) ? "true" : "false");
        else if (IS("fileName")) hex(byn_path_file_name(a, &byn_general));
        else if (IS("directoryName")) {
            byn_str d;
            if (byn_path_directory_name(a, &d, &byn_general)) hex(d);
            else printf("null");
        } else if (IS("fullPath")) hex(byn_path_full_path(a, &byn_general, __FILE__, __LINE__));
        else if (IS("relative")) hex(byn_path_relative(a, b, &byn_general, __FILE__, __LINE__));
        else if (IS("combine")) hex(byn_path_combine(a, b, &byn_general));
        else if (IS("combineAll")) {
            static byn_str ps[64];
            int64_t n = 0;
            for (char* p = sp; p && *p == ' ' && n < 64;) p = field(p + 1, &ps[n++]);
            trade_row(ps, n);
            hex(byn_path_combine_span(ps, n, &byn_general));
        } else {
            fprintf(stderr, "unknown row: %.80s\n", l);
            return 2;
        }
        printf("\n");
    }
    return 0;
}
