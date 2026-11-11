/* POSIX `byn_io_run_with` edges, one line each: the result, then the child's exit code. A child that leaves its process
 * group still ends a 300 ms timeout in time (under 3 s); the longest timeout never passes; a deleted working directory
 * does not stop a program found on an absolute PATH. Run as `<self> child <pgid>`, it is the child that leaves. */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L /* setpgid, setenv under -std=c11 on glibc */
#endif
#include "bayan-rt.h"
#include <errno.h>
#include <signal.h>
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
    if (argc == 4 && strcmp(argv[1], "helper") == 0) {
        /* forks a helper that stays in the original group, records its pid, then leaves the group */
        pid_t h = fork();
        if (h < 0) return 1;
        if (h == 0) {
            signal(SIGTERM, SIG_IGN); /* survives the group's SIGTERM, so the group stays signalable until SIGKILL */
            sleep(6);
            _exit(0);
        }
        FILE* f = fopen(argv[3], "w");
        if (!f) return 1;
        fprintf(f, "%ld", (long)getpid());
        fclose(f);
        if (setpgid(0, (pid_t)atol(argv[2])) != 0) return 1;
        sleep(6);
        return 0;
    }
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

    char pidfile[64];
    snprintf(pidfile, sizeof pidfile, "/tmp/byn-pid-%ld", (long)getpid());
    byn_str hargs[3] = {S("helper"), S(pgid), S(pidfile)};
    out = (byn_process){0};
    start = byn_io_monotonic_nanos();
    r = byn_io_run_with(S(argv[0]), hargs, 3, NULL, NULL, -1, NULL, NULL, NULL, 0, 300, &out, NULL, &byn_general);
    ms = (byn_io_monotonic_nanos() - start) / 1000000;
    long cpid = 0;
    FILE* pf = fopen(pidfile, "r");
    if (pf) {
        if (fscanf(pf, "%ld", &cpid) != 1) cpid = 0;
        fclose(pf);
    }
    remove(pidfile);
    printf("left group with helper: %u in time %d child gone %d\n", (unsigned)r, ms < 3000,
           cpid > 0 && kill((pid_t)cpid, 0) != 0 && errno == ESRCH);

    out = (byn_process){0};
    r = run("sh", "exit 0", NULL, INT64_MAX, &out);
    printf("longest timeout: %u code %d\n", (unsigned)r, (int)out.exit_code);

    const char* path_env = getenv("PATH");
    char* saved_path = path_env ? strdup(path_env) : NULL;
    char gone[64];
    snprintf(gone, sizeof gone, "/tmp/byn-cwd-%ld", (long)getpid());
    if (mkdir(gone, 0700) != 0 || chdir(gone) != 0 || rmdir(gone) != 0 || setenv("PATH", "/usr/bin:/bin", 1) != 0) return 1;
    byn_str tmp = S("/tmp");
    out = (byn_process){0};
    r = run("sh", "exit 0", &tmp, -1, &out);
    printf("deleted directory: %u code %d\n", (unsigned)r, (int)out.exit_code);
    if (setenv("PATH", ":/bin", 1) != 0) return 1;
    out = (byn_process){0};
    r = run("sh", "exit 0", &tmp, -1, &out);
    printf("deleted directory, empty PATH entry: %u code %d\n", (unsigned)r, (int)out.exit_code);
    if (saved_path ? setenv("PATH", saved_path, 1) : unsetenv("PATH")) return 1;
    free(saved_path);
    return 0;
}
