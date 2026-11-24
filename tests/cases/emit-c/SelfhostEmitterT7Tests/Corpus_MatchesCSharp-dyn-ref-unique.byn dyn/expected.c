vtab bynh_vtab_main__Stack_main__IStack
again bynh_vtab_main__Stack_main__IStack
slot push
slot top
slot get_count
count 1
static const struct byn_vt_main__IStack bynh_vtab_main__Stack_main__IStack = { bynh_vt_main__Stack_main__IStack_push, bynh_vt_main__Stack_main__IStack_top, bynh_vt_main__Stack_main__IStack_get_count };
helper bynh_vt_main__Stack_main__IStack_push
static void bynh_vt_main__Stack_main__IStack_push(void* self, int64_t a0) {
    byn_main__Stack__push((bynt_main__Stack*)self, a0);
}
helper bynh_vt_main__Stack_main__IStack_top
static int64_t bynh_vt_main__Stack_main__IStack_top(void* self) {
    return byn_main__Stack__top((bynt_main__Stack*)self);
}
helper bynh_vt_main__Stack_main__IStack_get_count
static int64_t bynh_vt_main__Stack_main__IStack_get_count(void* self) {
    return byn_main__Stack__get_count((bynt_main__Stack*)self);
}