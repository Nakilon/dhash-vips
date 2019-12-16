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

void Init_idhash() {
  VALUE m = rb_define_module("DHashVips");
  VALUE mm = rb_define_module_under(m, "IDHash");
  rb_define_module_function(mm, "distance3_c", idhash_distance, 2);
}
