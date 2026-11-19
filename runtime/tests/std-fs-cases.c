/* Replays StdFsTests' exported rows (spec 019 T26, format at csharp/tests/Bayan.Tests/StdPathTests.cs `Export`) through the
 * runtime's `Fs` and `Io` functions, under the scratch root argv[1] (an absolute path this driver creates). The fixture lines
 * (`dir <path> <mode>`, `file <path> <mode> <bytes>`, `link <path> <target> file|dir`) build the tree, their octal modes set once
 * every entry exists; the umask is 022, so an entry a call creates gets the mode .NET's export saw on a 022 host. Each call then
 * prints its outcome: `fileExists` `true`/`false`; `remove`, `createDirectory`, `removeDirectory` `ok`/`fail`; `rename` and `copy`
 * `ok`, `notFound`, `invalidInput`, `isDirectory` (copy only) or `fail`; `readText` the text in hex or `fail`. After the calls it
 * prints what the export does: nothing after `fileExists`, each `copy` destination's tree line (or `absent <path>`) after
 * `copy`, else the tree. In a path field `@ROOT@` is the root, `@RELROOT@` it relative to the working directory, `@TEMP@` the
 * temp directory as .NET's Path.GetTempPath gives it and `@EXE@` argv[0]; a link target under the root prints as `@ROOT@`. POSIX only. */
#include "bayan-rt.h"
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int nibble(char c) {
    return c <= '9' ? c - '0' : c - 'a' + 10;
}

static const char* root;
static const char* relroot;
static const char* temp;
static const char* exe;

/* A byte buffer that grows. */
typedef struct { char* p; size_t n, cap; } buf;

static void put(buf* b, const char* s, size_t n) {
    if (b->n + n + 1 > b->cap) {
        b->cap = (b->n + n + 1) * 2;
        b->p = (char*)realloc(b->p, b->cap);
        if (!b->p) exit(2);
    }
    memcpy(b->p + b->n, s, n);
    b->n += n;
    b->p[b->n] = 0;
}

/* Decodes the field at `p` into `out` (markers expanded, NUL-terminated, length in out->n) and returns its end. */
static char* field(char* p, buf* out) {
    out->n = 0;
    put(out, "", 0);
    while (*p && *p != ' ') {
        if (*p == '@') {
            char* end = strchr(p + 1, '@');
            if (!end) exit(2);
            size_t k = (size_t)(end - p + 1);
            const char* v = k == 6 && strncmp(p, "@ROOT@", 6) == 0 ? root : k == 9 && strncmp(p, "@RELROOT@", 9) == 0 ? relroot
                : k == 6 && strncmp(p, "@TEMP@", 6) == 0 ? temp : k == 5 && strncmp(p, "@EXE@", 5) == 0 ? exe : NULL;
            if (!v) { fprintf(stderr, "unknown marker: %.20s\n", p); exit(2); }
            put(out, v, strlen(v));
            p = end + 1;
            continue;
        }
        char c = (char)(nibble(p[0]) * 16 + nibble(p[1]));
        put(out, &c, 1);
        p += 2;
    }
    return p;
}

/* One line of stdin without its line end, in a buffer that grows; NULL at the end. */
static char* line(void) {
    static buf b;
    int c;
    b.n = 0;
    put(&b, "", 0);
    while ((c = getchar()) != EOF && c != '\n') { char ch = (char)c; put(&b, &ch, 1); }
    if (c == EOF && b.n == 0) return NULL;
    while (b.n > 0 && b.p[b.n - 1] == '\r') b.p[--b.n] = 0;
    return b.p;
}

static byn_str str(buf* b) {
    return (byn_str){(const uint8_t*)b->p, (int64_t)b->n};
}

static void hex(const char* s, size_t n) {
    for (size_t i = 0; i < n; i++) printf("%02x", (uint8_t)s[i]);
}

/* Prints `s` as a field with each occurrence of the root as `@ROOT@` (StdPathTests.Field). */
static void masked(const char* s) {
    size_t r = strlen(root);
    const char* run = s;
    for (const char* p = s; *p;) {
        if (strncmp(p, root, r) == 0) {
            hex(run, (size_t)(p - run));
            printf("@ROOT@");
            p += r;
            run = p;
        } else p++;
    }
    hex(run, strlen(run));
}

/* Prints the tree line of the entry at `path`, named `name` (StdFsTests.Entry). */
static void entry(const char* name, const char* path) {
    struct stat st, target;
    if (lstat(path, &st) != 0) { printf("absent "); hex(name, strlen(name)); printf("\n"); return; }
    if (S_ISLNK(st.st_mode)) {
        char t[4096];
        ssize_t n = readlink(path, t, sizeof t - 1);
        t[n < 0 ? 0 : n] = 0;
        printf("link ");
        hex(name, strlen(name));
        printf(" ");
        masked(t);
        printf(" %s\n", stat(path, &target) == 0 && S_ISDIR(target.st_mode) ? "dir" : "file");
        return;
    }
    printf("%s ", S_ISDIR(st.st_mode) ? "dir" : "file");
    hex(name, strlen(name));
    printf(" %o", (unsigned)(st.st_mode & 07777));
    if (!S_ISDIR(st.st_mode)) {
        printf(" ");
        FILE* f = fopen(path, "rb");
        int c;
        while (f && (c = fgetc(f)) != EOF) printf("%02x", c);
        if (f) fclose(f);
    }
    printf("\n");
}

static int byname(const struct dirent** a, const struct dirent** b) {
    return strcmp((*a)->d_name, (*b)->d_name);
}

