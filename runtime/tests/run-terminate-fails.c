/* Windows only, built by RuntimeNativeTests against a runtime whose timed-out `TerminateJobObject` always fails: a 200 ms
 * timeout on a cmd whose two pings (one a `start /b` grandchild) hold the pipes for about 30 s. Prints the result and
 * whether the call came back in time (under 20 s: the joins after the deadline are bounded by BYN_RUN_DRAIN_MS). */
#include "bayan-rt.h"
#include <stdio.h>
#include <string.h>

#define S(x) ((byn_str){(const uint8_t*)(x), (int64_t)strlen(x)})

int main(void) {
    byn_str args[2] = {S("/c"), S("start /b ping -n 30 127.0.0.1 & ping -n 30 127.0.0.1")};
    byn_process out = {0};
    int64_t start = byn_io_monotonic_nanos();
    uint32_t r = byn_io_run_with(S("cmd"), args, 2, NULL, NULL, -1, NULL, NULL, NULL, 0, 200, &out, NULL, &byn_general);
    int64_t ms = (byn_io_monotonic_nanos() - start) / 1000000;
    printf("result %u in time %d\n", (unsigned)r, ms < 20000);
    fprintf(stderr, "took %lld ms\n", (long long)ms);
    return 0;
}
