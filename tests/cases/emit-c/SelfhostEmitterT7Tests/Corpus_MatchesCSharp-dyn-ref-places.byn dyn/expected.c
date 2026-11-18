vtab bynh_vtab_main__Counter_main__ICounter
again bynh_vtab_main__Counter_main__ICounter
slot bump
slot report
slot get_value
count 1
static const struct byn_vt_main__ICounter bynh_vtab_main__Counter_main__ICounter = { bynh_vt_main__Counter_main__ICounter_bump, bynh_vt_main__Counter_main__ICounter_report, bynh_vt_main__Counter_main__ICounter_get_value };
helper bynh_vt_main__Counter_main__ICounter_bump
static void bynh_vt_main__Counter_main__ICounter_bump(void* self, int64_t a0) {
    byn_main__Counter__bump((bynt_main__Counter*)self, a0);
}
helper bynh_vt_main__Counter_main__ICounter_report
static void bynh_vt_main__Counter_main__ICounter_report(void* self) {
    byn_main__Counter__report((bynt_main__Counter*)self);
}
helper bynh_vt_main__Counter_main__ICounter_get_value
static int64_t bynh_vt_main__Counter_main__ICounter_get_value(void* self) {
    return byn_main__Counter__get_value((bynt_main__Counter*)self);
}