/* Prints the tree under `dir` (named `name` from the root), parents first and siblings in ordinal order (StdFsTests.Tree). */
static void tree(const char* dir, const char* name) {
    struct dirent** list;
    int n = scandir(dir, &list, NULL, byname);
    for (int i = 0; i < n; i++) {
        const char* d = list[i]->d_name;
        if (strcmp(d, ".") != 0 && strcmp(d, "..") != 0) {
            buf path = {0}, rel = {0};
            put(&path, dir, strlen(dir));
            put(&path, "/", 1);
            put(&path, d, strlen(d));
            if (*name) { put(&rel, name, strlen(name)); put(&rel, "/", 1); }
            put(&rel, d, strlen(d));
            entry(rel.p, path.p);
            struct stat st;
            if (lstat(path.p, &st) == 0 && S_ISDIR(st.st_mode)) tree(path.p, rel.p);
            free(path.p);
            free(rel.p);
        }
        free(list[i]);
    }
    if (n >= 0) free(list);
}

static const char* outcome(uint32_t e, int is_directory) {
    return e == 0 ? "ok" : e == BYN_IO_NOT_FOUND ? "notFound" : e == BYN_IO_INVALID_INPUT ? "invalidInput"
        : is_directory && e == BYN_IO_IS_DIRECTORY ? "isDirectory" : "fail";
}

int main(int argc, char** argv) {
    if (argc < 2) return 2;
    root = argv[1];
    exe = argv[0];
    char cwd[4096];
    if (!getcwd(cwd, sizeof cwd)) return 2;
    size_t c = strlen(cwd);
    relroot = strncmp(root, cwd, c) == 0 && root[c] == '/' ? root + c + 1 : root;
    const char* t = getenv("TMPDIR");
    static char tbuf[4096];
    snprintf(tbuf, sizeof tbuf, "%s%s", t && *t ? t : "/tmp/", t && *t && t[strlen(t) - 1] == '/' ? "" : "/");
    temp = tbuf;
    umask(022);
    if (mkdir(root, 0777) != 0) { perror(root); return 2; }

    /* The fixture's modes, applied before the first call. */
    static char* modes[256];
    static mode_t mode[256];
    int nmodes = 0, calls = 0, exists = 0;
    static char* copies[64];
    int ncopies = 0;
    buf a = {0}, b = {0}, full = {0};
    char* l;
    while ((l = line())) {
        if (!*l) continue;
        char* sp = strchr(l, ' ');
        if (!sp) return 2;
        *sp = 0;
        const char* op = l;
        char* p = field(sp + 1, &a);
        int fixture = strcmp(op, "dir") == 0 || strcmp(op, "file") == 0 || strcmp(op, "link") == 0;
        /* The mode of a `dir` or `file` line is octal text, not hex. */
        char* m = p;
        if (fixture && strcmp(op, "link") != 0 && *p == ' ') {
            p++;
            while (*p && *p != ' ') p++;
        } else if (*p == ' ') p = field(p + 1, &b);
        if (fixture) {
            if (calls) { fprintf(stderr, "fixture line after a call\n"); return 2; }
            full.n = 0;
            put(&full, root, strlen(root));
            put(&full, "/", 1);
            put(&full, a.p, a.n);
            int ok;
            if (strcmp(op, "link") == 0) ok = symlink(b.p, full.p) == 0;
            else {
                if (strcmp(op, "dir") == 0) ok = mkdir(full.p, 0777) == 0;
                else {
                    buf bytes = {0};
                    if (*p == ' ') field(p + 1, &bytes);
                    else put(&bytes, "", 0);
                    int fd = open(full.p, O_WRONLY | O_CREAT | O_TRUNC, 0666);
                    ok = fd >= 0 && write(fd, bytes.p, bytes.n) == (ssize_t)bytes.n && close(fd) == 0;
                    free(bytes.p);
                }
                if (nmodes == 256) return 2;
                mode[nmodes] = (mode_t)strtol(m + 1, NULL, 8);
                modes[nmodes++] = strdup(full.p);
            }
            if (!ok) { perror(full.p); return 2; }
            continue;
        }
        if (!calls++)
            for (int i = 0; i < nmodes; i++)
                if (chmod(modes[i], mode[i]) != 0) { perror(modes[i]); return 2; }
        if (strcmp(op, "fileExists") == 0) { exists = 1; printf(byn_fs_file_exists(str(&a)) ? "true\n" : "false\n"); }
        else if (strcmp(op, "remove") == 0) printf("%s\n", byn_io_remove(str(&a)) ? "fail" : "ok");
        else if (strcmp(op, "createDirectory") == 0) printf("%s\n", byn_io_create_directory(str(&a)) ? "fail" : "ok");
        else if (strcmp(op, "removeDirectory") == 0) printf("%s\n", byn_io_remove_directory(str(&a)) ? "fail" : "ok");
        else if (strcmp(op, "rename") == 0) printf("%s\n", outcome(byn_fs_rename(str(&a), str(&b)), 0));
        else if (strcmp(op, "copy") == 0) {
            printf("%s\n", outcome(byn_fs_copy(str(&a), str(&b)), 1));
            if (ncopies == 64) return 2;
            copies[ncopies++] = strdup(b.p);
        } else if (strcmp(op, "readText") == 0) {
            byn_str text;
            if (byn_io_read_text(str(&a), &text, &byn_general)) printf("fail\n");
            else { hex((const char*)text.ptr, (size_t)text.len); printf("\n"); }
        } else {
            fprintf(stderr, "unknown row: %.80s\n", op);
            return 2;
        }
    }
    size_t r = strlen(root);
    if (ncopies)
        for (int i = 0; i < ncopies; i++)
            entry(strncmp(copies[i], root, r) == 0 && copies[i][r] == '/' ? copies[i] + r + 1 : copies[i], copies[i]);
    else if (!exists) tree(root, "");
    return 0;
}
