vtab bynh_vtab_main__E_main__IBox
again bynh_vtab_main__E_main__IBox
slot get_n
count 1
static const struct byn_vt_main__IBox bynh_vtab_main__E_main__IBox = { bynh_vt_main__E_main__IBox_get_n };
helper bynh_vt_main__E_main__IBox_get_n
static int64_t bynh_vt_main__E_main__IBox_get_n(void* self) {
    return byn_main__E__get_n((bynt_main__E*)self);
}