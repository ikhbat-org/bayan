vtab bynh_vtab_main__Num_main__INode
again bynh_vtab_main__Num_main__INode
slot eval
slot describe
slot get_name
vtab bynh_vtab_main__Add_main__INode
again bynh_vtab_main__Add_main__INode
slot eval
slot describe
slot get_name
vtab bynh_vtab_main__Mul_main__INode
again bynh_vtab_main__Mul_main__INode
slot eval
slot describe
slot get_name
count 3
static const struct byn_vt_main__INode bynh_vtab_main__Num_main__INode = { bynh_vt_main__Num_main__INode_eval, bynh_vt_main__Num_main__INode_describe, bynh_vt_main__Num_main__INode_get_name };
static const struct byn_vt_main__INode bynh_vtab_main__Add_main__INode = { bynh_vt_main__Add_main__INode_eval, bynh_vt_main__Add_main__INode_describe, bynh_vt_main__Add_main__INode_get_name };
static const struct byn_vt_main__INode bynh_vtab_main__Mul_main__INode = { bynh_vt_main__Mul_main__INode_eval, bynh_vt_main__Mul_main__INode_describe, bynh_vt_main__Mul_main__INode_get_name };
helper bynh_vt_main__Num_main__INode_eval
static int64_t bynh_vt_main__Num_main__INode_eval(void* self) {
    return byn_main__Num__eval((bynt_main__Num*)self);
}
helper bynh_vt_main__Num_main__INode_describe
static byn_str bynh_vt_main__Num_main__INode_describe(void* self) {
    return byn_main__Num__describe((bynt_main__Num*)self);
}
helper bynh_vt_main__Num_main__INode_get_name
static byn_str bynh_vt_main__Num_main__INode_get_name(void* self) {
    return byn_main__Num__get_name((bynt_main__Num*)self);
}
helper bynh_vt_main__Add_main__INode_eval
static int64_t bynh_vt_main__Add_main__INode_eval(void* self) {
    return byn_main__Add__eval((bynt_main__Add*)self);
}
helper bynh_vt_main__Add_main__INode_describe
static byn_str bynh_vt_main__Add_main__INode_describe(void* self) {
    return byn_main__Add__describe((bynt_main__Add*)self);
}
helper bynh_vt_main__Add_main__INode_get_name
static byn_str bynh_vt_main__Add_main__INode_get_name(void* self) {
    return byn_main__Add__get_name((bynt_main__Add*)self);
}
helper bynh_vt_main__Mul_main__INode_eval
static int64_t bynh_vt_main__Mul_main__INode_eval(void* self) {
    return byn_main__Mul__eval((bynt_main__Mul*)self);
}
helper bynh_vt_main__Mul_main__INode_describe
static byn_str bynh_vt_main__Mul_main__INode_describe(void* self) {
    return byn_main__Mul__describe((bynt_main__Mul*)self);
}
helper bynh_vt_main__Mul_main__INode_get_name
static byn_str bynh_vt_main__Mul_main__INode_get_name(void* self) {
    return byn_main__Mul__get_name((bynt_main__Mul*)self);
}