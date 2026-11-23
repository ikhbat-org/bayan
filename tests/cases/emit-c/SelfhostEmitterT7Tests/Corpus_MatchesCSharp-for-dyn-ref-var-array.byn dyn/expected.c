vtab bynh_vtab_main__C_main__IC
again bynh_vtab_main__C_main__IC
slot bump
slot get_n
count 1
static const struct byn_vt_main__IC bynh_vtab_main__C_main__IC = { bynh_vt_main__C_main__IC_bump, bynh_vt_main__C_main__IC_get_n };
helper bynh_vt_main__C_main__IC_bump
static void bynh_vt_main__C_main__IC_bump(void* self) {
    byn_main__C__bump((bynt_main__C*)self);
}
helper bynh_vt_main__C_main__IC_get_n
static int64_t bynh_vt_main__C_main__IC_get_n(void* self) {
    return ((bynt_main__C*)self)->n;
}