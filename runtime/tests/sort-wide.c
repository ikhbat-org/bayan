/* Sorts records wider than byn_sort_reverse's 64-byte swap buffer (HF-0003) and checks order, stability, and that each
 * record's pointer still points at its own payload. */
#include "bayan-rt.h"
#include <stdio.h>

typedef struct {
    int64_t key;
    int64_t index;
    const int64_t* self;
    int64_t pad[10];
} wide; /* 104 bytes: one full chunk and a 40-byte remainder */

static bool less_wide(const void* a, const void* b) { return ((const wide*)a)->key < ((const wide*)b)->key; }

int main(void) {
    enum { n = 300 };
    static wide xs[n];
    int64_t seed = 7;
    for (int64_t i = 0; i < n; i++) {
        seed = (seed * 1103515245 + 12345) % 2147483648;
        xs[i].key = seed % 17;
        xs[i].index = i;
        for (int k = 0; k < 10; k++) xs[i].pad[k] = i * 10 + k;
    }
    for (int64_t i = 0; i < n; i++) xs[i].self = &xs[i].pad[0];
    const int64_t* before[n];
    for (int64_t i = 0; i < n; i++) before[i] = xs[i].self;
    byn_sort(xs, n, (int64_t)sizeof(wide), less_wide);
    int sorted = 1, stable = 1, intact = 1;
    for (int64_t i = 0; i < n; i++) {
        if (i > 0 && xs[i - 1].key > xs[i].key) sorted = 0;
        if (i > 0 && xs[i - 1].key == xs[i].key && xs[i - 1].index > xs[i].index) stable = 0;
        if (xs[i].self != before[xs[i].index]) intact = 0;
        for (int k = 0; k < 10; k++)
            if (xs[i].pad[k] != xs[i].index * 10 + k) intact = 0;
    }
    printf("size %d, sorted %d, stable %d, payload intact %d\n", (int)sizeof(wide), sorted, stable, intact);
    return 0;
}
