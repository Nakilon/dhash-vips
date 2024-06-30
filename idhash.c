#include <ruby.h>

// extract bignum to array of unsigned ints
static unsigned int * idhash_bignum_to_buf(VALUE a, size_t *num) {
    size_t word_numbits = sizeof(unsigned int) * CHAR_BIT;
    size_t nlz_bits = 0;
    *num = rb_absint_numwords(a, word_numbits, &nlz_bits);

    if (*num == (size_t)-1) {
        rb_raise(rb_eRuntimeError, "Number too large to represent and overflow occured");
    }

    unsigned int *buf = ALLOC_N(unsigned int, *num);

    rb_integer_pack(a, buf, *num, sizeof(unsigned int), 0,
                    INTEGER_PACK_LSWORD_FIRST|INTEGER_PACK_NATIVE_BYTE_ORDER|
                    INTEGER_PACK_2COMP);

    return buf;
}

// does ((a ^ b) & (a | b) >> 128)
static VALUE idhash_distance(VALUE self, VALUE a, VALUE b){
    size_t an, bn;
    unsigned int *as = idhash_bignum_to_buf(a, &an);
    unsigned int *bs = idhash_bignum_to_buf(b, &bn);

    while (an > 0 && as[an-1] == 0) an--;
    while (bn > 0 && bs[bn-1] == 0) bn--;

    if (an < bn) {
      unsigned int *tempd; size_t templ;
      tempd = as; as = bs; bs = tempd;
      templ = an; an = bn; bn = templ;
    }

    size_t i;
    long acc = 0;
    // to count >> 128
    size_t cycles = 128 / (sizeof(unsigned int) * CHAR_BIT);

    for (i = an; i-- > cycles;) {
      acc += __builtin_popcountl((as[i] | (i >= bn ? 0 : bs[i])) & (as[i-cycles] ^ (i-cycles >= bn ? 0 : bs[i-cycles])));
    }

    RB_GC_GUARD(a);
    RB_GC_GUARD(b);
    xfree(as);
    xfree(bs);

    return INT2FIX(acc);
}

void Init_idhash() {
    VALUE m = rb_define_module("DHashVips");
    VALUE mm = rb_define_module_under(m, "IDHash");
    rb_define_module_function(mm, "distance3_c", idhash_distance, 2);
}
