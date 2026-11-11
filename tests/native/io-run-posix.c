/* POSIX `byn_io_run_with` edges, one line each: the result, then the child's exit code. A child that leaves its process
 * group still ends a 300 ms timeout in time (under 3 s); the longest timeout never passes; a deleted working directory
 * does not stop a program found on an absolute PATH. Run as `<self> child <pgid>`, it is the child that leaves. */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L /* setpgid, setenv under -std=c11 on glibc */
#endif
#include "bayan-rt.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define S(x) ((byn_str){(const uint8_t*)(x), (int64_t)strlen(x)})

static uint32_t run(const char* program, const char* script, const byn_str* dir, int64_t timeout_ms, byn_process* out) {
    byn_str args[2] = {S("-c"), S(script)};
    return byn_io_run_with(S(program), args, 2, dir, NULL, -1, NULL, NULL, NULL, 0, timeout_ms, out, NULL, &byn_general);
}

int main(int argc, char** argv) {
    if (argc == 3 && strcmp(argv[1], "child") == 0) {
        if (setpgid(0, (pid_t)atol(argv[2])) != 0) return 1;
        sleep(6);
        return 0;
    }
    char pgid[32];
    snprintf(pgid, sizeof pgid, "%ld", (long)getpgrp());
    byn_str args[2] = {S("child"), S(pgid)};
    byn_process out = {0};
    int64_t start = byn_io_monotonic_nanos();
    uint32_t r = byn_io_run_with(S(argv[0]), args, 2, NULL, NULL, -1, NULL, NULL, NULL, 0, 300, &out, NULL, &byn_general);
    int64_t ms = (byn_io_monotonic_nanos() - start) / 1000000;
    printf("left group: %u in time %d\n", (unsigned)r, ms < 3000);
    fprintf(stderr, "left group took %lld ms\n", (long long)ms);

    out = (byn_process){0};
    r = run("sh", "exit 0", NULL, INT64_MAX, &out);
    printf("longest timeout: %u code %d\n", (unsigned)r, (int)out.exit_code);

    char gone[64];
    snprintf(gone, sizeof gone, "/tmp/byn-cwd-%ld", (long)getpid());
    if (mkdir(gone, 0700) != 0 || chdir(gone) != 0 || rmdir(gone) != 0 || setenv("PATH", "/usr/bin:/bin", 1) != 0) return 1;
    byn_str tmp = S("/tmp");
    out = (byn_process){0};
    r = run("sh", "exit 0", &tmp, -1, &out);
    printf("deleted directory: %u code %d\n", (unsigned)r, (int)out.exit_code);
    return 0;
}
