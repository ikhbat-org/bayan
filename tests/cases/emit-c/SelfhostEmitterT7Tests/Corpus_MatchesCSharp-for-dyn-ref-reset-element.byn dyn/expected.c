vtab bynh_vtab_main__B_main__IReset
again bynh_vtab_main__B_main__IReset
slot reset
count 1
static const struct byn_vt_main__IReset bynh_vtab_main__B_main__IReset = { bynh_vt_main__B_main__IReset_reset };
helper bynh_vt_main__B_main__IReset_reset
static void bynh_vt_main__B_main__IReset_reset(void* self) {
    byn_main__B__reset((bynt_main__B*)self);
}