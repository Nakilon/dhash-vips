// #include <ruby.h>
#include <bignum.c>

static VALUE idhash_distance(VALUE self, VALUE a, VALUE b){
    BDIGIT* tempd;
    long i, an = BIGNUM_LEN(a), bn = BIGNUM_LEN(b), templ, acc = 0;
    BDIGIT* as = BDIGITS(a);
    BDIGIT* bs = BDIGITS(b);
    while (0 < an && as[an-1] == 0) an--; // for (i = an; --i;) printf("%u\n", as[i]);
    while (0 < bn && bs[bn-1] == 0) bn--; // for (i = bn; --i;) printf("%u\n", bs[i]);
    // printf("%lu %lu\n", an, bn);
    if (an < bn) {
      tempd = as; as = bs; bs = tempd;
      templ = an; an = bn; bn = templ;
    }
    for (i = an; i-- > 4;) {
      // printf("%ld : (%u | %u) & (%u ^ %u)\n", i, as[i], (i >= bn ? 0 : bs[i]), as[i-4], bs[i-4]);
      acc += __builtin_popcountl((as[i] | (i >= bn ? 0 : bs[i])) & (as[i-4] ^ bs[i-4]));
      // printf("%ld : %ld\n", i, acc);
    }
    RB_GC_GUARD(a);
    RB_GC_GUARD(b);
    return INT2FIX(acc);
}

  // return a;
  // return rb_big_and(a, b);
  // return idhash_and(a, b);
  // return idhash_or(a, b);
  // return idhash_xor(a, b);
  // return idhash_popcount(self, a);
  // return rb_big_xor(a, b);
  // return rb_big_and(a, rb_big_xor(a, b));
  // return rb_big_and(rb_big_xor(a, b), b);
  // return rb_big_and(b, rb_big_xor(a, b));
  // return rb_big_and(rb_big_xor(a, b), rb_big_xor(a, b));
  // return rb_big_and(rb_big_xor(a, b), rb_big_rshift(rb_big_or(a, b), LONG2FIX(128L)));
  // return rb_big_xor(a, b), rb_big_rshift(rb_big_or(a, b), LONG2FIX(128L));
  // return rb_big_and(rb_big_xor(a, b), rb_big_rshift(rb_big_or(a, b), LONG2FIX(128L)));
  // return idhash_and(idhash_xor(a, b), idhash_rshift(idhash_or(a, b), LONG2FIX(128L)));
  // return idhash_popcount(self, idhash_and(idhash_xor(a, b), idhash_rshift(idhash_or(a, b), LONG2FIX(128L))));

void Init_idhash() {
  VALUE m = rb_define_module("DHashVips");
  VALUE mm = rb_define_module_under(m, "IDHash");
  rb_define_module_function(mm, "distance3_c", idhash_distance, 2);
}
