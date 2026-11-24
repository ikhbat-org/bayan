vtab bynh_vtab_main__Probe_main__IProbe
again bynh_vtab_main__Probe_main__IProbe
slot fill
slot put
slot trying
slot stop
count 1
static const struct byn_vt_main__IProbe bynh_vtab_main__Probe_main__IProbe = { bynh_vt_main__Probe_main__IProbe_fill, bynh_vt_main__Probe_main__IProbe_put, bynh_vt_main__Probe_main__IProbe_trying, bynh_vt_main__Probe_main__IProbe_stop };
helper bynh_vt_main__Probe_main__IProbe_fill
static void bynh_vt_main__Probe_main__IProbe_fill(void* self, bynt_list_i64* a0) {
    byn_main__Probe__fill((bynt_main__Probe*)self, a0);
}
helper bynh_vt_main__Probe_main__IProbe_put
static void bynh_vt_main__Probe_main__IProbe_put(void* self, int64_t* a0) {
    byn_main__Probe__put((bynt_main__Probe*)self, a0);
}
helper bynh_vt_main__Probe_main__IProbe_trying
static byn_err bynh_vt_main__Probe_main__IProbe_trying(void* self, int64_t a0, int64_t* byn_out) {
    return byn_main__Probe__trying((bynt_main__Probe*)self, a0, byn_out);
}
helper bynh_vt_main__Probe_main__IProbe_stop
static void bynh_vt_main__Probe_main__IProbe_stop(void* self) {
    byn_main__Probe__stop((bynt_main__Probe*)self);
}