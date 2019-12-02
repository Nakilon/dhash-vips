// $ bundle exec ruby extconf.rb && rm -f idhashdist.o && make && ruby ./temp.rb

// (byebug) hashes[0]
// 27362028616592833077810614538336061650596602259623245623188871925927275101952
// (byebug) hashes[1]
// 57097733966917585112089915289446881218887831888508524872740133297073405558528
// (byebug) DHashVips::IDHash.distance hashes[0], hashes[1]
// 17

// #include <ruby.h>
// #include <bignum.c>

#include <internal.h>
#define BDIGITS(x) (BIGNUM_DIGITS(x))
#define BARY_TRUNC(ds, n) do { \
        while (0 < (n) && (ds)[(n)-1] == 0) \
            (n)--; \
    } while (0)
#define BIGNUM_SET_LEN(b,l) \
    ((RBASIC(b)->flags & BIGNUM_EMBED_FLAG) ? \
     (void)(RBASIC(b)->flags = \
      (RBASIC(b)->flags & ~BIGNUM_EMBED_LEN_MASK) | \
      ((l) << BIGNUM_EMBED_LEN_SHIFT)) : \
     (void)(RBIGNUM(b)->as.heap.len = (l)))
static VALUE bignew_1(VALUE klass, size_t len, int sign)
{
    NEWOBJ_OF(big, struct RBignum, klass, T_BIGNUM | (RGENGC_WB_PROTECTED_BIGNUM ? FL_WB_PROTECTED : 0));
    BIGNUM_SET_SIGN(big, sign?1:0);
    if (len <= BIGNUM_EMBED_LEN_MAX) {
        RBASIC(big)->flags |= BIGNUM_EMBED_FLAG;
        BIGNUM_SET_LEN(big, len);
        (void)VALGRIND_MAKE_MEM_UNDEFINED((void*)RBIGNUM(big)->as.ary, sizeof(RBIGNUM(big)->as.ary));
    }
    else {
        RBIGNUM(big)->as.heap.digits = ALLOC_N(BDIGIT, len);
        RBIGNUM(big)->as.heap.len = len;
    }
    OBJ_FREEZE(big);
    return (VALUE)big;
}
#define BITSPERDIG (SIZEOF_BDIGIT*CHAR_BIT)
#define BIGRAD ((BDIGIT_DBL)1 << BITSPERDIG)
#define BDIGMAX ((BDIGIT)(BIGRAD-1))
#define BIGLO(x) ((BDIGIT)((x) & BDIGMAX))
static int bary_2comp(BDIGIT *ds, size_t n)
{
    size_t i;
    i = 0;
    for (i = 0; i < n; i++) if (ds[i] != 0) goto non_zero;
    return 1;
  non_zero:
    ds[i] = BIGLO(~ds[i] + 1);
    i++;
    for (; i < n; i++) ds[i] = BIGLO(~ds[i]);
    return 0;
}
static BDIGIT abs2twocomp(VALUE *xp, long *n_ret)
{
    VALUE x = *xp;
    long n = BIGNUM_LEN(x);
    BDIGIT *ds = BDIGITS(x);
    BDIGIT hibits = 0;
    BARY_TRUNC(ds, n);
    if (n != 0 && BIGNUM_NEGATIVE_P(x)) {
        VALUE z = bignew_1(CLASS_OF(x), n, 0);
        MEMCPY(BDIGITS(z), ds, BDIGIT, n);
        bary_2comp(BDIGITS(z), n);
        hibits = BDIGMAX;
        *xp = z;
    }
    *n_ret = n;
    return hibits;
}
#define bignew(len,sign) bignew_1(rb_cBignum,(len),(sign))
static void twocomp2abs_bang(VALUE x, int hibits)
{
    BIGNUM_SET_SIGN(x, !hibits);
    if (hibits) rb_raise(rb_eRuntimeError, "twocomp2abs_bang");//get2comp(x);
}
#define LSHIFTABLE(d, n) ((n) < sizeof(d) * CHAR_BIT)
#define LSHIFTX(d, n) (!LSHIFTABLE(d, n) ? 0 : ((d) << (!LSHIFTABLE(d, n) ? 0 : (n))))
#define BIGUP(x) LSHIFTX(((x) + (BDIGIT_DBL)0), BITSPERDIG)
static inline VALUE bigfixize(VALUE x)
{
    size_t n = BIGNUM_LEN(x);
    BDIGIT *ds = BDIGITS(x);
#if SIZEOF_BDIGIT < SIZEOF_LONG
    unsigned long u;
#else
    BDIGIT u;
#endif
    BARY_TRUNC(ds, n);
    if (n == 0) return INT2FIX(0);
#if SIZEOF_BDIGIT < SIZEOF_LONG
    if (sizeof(long)/SIZEOF_BDIGIT < n)
        goto return_big;
    else {
        int i = (int)n;
        u = 0;
        while (i--) u = (unsigned long)(BIGUP(u) + ds[i]);
    }
#else /* SIZEOF_BDIGIT >= SIZEOF_LONG */
    if (1 < n)
        goto return_big;
    else
        u = ds[0];
#endif
    if (BIGNUM_POSITIVE_P(x))
        if (POSFIXABLE(u)) return LONG2FIX((long)u);
    else
        if (u <= -FIXNUM_MIN) return LONG2FIX(-(long)u);
  return_big:
    rb_big_resize(x, n);
    return x;
}
#define RB_BIGNUM_TYPE_P(x) RB_TYPE_P((x), T_BIGNUM)
static VALUE bignorm(VALUE x)
{
    if (RB_BIGNUM_TYPE_P(x)) x = bigfixize(x);
    return x;
}
VALUE idhash_and(VALUE x, VALUE y)
{
    VALUE z;
    BDIGIT *ds1, *ds2, *zds;
    long i, xn, yn, n1, n2;
    BDIGIT hibitsx, hibitsy;
    BDIGIT hibits1, hibits2;
    VALUE tmpv;
    BDIGIT tmph;
    long tmpn;
    if (!FIXNUM_P(y) && !RB_BIGNUM_TYPE_P(y)) return rb_num_coerce_bit(x, y, '&');
    hibitsx = abs2twocomp(&x, &xn);
    if (FIXNUM_P(y)) rb_raise(rb_eRuntimeError, "idhash_and"); //return bigand_int(x, xn, hibitsx, FIX2LONG(y));
    hibitsy = abs2twocomp(&y, &yn);
    if (xn > yn) {
        tmpv = x; x = y; y = tmpv;
        tmpn = xn; xn = yn; yn = tmpn;
        tmph = hibitsx; hibitsx = hibitsy; hibitsy = tmph;
    }
    n1 = xn;
    n2 = yn;
    ds1 = BDIGITS(x);
    ds2 = BDIGITS(y);
    hibits1 = hibitsx;
    hibits2 = hibitsy;
    if (!hibits1) n2 = n1;
    z = bignew(n2, 0);
    zds = BDIGITS(z);
    for (i=0; i<n1; i++) zds[i] = ds1[i] & ds2[i];
    for (   ; i<n2; i++) zds[i] = hibits1 & ds2[i];
    twocomp2abs_bang(z, hibits1 && hibits2);
    RB_GC_GUARD(x);
    RB_GC_GUARD(y);
    return bignorm(z);
}
VALUE idhash_or(VALUE x, VALUE y)
{
    VALUE z;
    BDIGIT *ds1, *ds2, *zds;
    long i, xn, yn, n1, n2;
    BDIGIT hibitsx, hibitsy;
    BDIGIT hibits1, hibits2;
    VALUE tmpv;
    BDIGIT tmph;
    long tmpn;
    if (!FIXNUM_P(y) && !RB_BIGNUM_TYPE_P(y)) return rb_num_coerce_bit(x, y, '|');
    hibitsx = abs2twocomp(&x, &xn);
    if (FIXNUM_P(y)) rb_raise(rb_eRuntimeError, "idhash_or"); //return bigor_int(x, xn, hibitsx, FIX2LONG(y));
    hibitsy = abs2twocomp(&y, &yn);
    if (xn > yn) {
        tmpv = x; x = y; y = tmpv;
        tmpn = xn; xn = yn; yn = tmpn;
        tmph = hibitsx; hibitsx = hibitsy; hibitsy = tmph;
    }
    n1 = xn;
    n2 = yn;
    ds1 = BDIGITS(x);
    ds2 = BDIGITS(y);
    hibits1 = hibitsx;
    hibits2 = hibitsy;
    if (hibits1) n2 = n1;
    z = bignew(n2, 0);
    zds = BDIGITS(z);
    for (i=0; i<n1; i++) zds[i] = ds1[i] | ds2[i];
    for (   ; i<n2; i++) zds[i] = hibits1 | ds2[i];
    twocomp2abs_bang(z, hibits1 || hibits2);
    RB_GC_GUARD(x);
    RB_GC_GUARD(y);
    return bignorm(z);
}
VALUE idhash_xor(VALUE x, VALUE y)
{
    VALUE z;
    BDIGIT *ds1, *ds2, *zds;
    long i, xn, yn, n1, n2;
    BDIGIT hibitsx, hibitsy;
    BDIGIT hibits1, hibits2;
    VALUE tmpv;
    BDIGIT tmph;
    long tmpn;
    if (!FIXNUM_P(y) && !RB_BIGNUM_TYPE_P(y)) return rb_num_coerce_bit(x, y, '^');
    hibitsx = abs2twocomp(&x, &xn);
    if (FIXNUM_P(y)) rb_raise(rb_eRuntimeError, "idhash_xor"); // return bigxor_int(x, xn, hibitsx, FIX2LONG(y));
    hibitsy = abs2twocomp(&y, &yn);
    if (xn > yn) {
        tmpv = x; x = y; y = tmpv;
        tmpn = xn; xn = yn; yn = tmpn;
        tmph = hibitsx; hibitsx = hibitsy; hibitsy = tmph;
    }
    n1 = xn;
    n2 = yn;
    ds1 = BDIGITS(x);
    ds2 = BDIGITS(y);
    hibits1 = hibitsx;
    hibits2 = hibitsy;
    z = bignew(n2, 0);
    zds = BDIGITS(z);
    for (i=0; i<n1; i++) zds[i] = ds1[i] ^ ds2[i];
    for (   ; i<n2; i++) zds[i] = hibitsx ^ ds2[i];
    twocomp2abs_bang(z, (hibits1 ^ hibits2) != 0);
    RB_GC_GUARD(x);
    RB_GC_GUARD(y);
    return bignorm(z);
}
static void bary_small_rshift(BDIGIT *zds, const BDIGIT *xds, size_t n, int shift, BDIGIT higher_bdigit)
{
    BDIGIT_DBL num = 0;
    BDIGIT x;
    // assert(0 <= shift && shift < BITSPERDIG);
    num = BIGUP(higher_bdigit);
    while (n--) {
        num = (num | xds[n]) >> shift;
        x = xds[n];
        zds[n] = BIGLO(num);
        num = BIGUP(x);
    }
}
static VALUE big_shift3(VALUE x, int lshift_p, size_t shift_numdigits, int shift_numbits)
{
    BDIGIT *xds, *zds;
    long s1;
    int s2;
    VALUE z;
    long xn;
    if (lshift_p) {
        rb_raise(rb_eRuntimeError, "big_shift3 1");
        /*
        if (LONG_MAX < shift_numdigits) rb_raise(rb_eArgError, "too big number");
        s1 = shift_numdigits;
        s2 = shift_numbits;
        xn = BIGNUM_LEN(x);
        z = bignew(xn+s1+1, BIGNUM_SIGN(x));
        zds = BDIGITS(z);
        BDIGITS_ZERO(zds, s1);
        xds = BDIGITS(x);
        zds[xn+s1] = bary_small_lshift(zds+s1, xds, xn, s2);
        */
    } else {
        long zn;
        BDIGIT hibitsx;
        if (LONG_MAX < shift_numdigits || (size_t)BIGNUM_LEN(x) <= shift_numdigits) {
            rb_raise(rb_eRuntimeError, "big_shift3 2");
            /*
            if (BIGNUM_POSITIVE_P(x) || bary_zero_p(BDIGITS(x), BIGNUM_LEN(x)))
                return INT2FIX(0);
            else
                return INT2FIX(-1);
            */
        }
        s1 = shift_numdigits;
        s2 = shift_numbits;
        hibitsx = abs2twocomp(&x, &xn);
        xds = BDIGITS(x);
        if (xn <= s1) return hibitsx ? INT2FIX(-1) : INT2FIX(0);
        zn = xn - s1;
        z = bignew(zn, 0);
        zds = BDIGITS(z);
        bary_small_rshift(zds, xds+s1, zn, s2, hibitsx != 0 ? BDIGMAX : 0);
        twocomp2abs_bang(z, hibitsx != 0);
    }
    RB_GC_GUARD(x);
    return z;
}
VALUE idhash_rshift(VALUE x, VALUE y)
{
    int lshift_p;
    size_t shift_numdigits;
    int shift_numbits;
    for (;;) {
        if (FIXNUM_P(y)) {
            long l = FIX2LONG(y);
            unsigned long shift;
            if (0 <= l) {
                lshift_p = 0;
                shift = l;
            }
            else {
                lshift_p = 1;
                shift = 1+(unsigned long)(-(l+1));
            }
            shift_numbits = (int)(shift & (BITSPERDIG-1));
            shift_numdigits = shift >> bit_length(BITSPERDIG-1);
            return bignorm(big_shift3(x, lshift_p, shift_numdigits, shift_numbits));
        }
        else if (RB_BIGNUM_TYPE_P(y)) rb_raise(rb_eRuntimeError, "idhash_rshift"); // return bignorm(big_shift2(x, 0, y));
        y = rb_to_int(y);
    }
}

static VALUE qweqwe(VALUE self, VALUE a, VALUE b) {
  // ((a ^ b) & (a | b) >> 128).to_s(2).count "1"

  // return INT2NUM(3);
  // int sum = 0;
  // for (int pos = RARRAY_LEN(arr1); pos--; ) {
  //   sum += fix_abs(rb_ary_entry(arr1, pos) -
  //                  rb_ary_entry(arr2, pos));
  // }
  // return INT2NUM(sum);

  // return a;
  // return rb_big_and(a, b);
  // return idhash_and(a, b);
  // return idhash_or(a, b);
  // return idhash_xor(a, b);
  // return idhash_popcount(self, a);
  // return rb_big_and(rb_big_xor(a, b), rb_big_rshift(rb_big_or(a, b), LONG2FIX(128L)));
  return idhash_and(idhash_xor(a, b), idhash_rshift(idhash_or(a, b), LONG2FIX(128L)));
  // return idhash_popcount(self, idhash_and(idhash_xor(a, b), idhash_rshift(idhash_or(a, b), LONG2FIX(128L))));
}

void Init_idhashdist() {
  rb_define_global_function("dist", qweqwe, 2);
}
