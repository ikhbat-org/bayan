vtab bynh_vtab_main__Digits_main__IParser
again bynh_vtab_main__Digits_main__IParser
slot parse
slot check
count 1
static const struct byn_vt_main__IParser bynh_vtab_main__Digits_main__IParser = { bynh_vt_main__Digits_main__IParser_parse, bynh_vt_main__Digits_main__IParser_check };
helper bynh_vt_main__Digits_main__IParser_parse
static byn_err bynh_vt_main__Digits_main__IParser_parse(void* self, byn_str a0, int64_t* byn_out) {
    return byn_main__Digits__parse((bynt_main__Digits*)self, a0, byn_out);
}
helper bynh_vt_main__Digits_main__IParser_check
static byn_err bynh_vt_main__Digits_main__IParser_check(void* self, byn_str a0) {
    return byn_main__Digits__check((bynt_main__Digits*)self, a0);
}