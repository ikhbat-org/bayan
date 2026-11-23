vtab bynh_vtab_main__Box_main__ICount
again bynh_vtab_main__Box_main__ICount
slot get_count
vtab bynh_vtab_main__Box_main__ISized
again bynh_vtab_main__Box_main__ISized
slot show
slot get_size
vtab bynh_vtab_main__Empty_main__ISized
again bynh_vtab_main__Empty_main__ISized
slot show
slot get_size
count 3
static const struct byn_vt_main__ICount bynh_vtab_main__Box_main__ICount = { bynh_vt_main__Box_main__ICount_get_count };
static const struct byn_vt_main__ISized bynh_vtab_main__Box_main__ISized = { bynh_vt_main__Box_main__ISized_show, bynh_vt_main__Box_main__ISized_get_size };
static const struct byn_vt_main__ISized bynh_vtab_main__Empty_main__ISized = { bynh_vt_main__Empty_main__ISized_show, bynh_vt_main__Empty_main__ISized_get_size };
helper bynh_vt_main__Box_main__ICount_get_count
static int64_t bynh_vt_main__Box_main__ICount_get_count(void* self) {
    return ((bynt_main__Box*)self)->count;
}
helper bynh_vt_main__Box_main__ISized_show
static byn_str bynh_vt_main__Box_main__ISized_show(void* self) {
    return byn_main__Box__show((bynt_main__Box*)self);
}
helper bynh_vt_main__Box_main__ISized_get_size
static int64_t bynh_vt_main__Box_main__ISized_get_size(void* self) {
    return ((bynt_main__Box*)self)->size;
}
helper bynh_vt_main__Empty_main__ISized_show
static byn_str bynh_vt_main__Empty_main__ISized_show(void* self) {
    return byn_main__Empty__show((bynt_main__Empty*)self);
}
helper bynh_vt_main__Empty_main__ISized_get_size
static int64_t bynh_vt_main__Empty_main__ISized_get_size(void* self) {
    return byn_main__Empty__get_size((bynt_main__Empty*)self);
}