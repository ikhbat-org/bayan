/* Reads a 1.5 MiB file through an allocator that counts its resizes and prints the count and whether the bytes match:
 * a read sized from the file takes one buffer, so an arena keeps no superseded ones. Argument 1 is the file to write. */
#include "bayan-rt.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { SIZE = 3 << 19 };

static int resizes;
static void* counting(byn_alloc* self, void* old, int64_t old_size, int64_t new_size) {
    (void)self;
    resizes++;
    return byn_general.resize(&byn_general, old, old_size, new_size);
}
static byn_alloc counter = {counting};

int main(int argc, char** argv) {
    (void)argc;
    const char* path = argv[1];
    FILE* f = fopen(path, "wb");
    if (!f) return 1;
    uint8_t* bytes = malloc(SIZE);
    if (!bytes) return 1;
    for (int i = 0; i < SIZE; i++) bytes[i] = (uint8_t)(i * 7);
    fwrite(bytes, 1, SIZE, f);
    fclose(f);
    uint8_t* got;
    int64_t len;
    uint32_t err = byn_io_read((byn_str){(const uint8_t*)path, (int64_t)strlen(path)}, &got, &len, &counter);
    int same = err == 0 && len == SIZE && memcmp(got, bytes, SIZE) == 0;
    printf("file %u resizes %d same %d\n", err, resizes, same);
    return 0;
}
