vtab bynh_vtab_main__B_main__ICount
again bynh_vtab_main__B_main__ICount
slot count
count 1
static const struct byn_vt_main__ICount bynh_vtab_main__B_main__ICount = { bynh_vt_main__B_main__ICount_count };
helper bynh_vt_main__B_main__ICount_count
static int64_t bynh_vt_main__B_main__ICount_count(void* self) {
    return byn_main__B__count((bynt_main__B*)self);
}