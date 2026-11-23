typedef struct bynt_std_json__JsonReader bynt_std_json__JsonReader;
typedef struct byn_std_json_JsonToken byn_std_json_JsonToken;
typedef struct byn_std_json_JsonValue byn_std_json_JsonValue;
typedef struct bynt_opt_std_json__JsonToken bynt_opt_std_json__JsonToken;
typedef struct byn_std_json_ReadState byn_std_json_ReadState;
typedef struct bynt_list_bool bynt_list_bool;
typedef struct bynt_list_std_json__JsonValue bynt_list_std_json__JsonValue;
typedef struct bynt_list_std_json__JsonMember bynt_list_std_json__JsonMember;
typedef struct bynt_std_json__JsonMember bynt_std_json__JsonMember;
struct byn_std_json_ReadState {
    int32_t tag;
};
struct bynt_list_bool {
    bool* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_std_json__JsonReader {
    byn_str text;
    int64_t pos;
    int64_t line;
    int64_t lineStart;
    byn_std_json_ReadState state;
    bynt_list_bool open;
};
struct byn_std_json_JsonToken {
    int32_t tag;
    union {
        struct { byn_str name; } key;
        struct { byn_str value; } text;
        struct { double value; byn_str text; } number;
        struct { bool value; } flag;
    } u;
};
struct bynt_list_std_json__JsonValue {
    byn_std_json_JsonValue* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct bynt_list_std_json__JsonMember {
    bynt_std_json__JsonMember* ptr;
    int64_t len;
    int64_t cap;
    byn_alloc* alloc;
};
struct byn_std_json_JsonValue {
    int32_t tag;
    union {
        struct { bool value; } flag;
        struct { double value; byn_str text; } number;
        struct { byn_str value; } text;
        struct { bynt_list_std_json__JsonValue items; } list;
        struct { bynt_list_std_json__JsonMember members; } object;
    } u;
};
struct bynt_opt_std_json__JsonToken {
    bool has;
    byn_std_json_JsonToken value;
};
struct bynt_std_json__JsonMember {
    byn_str key;
    byn_std_json_JsonValue value;
};