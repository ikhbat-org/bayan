/* `byn_io_read_stdin_some` over a pipe on fd 0: one read returns what the pipe holds, up to the buffer (a short read
 * does not wait for more), 0 once the write end is closed, and an error once fd 0 is closed. Stdout is a second pipe:
 * a buffered `Io.stdout.write` is in it after the read, before a byte written straight to fd 1 behind it. */
#include "bayan-rt.h"
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#define pipe(fds) _pipe(fds, 4096, _O_BINARY)
#define dup _dup
#define dup2 _dup2
#define close _close
#define read _read
#define write _write
#else
#include <unistd.h>
#endif

static void show(const char* what, uint32_t err, const uint8_t* buf, int64_t got) {
    printf("%s: err %u got %lld \"%.*s\"\n", what, err, (long long)got, (int)(got > 0 ? got : 0), (const char*)buf);
}

int main(void) {
    int in[2], out[2];
    if (pipe(in) != 0 || pipe(out) != 0) return 1;
    int saved = dup(1);
    if (dup2(in[0], 0) < 0 || dup2(out[1], 1) < 0) return 1;
    close(in[0]);
    close(out[1]);

    uint8_t buf[8];
    int64_t got = -1;
    if (write(in[1], "hello", 5) != 5) return 1;
    byn_io_write(1, (byn_str){(const uint8_t*)"reply\n", 6});
    uint32_t e1 = byn_io_read_stdin_some(buf, 3, &got);
    if (write(1, "#", 1) != 1) return 1;
    uint8_t first[3];
    int64_t got1 = got;
    memcpy(first, buf, 3);
    char replied[16] = {0};
    int r = read(out[0], replied, sizeof replied - 1);
    uint32_t e2 = byn_io_read_stdin_some(buf, 3, &got);
    uint8_t second[3];
    int64_t got2 = got;
    memcpy(second, buf, 3);
    if (write(in[1], "xyz", 3) != 3) return 1;
    uint32_t e3 = byn_io_read_stdin_some(buf, 8, &got);
    uint8_t third[8];
    int64_t got3 = got;
    memcpy(third, buf, 8);
    close(in[1]);
    uint32_t e4 = byn_io_read_stdin_some(buf, 8, &got);
    int64_t got4 = got;
    close(0);
    got = -1;
    uint32_t e5 = byn_io_read_stdin_some(buf, 8, &got);
    int64_t got5 = got;

    dup2(saved, 1);
    close(saved);
    for (int i = 0; i < r; i++) replied[i] = replied[i] == '\n' ? '/' : replied[i];
    printf("stdout: \"%.*s\"\n", r > 0 ? r : 0, replied);
    show("short", e1, first, got1);
    show("rest", e2, second, got2);
    show("more", e3, third, got3);
    show("end", e4, buf, got4);
    printf("closed: failed %d got %lld\n", e5 != 0, (long long)got5);
    return 0;
}
