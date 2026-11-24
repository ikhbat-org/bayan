/* `byn_fs_size` on a file it writes (argument 1) and on a missing path (argument 1 with `.missing` appended): the size of
 * the written bytes, and `notFound` with `*out` untouched. */
#include "bayan-rt.h"
#include <stdio.h>
#include <string.h>

enum { SIZE = 12345 };

int main(int argc, char** argv) {
    (void)argc;
    const char* path = argv[1];
    FILE* f = fopen(path, "wb");
    if (!f) return 1;
    for (int i = 0; i < SIZE; i++) fputc(i & 0xff, f);
    fclose(f);
    int64_t size = -1;
    uint32_t err = byn_fs_size((byn_str){(const uint8_t*)path, (int64_t)strlen(path)}, &size);
    printf("file %u size %lld\n", err, (long long)size);
    char missing[4096];
    snprintf(missing, sizeof missing, "%s.missing", path);
    int64_t none = -1;
    err = byn_fs_size((byn_str){(const uint8_t*)missing, (int64_t)strlen(missing)}, &none);
    printf("missing %u size %lld\n", err, (long long)none);
    return 0;
}
