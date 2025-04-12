#include <ruby.h>

static VALUE idhash_distance(VALUE self, VALUE a, VALUE b) {
    const size_t max_words = 256 / sizeof(uint64_t);

    const size_t word_numbits = sizeof(uint64_t) * CHAR_BIT;
    size_t n;
    n = rb_absint_numwords(a, word_numbits, NULL);
    if (n > max_words || n == (size_t)-1)
        rb_raise(rb_eRangeError, "fingerprint #1 exceeds 256 bits");
    n = rb_absint_numwords(b, word_numbits, NULL);
    if (n > max_words || n == (size_t)-1)
        rb_raise(rb_eRangeError, "fingerprint #2 exceeds 256 bits");

    uint64_t as[max_words], bs[max_words];
    rb_integer_pack(
        a, as, max_words, sizeof(uint64_t), 0,
        INTEGER_PACK_LSWORD_FIRST | INTEGER_PACK_NATIVE_BYTE_ORDER | INTEGER_PACK_2COMP
    );
    rb_integer_pack(
        b, bs, max_words, sizeof(uint64_t), 0,
        INTEGER_PACK_LSWORD_FIRST | INTEGER_PACK_NATIVE_BYTE_ORDER | INTEGER_PACK_2COMP
    );

    return INT2FIX(
        __builtin_popcountll((as[3] | bs[3]) & (as[1] ^ bs[1])) +
        __builtin_popcountll((as[2] | bs[2]) & (as[0] ^ bs[0]))
    );
}

void Init_idhash() {
    VALUE m = rb_define_module("DHashVips");
    VALUE mm = rb_define_module_under(m, "IDHash");
    rb_define_module_function(mm, "distance3_c", idhash_distance, 2);
}
