vtab bynh_vtab_main__Tile_main__IShape
again bynh_vtab_main__Tile_main__IShape
slot area
slot grow
slot describe
count 1
static const struct byn_vt_main__IShape bynh_vtab_main__Tile_main__IShape = { bynh_vt_main__Tile_main__IShape_area, bynh_vt_main__Tile_main__IShape_grow, bynh_vt_main__Tile_main__IShape_describe };
helper bynh_vt_main__Tile_main__IShape_area
static int64_t bynh_vt_main__Tile_main__IShape_area(void* self) {
    return byn_main__Tile__area((bynt_main__Tile*)self);
}
helper bynh_vt_main__Tile_main__IShape_grow
static void bynh_vt_main__Tile_main__IShape_grow(void* self) {
    byn_main__Tile__grow((bynt_main__Tile*)self);
}
helper bynh_vt_main__Tile_main__IShape_describe
static byn_str bynh_vt_main__Tile_main__IShape_describe(void* self) {
    return byn_main__Tile__describe((bynt_main__Tile*)self);
}