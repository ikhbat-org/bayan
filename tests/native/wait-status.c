/* Prints `byn_wait_status` for each case, one line each: the result, then `*code` and `*detail` (-1 when left untouched). */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L /* kill under -std=c11 on glibc */
#endif
#include "bayan-rt.h"
#include <errno.h>
#include <stdio.h>
#ifndef _WIN32
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

static void show(const char* label, int outcome, uint32_t raw) {
    int32_t code = -1;
    int64_t detail = -1;
    uint32_t r = byn_wait_status(outcome, raw, &code, &detail);
    printf("%s: %u code %d detail %lld\n", label, (unsigned)r, (int)code, (long long)detail);
}

#ifndef _WIN32
/* A real waitpid status: a child that exits with `exit_code`, or kills itself with SIGKILL when `exit_code` is -1. */
static uint32_t child_status(int exit_code) {
    pid_t pid = fork();
    if (pid < 0) return 0xFFFFFFFFu;
    if (pid == 0) {
        if (exit_code < 0) kill(getpid(), SIGKILL);
        _exit(exit_code < 0 ? 0 : exit_code);
    }
    int status = 0;
    pid_t waited;
    while ((waited = waitpid(pid, &status, 0)) < 0 && errno == EINTR) {}
    if (waited != pid) return 0xFFFFFFFFu;
    return (uint32_t)status;
}
#endif

int main(void) {
    show("failed raw 0", BYN_WAIT_FAILED, 0);
    show("query failed raw 259", BYN_WAIT_QUERY_FAILED, 259);
    show("failed raw 259", BYN_WAIT_FAILED, 259);
    show("timed out", BYN_WAIT_TIMED_OUT, 0);
#ifdef _WIN32
    show("exit 3", BYN_WAIT_DONE, 3);
#else
    show("signaled", BYN_WAIT_DONE, child_status(-1));
    show("exit 3", BYN_WAIT_DONE, child_status(3));
#endif
    return 0;
}
