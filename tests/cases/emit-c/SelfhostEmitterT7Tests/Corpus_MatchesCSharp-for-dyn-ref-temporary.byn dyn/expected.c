vtab bynh_vtab_main__S_main__IThing
again bynh_vtab_main__S_main__IThing
slot get
slot bump
count 1
static const struct byn_vt_main__IThing bynh_vtab_main__S_main__IThing = { bynh_vt_main__S_main__IThing_get, bynh_vt_main__S_main__IThing_bump };
helper bynh_vt_main__S_main__IThing_get
static int64_t bynh_vt_main__S_main__IThing_get(void* self) {
    return byn_main__S__get((bynt_main__S*)self);
}
helper bynh_vt_main__S_main__IThing_bump
static void bynh_vt_main__S_main__IThing_bump(void* self) {
    byn_main__S__bump((bynt_main__S*)self);
}