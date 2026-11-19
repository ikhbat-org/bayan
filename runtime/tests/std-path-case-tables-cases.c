/* Replays StdPathTests.CaseTablesMatchDotNet's exported rows (spec 019 T26) through the runtime's path case tables, which are
 * static, so this driver includes bayan-rt.c and is built alone. A row `<table> <first> <last>` (hex) prints, for each code in the
 * range the table moves, `<table> <code> <upper>` in hex: `invariant` is `byn_path_upper`, `ordinal` `byn_path_upper_ordinal_unit`
 * (4 digits each) and `scalar` `byn_path_upper_scalar_of`. */
#include "bayan-rt.c"
#include <stdio.h>
#include <string.h>

int main(void) {
    char table[16];
    unsigned long first, last;
    while (scanf("%15s %lx %lx", table, &first, &last) == 3) {
        for (unsigned long c = first; c <= last; c++) {
            if (strcmp(table, "invariant") == 0) {
                uint16_t u = byn_path_upper((uint16_t)c);
                if (u != c) printf("invariant %04lx %04x\n", c, u);
            } else if (strcmp(table, "ordinal") == 0) {
                uint16_t u = byn_path_upper_ordinal_unit((uint16_t)c);
                if (u != c) printf("ordinal %04lx %04x\n", c, u);
            } else if (strcmp(table, "scalar") == 0) {
                uint32_t u = byn_path_upper_scalar_of((uint32_t)c);
                if (u != c) printf("scalar %lx %x\n", c, u);
            } else {
                fprintf(stderr, "unknown table: %s\n", table);
                return 2;
            }
        }
    }
    return 0;
}
