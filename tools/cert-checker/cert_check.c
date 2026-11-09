/*
 * cert_check.c -- integrity checker for ACL2 .cert files.
 *
 * What it checks (no proof is replayed, no ACL2 logic is evaluated):
 *   (1) the cert checksum: the last object of the .cert equals check-sum-obj
 *       of the cert contents (cmds, pre-alist, post-alist, expansion-alist,
 *       cert-data);
 *   (2) the source binding: the book-hash of the book's own entry (the first
 *       element of the post-alist) equals check-sum-obj of (cmds, expansion
 *       alist, the events read from the .lisp file, cert-data);
 *   (3) for each recorded book in the post-alist, the stored hash equals the
 *       own-entry hash of that book's .cert, and that book's .cert and .lisp
 *       pass checks (1) and (2). Only one level is read: the dependencies of
 *       the dependencies are not followed.
 *
 * Code paths are cited from the ACL2 8.7 source tree (acl2-8.7/, file names below):
 *   serialize-raw.lisp   ser-decode-from-stream (:1518), ser-decode-str (:591),
 *                        ser-decode-and-load-package (:795),
 *                        ser-decode-loop (:1233), ser-decode-and-restore-fals
 *                        (:1385), ser-decode-nat (:494), ser-decode-rat (:526),
 *                        ser-decode-magic (:329), file format essay (:95-170).
 *   acl2-fns.lisp        ser-hons-reader-macro (:2046): #Z uses hons-mode :smart.
 *   basis-b.lisp         fchecksum-obj (:2033), fchecksum-atom (~:1950),
 *                        fchecksum-string1 (:1805), fchecksum-string (:1874),
 *                        fchecksum-natural (:1749,:1800), times-mod-m31 (:1679),
 *                        check-sum-obj (:2074).
 *   other-events.lisp    make-certificate-file1 (:12886): file layout,
 *                        cert-hash (:11403), book-hash (:13436),
 *                        book-hash-alist (:13421), read-object-file (:13123),
 *                        chk-in-package (:10576), include-book-ok-familiar-
 *                        name-and-hash (:13821, compares the stored own-entry
 *                        hash with the one recomputed from the source).
 *   axioms.lisp          *common-lisp-symbols-from-main-lisp-package* (:93),
 *                        transcribed into cl_symbols.h.
 *
 * Portable C99. No libc is used in the core, so it compiles for wasm32 without
 * a C library. The host supplies file bytes through host_read_file.
 */
#include <stdint.h>

#include "cl_symbols.h"

/* ------------------------------------------------------------------ */
/* Host interface and static storage                                   */
/* ------------------------------------------------------------------ */

#define FILE_CAP   (4u * 1024u * 1024u)
#define ARENA_CAP  (32u * 1024u * 1024u)
#define OUT_CAP    (64u * 1024u)
#define PATH_CAP   1024
#define INT64_MAX_LOCAL ((uint64_t)0x7fffffffffffffffULL)
#define UINT64_MAX_LOCAL ((uint64_t)0xffffffffffffffffULL)

/* host_read_file(path, path_len, dst, cap): returns the byte count, or -1.
 * The wasm build imports it from module "env"; the native build defines it. */
#ifdef CC_WASM
__attribute__((import_module("env"), import_name("host_read_file")))
#endif
int32_t host_read_file(const uint8_t *path, uint32_t path_len, uint8_t *dst,
                       uint32_t cap);

/* host_file_info(path, path_len, out): out[0] is the byte size and out[1] the
 * write date as universal time (seconds since 1900, ACL2 file-write-date$).
 * Returns 0 on success and -1 when the file is missing. */
#ifdef CC_WASM
__attribute__((import_module("env"), import_name("host_file_info")))
#endif
int32_t host_file_info(const uint8_t *path, uint32_t path_len, int64_t *out);

static void memset_local(void *p, uint32_t n);

static uint8_t cert_buf[FILE_CAP];
static uint8_t lisp_buf[FILE_CAP];
static uint8_t dep_cert_buf[FILE_CAP];
static uint8_t dep_lisp_buf[FILE_CAP];
static uint8_t arena[ARENA_CAP] __attribute__((aligned(16)));
static uint32_t arena_used;
static char out_buf[OUT_CAP];
static uint32_t out_len;

#ifdef CC_WASM
/* The core is libc-free for wasm, so memcpy and memset are provided here. */
void *memcpy(void *d, const void *s, unsigned long n) {
  uint8_t *dd = (uint8_t *)d;
  const uint8_t *ss = (const uint8_t *)s;
  for (unsigned long i = 0; i < n; i++) dd[i] = ss[i];
  return d;
}
void *memset(void *d, int c, unsigned long n) {
  uint8_t *dd = (uint8_t *)d;
  for (unsigned long i = 0; i < n; i++) dd[i] = (uint8_t)c;
  return d;
}
#endif

uint8_t *cc_cert_buf(void) { return cert_buf; }
uint8_t *cc_lisp_buf(void) { return lisp_buf; }
uint32_t cc_cert_cap(void) { return FILE_CAP; }
uint32_t cc_lisp_cap(void) { return FILE_CAP; }
char *cc_out_buf(void) { return out_buf; }
uint32_t cc_out_cap(void) { return OUT_CAP; }

/* ------------------------------------------------------------------ */
/* Small helpers (no libc)                                             */
/* ------------------------------------------------------------------ */

static void *arena_alloc(uint32_t n) {
  uint32_t aligned = (arena_used + 7u) & ~7u;
  if (aligned > ARENA_CAP || n > ARENA_CAP - aligned) return 0;
  arena_used = aligned + n;
  return &arena[aligned];
}

static uint32_t slen(const char *s) {
  uint32_t n = 0;
  while (s[n]) n++;
  return n;
}

static int meq(const uint8_t *a, uint32_t an, const char *b) {
  uint32_t bn = slen(b);
  if (an != bn) return 0;
  for (uint32_t i = 0; i < an; i++)
    if (a[i] != (uint8_t)b[i]) return 0;
  return 1;
}

static void out_put(const char *s) {
  while (*s && out_len + 1 < OUT_CAP) out_buf[out_len++] = *s++;
  out_buf[out_len] = 0;
}

static void out_putn(const uint8_t *s, uint32_t n) {
  for (uint32_t i = 0; i < n && out_len + 1 < OUT_CAP; i++)
    out_buf[out_len++] = (char)s[i];
  out_buf[out_len] = 0;
}

static void out_i64(int64_t v) {
  char tmp[24];
  int k = 0;
  uint64_t u;
  if (v < 0) {
    out_put("-");
    u = (uint64_t)(-(v + 1)) + 1u;
  } else {
    u = (uint64_t)v;
  }
  do {
    tmp[k++] = (char)('0' + (u % 10));
    u /= 10;
  } while (u);
  while (k) {
    char c[2];
    c[0] = tmp[--k];
    c[1] = 0;
    out_put(c);
  }
}

/* Error state: the first error message wins. */
static char err_msg[256];
static int err_set;

static void set_err(const char *msg) {
  if (!err_set) {
    uint32_t i = 0;
    while (msg[i] && i + 1 < sizeof err_msg) {
      err_msg[i] = msg[i];
      i++;
    }
    err_msg[i] = 0;
    err_set = 1;
  }
}

/* ------------------------------------------------------------------ */
/* Lisp objects                                                        */
/* ------------------------------------------------------------------ */

enum { T_INT, T_RAT, T_CHAR, T_STR, T_SYM, T_CONS };

typedef struct Obj {
  uint8_t tag;
  int64_t num;             /* T_INT value, T_RAT numerator, T_CHAR code */
  uint64_t den;            /* T_RAT denominator (> 1) */
  const uint8_t *p1;       /* T_STR bytes, T_SYM package name */
  uint32_t n1;
  const uint8_t *p2;       /* T_SYM symbol name */
  uint32_t n2;
  struct Obj *car;
  struct Obj *cdr;
} Obj;

static Obj *new_obj(uint8_t tag) {
  Obj *o = (Obj *)arena_alloc((uint32_t)sizeof(Obj));
  if (!o) {
    set_err("arena exhausted");
    return 0;
  }
  o->tag = tag;
  o->num = 0;
  o->den = 1;
  o->p1 = 0;
  o->n1 = 0;
  o->p2 = 0;
  o->n2 = 0;
  o->car = 0;
  o->cdr = 0;
  return o;
}

static Obj *mk_int(int64_t v) {
  Obj *o = new_obj(T_INT);
  if (o) o->num = v;
  return o;
}

static Obj *mk_cons(Obj *a, Obj *d) {
  Obj *o = new_obj(T_CONS);
  if (o) {
    o->car = a;
    o->cdr = d;
  }
  return o;
}

static Obj *mk_sym(const uint8_t *pkg, uint32_t pn, const uint8_t *name,
                   uint32_t nn) {
  Obj *o = new_obj(T_SYM);
  if (o) {
    o->p1 = pkg;
    o->n1 = pn;
    o->p2 = name;
    o->n2 = nn;
  }
  return o;
}

static Obj *mk_str(const uint8_t *p, uint32_t n) {
  Obj *o = new_obj(T_STR);
  if (o) {
    o->p1 = p;
    o->n1 = n;
  }
  return o;
}

static int is_sym(const Obj *o, const char *pkg, const char *name) {
  return o && o->tag == T_SYM && meq(o->p1, o->n1, pkg) &&
         meq(o->p2, o->n2, name);
}

static int is_nil(const Obj *o) { return is_sym(o, "COMMON-LISP", "NIL"); }

static int is_kw(const Obj *o, const char *name) {
  return is_sym(o, "KEYWORD", name);
}

static int is_str_eq(const Obj *o, const char *s) {
  return o && o->tag == T_STR && meq(o->p1, o->n1, s);
}

static Obj *car_of(const Obj *o) {
  if (!o || o->tag != T_CONS) return 0;
  return o->car;
}

static Obj *cdr_of(const Obj *o) {
  if (!o || o->tag != T_CONS) return 0;
  return o->cdr;
}

static int is_cons(const Obj *o) { return o && o->tag == T_CONS; }

/* Nil is the symbol COMMON-LISP::NIL, so the cdr of a list is nil. */
static Obj *mk_nil(void) { return mk_sym((const uint8_t *)"COMMON-LISP", 11,
                                        (const uint8_t *)"NIL", 3); }

/* ------------------------------------------------------------------ */
/* Checksums (basis-b.lisp)                                            */
/* ------------------------------------------------------------------ */

/* times-mod-m31 (basis-b.lisp:1679), non-GCL branch: (rem (* u v) #x7fffffff). */
static int32_t times_m31(int64_t u, int64_t v) {
  return (int32_t)((u * v) % 0x7fffffffLL);
}

/* fchecksum-natural (basis-b.lisp:1800) and -aux (basis-b.lisp:1749). */
static int32_t cs_natural(uint64_t n) {
  int32_t ans = 28371987;
  while (n != 0) {
    ans ^= times_m31((int64_t)(n & 0x7FFFFFFFu), 392894102);
    n >>= 31;
  }
  return ans;
}

/* fchecksum-atom on an integer (basis-b.lisp, the natp and integerp branches). */
static int32_t cs_integer(int64_t x) {
  if (x >= 0) return cs_natural((uint64_t)x);
  return times_m31((int64_t)cs_natural((uint64_t)(-x)), 283748912);
}

/*
 * fchecksum-string (basis-b.lisp:1874) with fchecksum-string1 (basis-b.lisp:1805).
 * The recursion of fchecksum-string1 advances the index by 3, not 4, because
 * the three (ash ...) bindings i:=i+1 are not undone before the recursive call.
 */
static int32_t cs_string(const uint8_t *p, uint32_t n) {
  int32_t ans;
  uint32_t i = 0;
  if (n >= 2147483647u) {
    set_err("string too long for checksum");
    return 0;
  }
  ans = times_m31((int64_t)n + 1, 718273893);
  while (i < n) {
    int64_t c0 = p[i] & 0x7F;
    int64_t c1 = (i + 1 < n) ? p[i + 1] : 0;
    int64_t c2 = (i + 2 < n) ? p[i + 2] : 0;
    int64_t c3 = (i + 3 < n) ? p[i + 3] : 0;
    int64_t bits = (c0 << 24) | (c1 << 16) | (c2 << 8) | c3;
    ans ^= times_m31(bits, 506249751);
    i += 3;
  }
  return ans;
}

/* fchecksum-atom (basis-b.lisp, after fchecksum-natural). */
static int32_t cs_atom(const Obj *x) {
  switch (x->tag) {
  case T_INT:
    return cs_integer(x->num);
  case T_SYM: {
    int32_t pc = cs_string(x->p1, x->n1);
    int32_t sc = cs_string(x->p2, x->n2);
    return times_m31(pc, 938187814) ^ sc;
  }
  case T_STR:
    return cs_string(x->p1, x->n1);
  case T_CHAR:
    return times_m31(x->num, 619823821);
  case T_RAT: {
    int32_t num_code = cs_integer(x->num);
    int32_t den_code = cs_natural(x->den);
    return times_m31(num_code, 111298397) ^ times_m31(den_code, 391892127);
  }
  default:
    set_err("internal: atom expected");
    return 0;
  }
}

/*
 * fchecksum-obj (basis-b.lisp:2033). The cdr recursion is unrolled: the cars
 * are coded recursively, then the spine is folded from its last cell.
 */
static int32_t cs_obj(const Obj *x) {
  const Obj *cell = x;
  uint32_t m = 0;
  int32_t *car_codes;
  int32_t code;
  uint32_t k;
  if (!x || x->tag != T_CONS) return x ? cs_atom(x) : 0;
  while (cell && cell->tag == T_CONS) {
    m++;
    cell = cell->cdr;
  }
  car_codes = (int32_t *)arena_alloc(m * (uint32_t)sizeof(int32_t));
  if (!car_codes) {
    set_err("arena exhausted (checksum)");
    return 0;
  }
  cell = x;
  for (k = 0; k < m; k++) {
    car_codes[k] = cs_obj(cell->car);
    cell = cell->cdr;
  }
  code = cs_obj(cell); /* the atom at the end of the spine, normally nil */
  for (k = m; k > 0; k--) {
    code = times_m31(car_codes[k - 1], 627718124) ^
           times_m31(code, 278917287);
  }
  return code;
}

/* ------------------------------------------------------------------ */
/* Serialized object decoder (serialize-raw.lisp, format V3)           */
/* ------------------------------------------------------------------ */

typedef struct {
  const uint8_t *b;
  uint32_t n;
  uint32_t pos;
} Bytes;

static int bget(Bytes *s, uint8_t *c) {
  if (s->pos >= s->n) {
    set_err("unexpected end of serialized data");
    return 0;
  }
  *c = s->b[s->pos++];
  return 1;
}

/* ser-decode-nat (serialize-raw.lisp:494): little-endian base 128, MSB continues. */
static int dec_nat(Bytes *s, uint64_t *out) {
  uint64_t value = 0;
  uint32_t shift = 0;
  for (;;) {
    uint8_t c;
    if (!bget(s, &c)) return 0;
    if (shift >= 64) {
      set_err("natural number too large");
      return 0;
    }
    value |= ((uint64_t)(c & 0x7F)) << shift;
    if (c < 128) break;
    shift += 7;
  }
  *out = value;
  return 1;
}

/* ser-decode-str (serialize-raw.lisp:591) with V3 header (len << 1) | normed. */
static int dec_str(Bytes *s, const uint8_t **p, uint32_t *n) {
  uint64_t header, len;
  if (!dec_nat(s, &header)) return 0;
  len = header >> 1;
  if (len > (uint64_t)(s->n - s->pos)) {
    set_err("serialized string runs past the end of the data");
    return 0;
  }
  *p = s->b + s->pos;
  *n = (uint32_t)len;
  s->pos += (uint32_t)len;
  return 1;
}

static int dec_magic(Bytes *s, int *version) {
  uint8_t m[4];
  for (int i = 0; i < 4; i++)
    if (!bget(s, &m[i])) return 0;
  if (m[0] != 0xAC || m[1] != 0x12 || m[2] != 0x0B) {
    set_err("serialized object has a bad magic number");
    return 0;
  }
  if (m[3] == 0xC9) {
    *version = 3;
    return 1;
  }
  set_err("serialized object is not format V3 (unsupported version)");
  return 0;
}

static int64_t rat_to_int(int sign, uint64_t num, uint64_t den, Obj **out) {
  Obj *o;
  if (den == 0) {
    set_err("serialized rational has zero denominator");
    return 0;
  }
  if (num > (uint64_t)INT64_MAX_LOCAL) {
    set_err("serialized rational numerator exceeds 63 bits");
    return 0;
  }
  if (den == 1) {
    int64_t v = (int64_t)num;
    o = mk_int(sign ? -v : v);
  } else {
    o = new_obj(T_RAT);
    if (o) {
      o->num = sign ? -(int64_t)num : (int64_t)num;
      o->den = den;
    }
  }
  *out = o;
  return o != 0;
}

/*
 * ser-decode-from-stream (serialize-raw.lisp:1518) for V3, with hons-mode
 * :smart as used by the #Z reader (acl2-fns.lisp:2046). Returns the top object.
 */
static Obj *dec_object(Bytes *s) {
  int version = 0;
  uint64_t size_idx, arr_size, free_idx, len, i;
  Obj **arr;
  Obj *nil_obj, *t_obj;
  if (!dec_magic(s, &version)) return 0;
  if (!dec_nat(s, &size_idx)) return 0;
  arr_size = (size_idx == 0) ? 2 : size_idx + 1;
  if (arr_size > (uint64_t)(ARENA_CAP / sizeof(Obj *))) {
    set_err("serialized object too large");
    return 0;
  }
  arr = (Obj **)arena_alloc((uint32_t)(arr_size * sizeof(Obj *)));
  if (!arr) {
    set_err("arena exhausted (decoder)");
    return 0;
  }
  nil_obj = mk_nil();
  t_obj = mk_sym((const uint8_t *)"COMMON-LISP", 11, (const uint8_t *)"T", 1);
  if (!nil_obj || !t_obj) return 0;
  arr[0] = nil_obj;
  arr[1] = t_obj;
  free_idx = 2;

  /* NATS (serialize-raw.lisp:648) */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    uint64_t v;
    Obj *o;
    if (free_idx >= arr_size) { set_err("too many naturals"); return 0; }
    if (!dec_nat(s, &v)) return 0;
    if (v > (uint64_t)INT64_MAX_LOCAL) { set_err("natural exceeds 63 bits"); return 0; }
    o = mk_int((int64_t)v);
    if (!o) return 0;
    arr[free_idx++] = o;
  }

  /* RATS (serialize-raw.lisp:673) */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    uint64_t sign, num, den;
    Obj *o;
    if (free_idx >= arr_size) { set_err("too many rationals"); return 0; }
    if (!dec_nat(s, &sign) || !dec_nat(s, &num) || !dec_nat(s, &den)) return 0;
    if (sign > 1) { set_err("bad rational sign"); return 0; }
    if (!rat_to_int((int)sign, num, den, &o)) return 0;
    arr[free_idx++] = o;
  }

  /* COMPLEXES (serialize-raw.lisp:697): not supported by this checker. */
  if (!dec_nat(s, &len)) return 0;
  if (len != 0) {
    set_err("cert contains complex numbers (not supported by this checker)");
    return 0;
  }

  /* CHARS (serialize-raw.lisp:721) */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    uint8_t c;
    Obj *o;
    if (free_idx >= arr_size) { set_err("too many characters"); return 0; }
    if (!bget(s, &c)) return 0;
    o = new_obj(T_CHAR);
    if (!o) return 0;
    o->num = c;
    arr[free_idx++] = o;
  }

  /* STRS (serialize-raw.lisp:745) */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    const uint8_t *p;
    uint32_t n;
    Obj *o;
    if (free_idx >= arr_size) { set_err("too many strings"); return 0; }
    if (!dec_str(s, &p, &n)) return 0;
    o = mk_str(p, n);
    if (!o) return 0;
    arr[free_idx++] = o;
  }

  /* PACKAGES (serialize-raw.lisp:840, 795): each package then its symbols. */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    const uint8_t *pp;
    uint32_t pn;
    uint64_t count, j;
    if (!dec_str(s, &pp, &pn)) return 0;
    if (!dec_nat(s, &count)) return 0;
    for (j = 0; j < count; j++) {
      const uint8_t *np;
      uint32_t nn;
      Obj *o;
      if (free_idx >= arr_size) { set_err("too many symbols"); return 0; }
      if (!dec_str(s, &np, &nn)) return 0;
      o = mk_sym(pp, pn, np, nn);
      if (!o) return 0;
      arr[free_idx++] = o;
    }
  }

  /* CONSES (serialize-raw.lisp:1233 ser-decode-loop, V2/V3 encoding). */
  if (!dec_nat(s, &len)) return 0;
  for (i = 0; i < len; i++) {
    uint64_t first, cdr_idx, car_idx;
    Obj *o;
    if (free_idx >= arr_size) { set_err("too many conses"); return 0; }
    if (!dec_nat(s, &first) || !dec_nat(s, &cdr_idx)) return 0;
    car_idx = first >> 1; /* the low bit is the honsp flag, ignored here */
    if (car_idx >= free_idx || cdr_idx >= free_idx) {
      set_err("cons index out of bounds");
      return 0;
    }
    o = mk_cons(arr[car_idx], arr[cdr_idx]);
    if (!o) return 0;
    arr[free_idx++] = o;
  }

  /* FALS (serialize-raw.lisp:1385): index, count pairs, zero terminated.
     With hons-mode :smart (#Z) the count is read. Fast alists are not
     restored: they are ordinary alists for the checksum. */
  {
    uint64_t idx;
    if (!dec_nat(s, &idx)) return 0;
    while (idx != 0) {
      uint64_t cnt;
      if (idx >= arr_size) { set_err("FAL index too large"); return 0; }
      if (!dec_nat(s, &cnt)) return 0;
      if (!dec_nat(s, &idx)) return 0;
    }
  }

  if (!dec_magic(s, &version)) return 0;
  if (free_idx != arr_size) {
    set_err("serialized object size mismatch");
    return 0;
  }
  return arr[size_idx];
}

/* ------------------------------------------------------------------ */
/* Source reader (ACL2 reader on the events of a .lisp file)           */
/* ------------------------------------------------------------------ */

typedef struct {
  const uint8_t *b;
  uint32_t n;
  uint32_t pos;
  uint32_t line;
} Src;

static int is_ws(uint8_t c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f';
}

static int is_delim(uint8_t c) {
  return is_ws(c) || c == '(' || c == ')' || c == '"' || c == '\'' ||
         c == ';' || c == '`' || c == ',';
}

/* Skips whitespace, ; comments and nested #| |# comments. */
static int src_skip(Src *r) {
  for (;;) {
    if (r->pos >= r->n) return 1;
    uint8_t c = r->b[r->pos];
    if (c == '\n') {
      r->line++;
      r->pos++;
    } else if (is_ws(c)) {
      r->pos++;
    } else if (c == ';') {
      while (r->pos < r->n && r->b[r->pos] != '\n') r->pos++;
    } else if (c == '#' && r->pos + 1 < r->n && r->b[r->pos + 1] == '|') {
      uint32_t depth = 1;
      r->pos += 2;
      while (depth > 0) {
        if (r->pos + 1 >= r->n) {
          set_err("unterminated #| comment in the source");
          return 0;
        }
        if (r->b[r->pos] == '|' && r->b[r->pos + 1] == '#') {
          depth--;
          r->pos += 2;
        } else if (r->b[r->pos] == '#' && r->b[r->pos + 1] == '|') {
          depth++;
          r->pos += 2;
        } else {
          if (r->b[r->pos] == '\n') r->line++;
          r->pos++;
        }
      }
    } else {
      return 1;
    }
  }
}

/* Name used for a symbol read in package ACL2 that is not imported from CL. */
static int in_cl_list(const uint8_t *name, uint32_t n) {
  for (int i = 0; i < CL_SYMBOLS_COUNT; i++) {
    const char *s = CL_SYMBOLS[i];
    uint32_t k = 0;
    while (s[k] && k < n && (uint8_t)s[k] == name[k]) k++;
    if (k == n && s[k] == 0) return 1;
  }
  return 0;
}

/*
 * Resolves a symbol read in the ACL2 reader. Unqualified and ACL2-qualified
 * symbols whose name is in the CL import list belong to COMMON-LISP, the
 * others to ACL2 (axioms.lisp:93 and acl2.lisp, import into "ACL2").
 */
static Obj *resolve_sym(const uint8_t *pkg, uint32_t pn, const uint8_t *name,
                        uint32_t nn) {
  static const uint8_t kw[] = "KEYWORD";
  static const uint8_t acl2[] = "ACL2";
  static const uint8_t cl[] = "COMMON-LISP";
  if (pn == 0 || meq(pkg, pn, "ACL2")) {
    if (in_cl_list(name, nn)) return mk_sym(cl, 11, name, nn);
    return mk_sym(acl2, 4, name, nn);
  }
  if (meq(pkg, pn, "COMMON-LISP")) {
    if (in_cl_list(name, nn)) return mk_sym(cl, 11, name, nn);
    set_err("source uses a COMMON-LISP symbol that is not in the CL list");
    return 0;
  }
  if (meq(pkg, pn, "KEYWORD")) return mk_sym(kw, 7, name, nn);
  set_err("source uses a package other than ACL2, COMMON-LISP or KEYWORD (not supported)");
  return 0;
}

static Obj *src_datum(Src *r);

static Obj *src_list(Src *r) {
  Obj *head = 0, *tail = 0;
  r->pos++; /* ( */
  if (!src_skip(r)) return 0;
  if (r->pos < r->n && r->b[r->pos] == ')') {
    r->pos++;
    return mk_nil();
  }
  for (;;) {
    Obj *item, *cell;
    if (!src_skip(r)) return 0;
    if (r->pos >= r->n) {
      set_err("unterminated list in the source");
      return 0;
    }
    if (r->b[r->pos] == ')') {
      r->pos++;
      break;
    }
    if (r->b[r->pos] == '.' && r->pos + 1 < r->n && is_delim(r->b[r->pos + 1])) {
      Obj *rest;
      r->pos++;
      rest = src_datum(r);
      if (!rest) return 0;
      if (!tail) {
        set_err("dotted list with no elements");
        return 0;
      }
      tail->cdr = rest;
      if (!src_skip(r)) return 0;
      if (r->pos >= r->n || r->b[r->pos] != ')') {
        set_err("expected ) after dotted tail");
        return 0;
      }
      r->pos++;
      return head;
    }
    item = src_datum(r);
    if (!item) return 0;
    cell = mk_cons(item, 0);
    if (!cell) return 0;
    if (!head) head = cell;
    else tail->cdr = cell;
    tail = cell;
  }
  if (!tail) return mk_nil();
  tail->cdr = mk_nil();
  return head;
}

static Obj *src_string(Src *r) {
  uint32_t start, n = 0, i;
  uint8_t *buf;
  r->pos++; /* opening quote */
  start = r->pos;
  /* First pass: count bytes. */
  while (r->pos < r->n && r->b[r->pos] != '"') {
    if (r->b[r->pos] == '\\') r->pos++;
    if (r->pos < r->n && r->b[r->pos] == '\n') r->line++;
    r->pos++;
    n++;
  }
  if (r->pos >= r->n) {
    set_err("unterminated string in the source");
    return 0;
  }
  buf = (uint8_t *)arena_alloc(n + 1);
  if (!buf) {
    set_err("arena exhausted (source)");
    return 0;
  }
  i = 0;
  for (uint32_t p = start; p < r->pos; p++) {
    if (r->b[p] == '\\' && p + 1 < r->pos) {
      p++;
    }
    buf[i++] = r->b[p];
  }
  r->pos++; /* closing quote */
  return mk_str(buf, i);
}

/* Reads one token. Returns its length; escapes are reported in *escaped. */
static uint32_t src_token(Src *r, uint8_t *buf, uint32_t cap, int *escaped,
                          uint32_t *colon_at) {
  uint32_t k = 0;
  *escaped = 0;
  *colon_at = 0xFFFFFFFFu;
  while (r->pos < r->n) {
    uint8_t c = r->b[r->pos];
    if (c == '|') {
      *escaped = 1;
      r->pos++;
      while (r->pos < r->n && r->b[r->pos] != '|') {
        if (k < cap) buf[k++] = r->b[r->pos];
        r->pos++;
      }
      r->pos++;
      continue;
    }
    if (c == '\\') {
      *escaped = 1;
      r->pos++;
      if (r->pos < r->n && k < cap) buf[k++] = r->b[r->pos];
      r->pos++;
      continue;
    }
    if (is_delim(c)) break;
    if (c == ':' && *colon_at == 0xFFFFFFFFu) *colon_at = k;
    if (k < cap) {
      if (c >= 'a' && c <= 'z') c = (uint8_t)(c - 32);
      buf[k++] = c;
    }
    r->pos++;
  }
  return k;
}

static int all_digits(const uint8_t *s, uint32_t n) {
  if (n == 0) return 0;
  for (uint32_t i = 0; i < n; i++)
    if (s[i] < '0' || s[i] > '9') return 0;
  return 1;
}

static Obj *src_token_obj(Src *r) {
  uint8_t tokbuf[1024];
  int escaped;
  uint32_t colon_at, k;
  Obj *o;
  k = src_token(r, tokbuf, sizeof tokbuf, &escaped, &colon_at);
  if (k >= sizeof tokbuf) {
    set_err("token too long in the source");
    return 0;
  }
  if (k == 0 && !escaped) {
    set_err("empty token in the source");
    return 0;
  }
  if (!escaped) {
    /* integer, optional sign, optional trailing dot */
    uint32_t s = 0, e = k;
    int neg = 0;
    if (e > 0 && (tokbuf[0] == '+' || tokbuf[0] == '-')) {
      neg = tokbuf[0] == '-';
      s = 1;
    }
    if (e > s && tokbuf[e - 1] == '.' && all_digits(tokbuf + s, e - s - 1) &&
        e - s - 1 > 0) {
      /* "123." is an integer in Common Lisp */
      uint64_t v = 0;
      for (uint32_t i = s; i + 1 < e; i++) v = v * 10 + (uint64_t)(tokbuf[i] - '0');
      if (v > (uint64_t)INT64_MAX_LOCAL) {
        set_err("integer too large in the source");
        return 0;
      }
      return mk_int(neg ? -(int64_t)v : (int64_t)v);
    }
    if (all_digits(tokbuf + s, e - s)) {
      uint64_t v = 0;
      for (uint32_t i = s; i < e; i++) {
        if (v > (UINT64_MAX_LOCAL / 10u)) {
          set_err("integer too large in the source");
          return 0;
        }
        v = v * 10 + (uint64_t)(tokbuf[i] - '0');
      }
      if (v > (uint64_t)INT64_MAX_LOCAL) {
        set_err("integer too large in the source");
        return 0;
      }
      return mk_int(neg ? -(int64_t)v : (int64_t)v);
    }
    /* ratio a/b */
    {
      uint32_t slash = 0xFFFFFFFFu;
      for (uint32_t i = 0; i < e; i++)
        if (tokbuf[i] == '/') slash = i;
      if (slash != 0xFFFFFFFFu) {
        uint32_t ns = (tokbuf[0] == '+' || tokbuf[0] == '-') ? 1u : 0u;
        int rneg = tokbuf[0] == '-';
        if (slash > ns && all_digits(tokbuf + ns, slash - ns) &&
            all_digits(tokbuf + slash + 1, e - slash - 1)) {
          uint64_t a = 0, b = 0;
          for (uint32_t i = ns; i < slash; i++) a = a * 10 + (uint64_t)(tokbuf[i] - '0');
          for (uint32_t i = slash + 1; i < e; i++) b = b * 10 + (uint64_t)(tokbuf[i] - '0');
          if (b == 0) {
            set_err("zero denominator in the source");
            return 0;
          }
          {
            uint64_t x = a, y = b;
            while (y) {
              uint64_t t = x % y;
              x = y;
              y = t;
            }
            if (x == 0) x = 1;
            a /= x;
            b /= x;
          }
          if (b == 1) return mk_int(rneg ? -(int64_t)a : (int64_t)a);
          o = new_obj(T_RAT);
          if (!o) return 0;
          o->num = rneg ? -(int64_t)a : (int64_t)a;
          o->den = b;
          return o;
        }
      }
    }
    /* Dot-only tokens are rejected. Digit-led tokens with a decimal point
       and only digits and dots are floats, which this checker rejects. */
    {
      int dots = 0, onlydots = 1, floatlike = 1;
      for (uint32_t i = 0; i < e; i++) {
        if (tokbuf[i] == '.') dots++;
        else onlydots = 0;
        if (!((tokbuf[i] >= '0' && tokbuf[i] <= '9') || tokbuf[i] == '.'))
          floatlike = 0;
      }
      if (onlydots) {
        set_err("dot token in the source");
        return 0;
      }
      if (dots > 0 && floatlike && tokbuf[s] >= '0' && tokbuf[s] <= '9') {
        set_err("floating point number in the source (not supported)");
        return 0;
      }
    }
  }
  /* symbol */
  if (colon_at == 0 && !escaped) {
    /* keyword :NAME (also ::NAME is not expected here) */
    uint32_t nstart = 1;
    if (k > 1 && tokbuf[1] == ':') nstart = 2;
    return resolve_sym((const uint8_t *)"KEYWORD", 7, tokbuf + nstart, k - nstart);
  }
  if (colon_at != 0xFFFFFFFFu) {
    uint32_t nstart = colon_at + 1;
    if (nstart < k && tokbuf[nstart] == ':') nstart++;
    return resolve_sym(tokbuf, colon_at, tokbuf + nstart, k - nstart);
  }
  return resolve_sym(0, 0, tokbuf, k);
}

static Obj *src_char(Src *r) {
  /* r->pos is at the backslash after #. */
  uint8_t tokbuf[64];
  uint32_t k = 0;
  int escaped;
  uint32_t colon_at;
  Obj *o;
  r->pos++; /* skip backslash */
  if (r->pos >= r->n) {
    set_err("unterminated character in the source");
    return 0;
  }
  /* A single character always stands for itself, even if it is a delimiter. */
  tokbuf[k++] = r->b[r->pos];
  r->pos++;
  while (r->pos < r->n && !is_delim(r->b[r->pos]) && k < sizeof tokbuf) {
    tokbuf[k++] = r->b[r->pos];
    r->pos++;
  }
  (void)escaped;
  (void)colon_at;
  o = new_obj(T_CHAR);
  if (!o) return 0;
  if (k == 1) {
    o->num = tokbuf[0];
    return o;
  }
  {
    static const struct { const char *name; int code; } names[] = {
        {"SPACE", 32}, {"NEWLINE", 10}, {"LINEFEED", 10}, {"TAB", 9},
        {"RETURN", 13}, {"PAGE", 12}, {"BACKSPACE", 8}, {"RUBOUT", 127},
        {"NUL", 0}, {"NULL", 0}};
    for (uint32_t i = 0; i < sizeof names / sizeof names[0]; i++) {
      uint32_t j = 0;
      const char *nm = names[i].name;
      while (nm[j] && j < k) {
        uint8_t c = tokbuf[j];
        if (c >= 'a' && c <= 'z') c = (uint8_t)(c - 32);
        if (c != (uint8_t)nm[j]) break;
        j++;
      }
      if (j == k && nm[j] == 0) {
        o->num = names[i].code;
        return o;
      }
    }
  }
  set_err("unsupported character name in the source");
  return 0;
}

static Obj *src_datum(Src *r) {
  uint8_t c;
  if (!src_skip(r)) return 0;
  if (r->pos >= r->n) {
    set_err("unexpected end of source");
    return 0;
  }
  c = r->b[r->pos];
  if (c == '(') return src_list(r);
  if (c == ')') {
    set_err("unexpected ) in the source");
    return 0;
  }
  if (c == '\'') {
    Obj *d, *cell1, *cell2;
    r->pos++;
    d = src_datum(r);
    if (!d) return 0;
    cell2 = mk_cons(d, mk_nil());
    if (!cell2) return 0;
    cell1 = mk_cons(resolve_sym(0, 0, (const uint8_t *)"QUOTE", 5), cell2);
    return cell1;
  }
  if (c == '`' || c == ',') {
    set_err("backquote or comma in the source (not supported by this checker)");
    return 0;
  }
  if (c == '"') return src_string(r);
  if (c == '#') {
    if (r->pos + 1 < r->n && r->b[r->pos + 1] == '\\') {
      r->pos++;
      return src_char(r);
    }
    if (r->pos + 1 < r->n && r->b[r->pos + 1] == '\'') {
      Obj *d, *cell2;
      r->pos += 2;
      d = src_datum(r);
      if (!d) return 0;
      cell2 = mk_cons(d, mk_nil());
      if (!cell2) return 0;
      return mk_cons(resolve_sym(0, 0, (const uint8_t *)"FUNCTION", 8), cell2);
    }
    set_err("unsupported # reader macro in the source (not supported by this checker)");
    return 0;
  }
  return src_token_obj(r);
}

/*
 * read-object-file (other-events.lisp:13123): the events are the forms after
 * the first in-package form, which chk-in-package consumes (:10576). The
 * result is (IN-PACKAGE "ACL2") followed by those forms.
 */
static Obj *read_source_events(const uint8_t *b, uint32_t n) {
  Src r;
  Obj *first, *head = 0, *tail = 0, *pkg_form, *cell;
  r.b = b;
  r.n = n;
  r.pos = 0;
  r.line = 1;
  first = src_datum(&r);
  if (!first) {
    if (!err_set) set_err("source file is empty");
    return 0;
  }
  if (!(is_cons(first) && is_sym(car_of(first), "COMMON-LISP", "IN-PACKAGE") &&
        is_cons(cdr_of(first)) && is_str_eq(car_of(cdr_of(first)), "ACL2") &&
        is_nil(cdr_of(cdr_of(first))))) {
    set_err("first form of the source is not (in-package \"ACL2\")");
    return 0;
  }
  pkg_form = mk_cons(resolve_sym(0, 0, (const uint8_t *)"IN-PACKAGE", 10),
                     mk_cons(mk_str((const uint8_t *)"ACL2", 4), mk_nil()));
  if (!pkg_form) return 0;
  head = mk_cons(pkg_form, mk_nil());
  if (!head) return 0;
  tail = head;
  for (;;) {
    Obj *d;
    if (!src_skip(&r)) return 0;
    if (r.pos >= r.n) break;
    d = src_datum(&r);
    if (!d) return 0;
    cell = mk_cons(d, mk_nil());
    if (!cell) return 0;
    tail->cdr = cell;
    tail = cell;
  }
  return head;
}

/* ------------------------------------------------------------------ */
/* Certificate interpretation                                          */
/* ------------------------------------------------------------------ */

/* Parses every top-level #Z object of the .cert into forms[]. */
#define MAX_FORMS 65536
static Obj *forms[MAX_FORMS];
static uint32_t nforms;

static int parse_cert_forms(const uint8_t *b, uint32_t n) {
  Bytes s;
  s.b = b;
  s.n = n;
  s.pos = 0;
  nforms = 0;
  for (;;) {
    Obj *o;
    while (s.pos < s.n && is_ws(s.b[s.pos])) s.pos++;
    if (s.pos >= s.n) break;
    if (!(s.pos + 1 < s.n && s.b[s.pos] == '#' && s.b[s.pos + 1] == 'Z')) {
      set_err("cert contains text outside a #Z serialized object");
      return 0;
    }
    s.pos += 2;
    o = dec_object(&s);
    if (!o) return 0;
    if (nforms >= MAX_FORMS) {
      set_err("cert has too many top-level forms");
      return 0;
    }
    forms[nforms++] = o;
  }
  return 1;
}

/* Debugging aid: writes a shape summary of each top-level form to out_buf. */
static void dump_obj(const Obj *o, int depth) {
  if (!o) {
    out_put("<null>");
    return;
  }
  switch (o->tag) {
  case T_INT:
    out_i64(o->num);
    break;
  case T_RAT:
    out_i64(o->num);
    out_put("/");
    out_i64((int64_t)o->den);
    break;
  case T_CHAR:
    out_put("#\\");
    out_i64(o->num);
    break;
  case T_STR:
    out_put("\"");
    out_putn(o->p1, o->n1 > 60 ? 60 : o->n1);
    out_put("\"");
    break;
  case T_SYM:
    if (!(o->n1 == 7 && meq(o->p1, o->n1, "KEYWORD"))) {
      out_putn(o->p1, o->n1);
      out_put("::");
    } else {
      out_put(":");
    }
    out_putn(o->p2, o->n2);
    break;
  case T_CONS: {
    uint32_t k = 0;
    const Obj *c = o;
    if (depth <= 0) {
      out_put("(...)");
      break;
    }
    out_put("(");
    while (c && c->tag == T_CONS && k < 8) {
      if (k) out_put(" ");
      dump_obj(c->car, depth - 1);
      c = c->cdr;
      k++;
    }
    if (c && c->tag == T_CONS) out_put(" ...");
    else if (c && !is_nil(c)) {
      out_put(" . ");
      dump_obj(c, depth - 1);
    }
    out_put(")");
    break;
  }
  }
}

static int dump_depth = 3;
void cc_set_dump_depth(int d) { dump_depth = d; }

int cc_dump_cert(uint32_t cert_len) {
  out_len = 0;
  out_buf[0] = 0;
  err_set = 0;
  arena_used = 0;
  if (!parse_cert_forms(cert_buf, cert_len)) {
    out_put("parse error: ");
    out_put(err_msg);
    out_put("\n");
    return 2;
  }
  for (uint32_t i = 0; i < nforms; i++) {
    out_i64(i);
    out_put(": ");
    dump_obj(forms[i], dump_depth);
    out_put("\n");
  }
  return 0;
}
/* ------------------------------------------------------------------ */
/* Recorded hashes and paths                                           */
/* ------------------------------------------------------------------ */

/* Universal time (seconds since 1900) minus this is the Unix epoch. The
 * write date in a cert is ACL2 file-write-date$, which is universal time. */
#define UT_UNIX_OFFSET 2208988800LL

#define HK_NONE   0   /* no entry */
#define HK_INT    1   /* checksum (other-events.lisp:11403, :13436) */
#define HK_ALIST  2   /* ((:BOOK-LENGTH . n) (:BOOK-WRITE-DATE . d)) (other-events.lisp:13421) */
#define HK_OTHER  3   /* :TRIVIAL-BOOK-HASH or an unknown form */

typedef struct {
  char disp[PATH_CAP];      /* name as recorded: "arithmetic/top.lisp" or absolute */
  uint32_t disp_len;
  int sysfile;              /* 1 when recorded as (:SYSTEM . relpath) */
  char lisp_path[PATH_CAP];
  uint32_t lisp_path_len;
  char cert_path[PATH_CAP];
  uint32_t cert_path_len;
  int resolved;
  int local;                /* 1 when recorded inside (ACL2::LOCAL entry) */
  int hkind;
  int64_t hint;             /* HK_INT value */
  int64_t hlen;             /* HK_ALIST :BOOK-LENGTH */
  int64_t hdate;            /* HK_ALIST :BOOK-WRITE-DATE */
} EntryRef;

#define MAX_DEPS 128

typedef struct {
  int error;
  char err[256];
  char version[128];
  uint32_t ncmds;
  /* cert-hash */
  int cert_kind;            /* HK_INT or HK_OTHER */
  int cert_ok;              /* HK_INT: stored equals computed */
  int64_t cert_stored;
  int64_t cert_computed;
  /* own entry and source binding */
  EntryRef own;
  int src_status;           /* 0 MATCH, 1 MISMATCH, 2 UNVERIFIED */
  int64_t src_stored;
  int64_t src_computed;
  /* recorded dependencies */
  uint32_t ndeps;
  EntryRef deps[MAX_DEPS];
} Report;

static char books_dir[PATH_CAP];
static uint32_t books_dir_len;

/* Input buffer for the host: the books directory is written here, then
 * cc_set_books_dir_len is called with its length. */
static char books_dir_in[PATH_CAP];

char *cc_books_buf(void) { return books_dir_in; }

void cc_set_books_dir_len(uint32_t n) {
  if (n >= sizeof books_dir) n = sizeof books_dir - 1;
  for (uint32_t i = 0; i < n; i++) books_dir[i] = books_dir_in[i];
  books_dir[n] = 0;
  books_dir_len = n;
}

void cc_set_books_dir(const char *s, uint32_t n) {
  if (n >= sizeof books_dir_in) n = sizeof books_dir_in - 1;
  for (uint32_t i = 0; i < n; i++) books_dir_in[i] = s[i];
  cc_set_books_dir_len(n);
}

static void memset_local(void *p, uint32_t n) {
  uint8_t *b = (uint8_t *)p;
  for (uint32_t i = 0; i < n; i++) b[i] = 0;
}

static void copy_bytes(char *dst, uint32_t cap, uint32_t *dlen, const uint8_t *src, uint32_t n) {
  if (n >= cap) n = cap - 1;
  for (uint32_t i = 0; i < n; i++) dst[i] = (char)src[i];
  dst[n] = 0;
  *dlen = n;
}

static void append_bytes(char *dst, uint32_t cap, uint32_t *dlen, const char *src, uint32_t n) {
  for (uint32_t i = 0; i < n && *dlen + 1 < cap; i++) dst[(*dlen)++] = src[i];
  dst[*dlen] = 0;
}

/* Builds the .lisp and .cert paths of a recorded entry (ACL2 book names). */
static void resolve_entry(EntryRef *e) {
  static const char lisp_ext[] = ".lisp";
  static const char cert_ext[] = ".cert";
  uint32_t base = e->disp_len;
  uint32_t i;
  e->resolved = 0;
  e->lisp_path_len = 0;
  e->cert_path_len = 0;
  e->lisp_path[0] = 0;
  e->cert_path[0] = 0;
  if (e->sysfile) {
    if (books_dir_len == 0) return;
    e->lisp_path_len = 0;
    append_bytes(e->lisp_path, PATH_CAP, &e->lisp_path_len, books_dir, books_dir_len);
    append_bytes(e->lisp_path, PATH_CAP, &e->lisp_path_len, "/", 1);
    append_bytes(e->lisp_path, PATH_CAP, &e->lisp_path_len, e->disp, e->disp_len);
  } else {
    copy_bytes(e->lisp_path, PATH_CAP, &e->lisp_path_len, (const uint8_t *)e->disp, e->disp_len);
  }
  /* Strip a trailing .lisp for the cert name, then add the extensions. */
  base = e->lisp_path_len;
  if (base >= 5) {
    int has = 1;
    for (i = 0; i < 5; i++)
      if (e->lisp_path[base - 5 + i] != lisp_ext[i]) has = 0;
    if (has) base -= 5;
  }
  if (base + 5 >= PATH_CAP) return;
  for (i = 0; i < base; i++) e->cert_path[i] = e->lisp_path[i];
  for (i = 0; i < 5; i++) e->cert_path[base + i] = cert_ext[i];
  e->cert_path[base + 5] = 0;
  e->cert_path_len = base + 5;
  {
    uint32_t L = e->lisp_path_len;
    if (L + 5 >= PATH_CAP) return;
    if (!(L >= 5 && e->lisp_path[L - 5] == '.' && e->lisp_path[L - 4] == 'l')) {
      append_bytes(e->lisp_path, PATH_CAP, &e->lisp_path_len, lisp_ext, 5);
    }
  }
  e->resolved = 1;
}

/* Reads a recorded entry (full name, hash) from its list form. */
static void read_entry(const Obj *entry, EntryRef *e) {
  const Obj *full = car_of(entry);
  const Obj *h = cdr_of(cdr_of(cdr_of(cdr_of(entry))));
  memset_local(e, sizeof *e);
  if (full && full->tag == T_CONS && is_kw(car_of(full), "SYSTEM") &&
      cdr_of(full) && cdr_of(full)->tag == T_STR) {
    e->sysfile = 1;
    copy_bytes(e->disp, PATH_CAP, &e->disp_len, cdr_of(full)->p1, cdr_of(full)->n1);
  } else if (full && full->tag == T_STR) {
    e->sysfile = 0;
    copy_bytes(e->disp, PATH_CAP, &e->disp_len, full->p1, full->n1);
  } else {
    e->disp[0] = 0;
    e->disp_len = 0;
  }
  if (h && h->tag == T_INT) {
    e->hkind = HK_INT;
    e->hint = h->num;
  } else if (h && h->tag == T_CONS) {
    /* alist: ((:BOOK-LENGTH . n) (:BOOK-WRITE-DATE . d)) */
    const Obj *c = h;
    e->hkind = HK_ALIST;
    while (c && c->tag == T_CONS) {
      const Obj *pair = c->car;
      if (pair && pair->tag == T_CONS && pair->car && pair->car->tag == T_SYM) {
        const Obj *val = pair->cdr;
        if (val && val->tag == T_INT) {
          if (is_kw(pair->car, "BOOK-LENGTH")) e->hlen = val->num;
          if (is_kw(pair->car, "BOOK-WRITE-DATE")) e->hdate = val->num;
        }
      }
      c = c->cdr;
    }
  } else {
    e->hkind = HK_OTHER;
  }
  resolve_entry(e);
}

/* ------------------------------------------------------------------ */
/* One cert and its source                                             */
/* ------------------------------------------------------------------ */

static void set_report_error(Report *rep) {
  uint32_t k = 0;
  rep->error = 1;
  while (err_msg[k] && k + 1 < sizeof rep->err) {
    rep->err[k] = err_msg[k];
    k++;
  }
  rep->err[k] = 0;
}

/*
 * Checks one cert and its source. The source file is given as bytes and as
 * its write date (universal time). Results go to rep.
 */
static void check_pair(const uint8_t *cb, uint32_t cn, const uint8_t *lb,
                       uint32_t ln, int64_t lwdate, Report *rep) {
  uint32_t i;
  Obj *cmds_head = 0, *cmds_tail = 0, *exp, *cd, *pre, *post, *hashobj, *cmds;
  Obj *own, *ev;

  memset_local(rep, sizeof *rep);
  err_set = 0;
  err_msg[0] = 0;
  arena_used = 0;

  if (!parse_cert_forms(cb, cn)) goto fail;
  if (nforms < 4) {
    set_err("cert has too few forms");
    goto fail;
  }
  if (!(is_cons(forms[0]) && is_sym(car_of(forms[0]), "COMMON-LISP", "IN-PACKAGE") &&
        is_str_eq(car_of(cdr_of(forms[0])), "ACL2"))) {
    set_err("cert does not start with (in-package \"ACL2\")");
    goto fail;
  }
  if (forms[1]->tag == T_STR) {
    uint32_t vlen = 0;
    copy_bytes(rep->version, sizeof rep->version, &vlen, forms[1]->p1, forms[1]->n1);
  }
  i = 2;
  if (!is_kw(forms[i], "BEGIN-PORTCULLIS-CMDS")) {
    set_err("cert lacks :BEGIN-PORTCULLIS-CMDS");
    goto fail;
  }
  i++;
  while (i < nforms && !is_kw(forms[i], "END-PORTCULLIS-CMDS")) {
    Obj *cell = mk_cons(forms[i], mk_nil());
    if (!cell) goto fail;
    if (!cmds_head) cmds_head = cell;
    else cmds_tail->cdr = cell;
    cmds_tail = cell;
    rep->ncmds++;
    i++;
  }
  if (i >= nforms) {
    set_err("cert lacks :END-PORTCULLIS-CMDS");
    goto fail;
  }
  cmds = cmds_head ? cmds_head : mk_nil();
  if (!cmds) goto fail;
  i++;
  if (i < nforms && is_kw(forms[i], "EXPANSION-ALIST") && i + 1 < nforms) {
    exp = forms[i + 1];
    i += 2;
  } else {
    exp = mk_nil();
  }
  if (i < nforms && is_kw(forms[i], "CERT-DATA") && i + 1 < nforms) {
    cd = forms[i + 1];
    i += 2;
  } else {
    cd = mk_nil();
  }
  if (i + 3 > nforms) {
    set_err("cert ends before pre-alist, post-alist and cert-hash");
    goto fail;
  }
  pre = forms[i];
  post = forms[i + 1];
  hashobj = forms[i + 2];
  i += 3;
  if (i < nforms && is_kw(forms[i], "PCERT-INFO")) i += 2;
  if (i != nforms) {
    set_err("cert has unexpected trailing forms");
    goto fail;
  }

  /* cert-hash: an integer is a checksum (other-events.lisp:11403). */
  if (hashobj->tag == T_INT) {
    Obj *top;
    rep->cert_kind = HK_INT;
    rep->cert_stored = hashobj->num;
    /* (check-sum-obj (cons (cons cmds pre) (list* post exp cd))) */
    top = mk_cons(mk_cons(cmds, pre), mk_cons(post, mk_cons(exp, cd)));
    if (!top) goto fail;
    rep->cert_computed = cs_obj(top);
    if (err_set) goto fail;
    rep->cert_ok = rep->cert_computed == rep->cert_stored;
  } else {
    rep->cert_kind = HK_OTHER;
  }

  /* Own entry: the car of the post-alist. certify-book writes it
   * (other-events.lisp:17986), and include-book compares it with the source
   * (other-events.lisp:14405-14425, include-book-ok-familiar-name-and-hash:13821). */
  if (!is_cons(post) || !is_cons(car_of(post))) {
    set_err("post-alist has no own entry");
    goto fail;
  }
  own = car_of(post);
  read_entry(own, &rep->own);

  if (rep->own.hkind == HK_INT) {
    /* (check-sum-obj (list* cmds exp ev cd)), book-hash (other-events.lisp:13436) */
    ev = read_source_events(lb, ln);
    if (!ev) goto fail;
    {
      Obj *top = mk_cons(cmds, mk_cons(exp, mk_cons(ev, cd)));
      if (!top) goto fail;
      rep->src_computed = cs_obj(top);
      if (err_set) goto fail;
    }
    rep->src_stored = rep->own.hint;
    rep->src_status = rep->src_computed == rep->src_stored ? 0 : 1;
  } else if (rep->own.hkind == HK_ALIST) {
    /* book-hash-alist (other-events.lisp:13421): length and write date of the .lisp */
    rep->src_status = (rep->own.hlen == (int64_t)ln && rep->own.hdate == lwdate) ? 0 : 1;
  } else {
    rep->src_status = 2;
  }

  /* Recorded dependencies: the remaining post-alist entries. */
  {
    const Obj *cur = cdr_of(post);
    while (cur && cur->tag == T_CONS) {
      if (rep->ndeps >= MAX_DEPS) {
        set_err("too many recorded dependencies");
        goto fail;
      }
      {
        const Obj *ent = cur->car;
        int is_local = 0;
        if (is_cons(ent) && is_sym(car_of(ent), "ACL2", "LOCAL") && is_cons(cdr_of(ent))) {
          ent = car_of(cdr_of(ent));
          is_local = 1;
        }
        if (!is_cons(ent)) {
          set_err("malformed include-book entry in the post-alist");
          goto fail;
        }
        read_entry(ent, &rep->deps[rep->ndeps]);
        rep->deps[rep->ndeps].local = is_local;
      }
      rep->ndeps++;
      cur = cur->cdr;
    }
  }
  return;

fail:
  set_report_error(rep);
}

/* ------------------------------------------------------------------ */
/* Top level                                                           */
/* ------------------------------------------------------------------ */

static Report parent_rep;
static Report dep_rep;

/* Status codes used in the report. */
#define ST_MATCH 0
#define ST_MISMATCH 1
#define ST_UNVERIFIED 2


/* Checks one recorded dependency against its own .lisp and .cert. */
static int check_dependency(const EntryRef *d) {
  int32_t cn, ln;
  int64_t info[2];
  if (!d->resolved) {
    out_put("    UNVERIFIED (no path: sysfile book name needs --books-dir)\n");
    return ST_UNVERIFIED;
  }
  cn = host_read_file((const uint8_t *)d->cert_path, d->cert_path_len, dep_cert_buf, FILE_CAP);
  if (cn < 0) {
    out_put("    UNVERIFIED (cert not found: ");
    out_putn((const uint8_t *)d->cert_path, d->cert_path_len);
    out_put(")\n");
    return ST_UNVERIFIED;
  }
  ln = host_read_file((const uint8_t *)d->lisp_path, d->lisp_path_len, dep_lisp_buf, FILE_CAP);
  if (ln < 0) {
    out_put("    UNVERIFIED (source not found: ");
    out_putn((const uint8_t *)d->lisp_path, d->lisp_path_len);
    out_put(")\n");
    return ST_UNVERIFIED;
  }
  if (host_file_info((const uint8_t *)d->lisp_path, d->lisp_path_len, info) != 0) {
    out_put("    UNVERIFIED (cannot stat source)\n");
    return ST_UNVERIFIED;
  }
  check_pair(dep_cert_buf, (uint32_t)cn, dep_lisp_buf, (uint32_t)ln, info[1], &dep_rep);
  if (dep_rep.error) {
    out_put("    UNVERIFIED (");
    out_put(dep_rep.err);
    out_put(")\n");
    return ST_UNVERIFIED;
  }
  if (d->hkind == HK_ALIST) {
    int same = dep_rep.own.hkind == HK_ALIST && dep_rep.own.hlen == d->hlen &&
               dep_rep.own.hdate == d->hdate;
    out_put("    recorded length ");
    out_i64(d->hlen);
    out_put(", write date ");
    out_i64(d->hdate);
    out_put("; its own cert records length ");
    out_i64(dep_rep.own.hlen);
    out_put(", write date ");
    out_i64(dep_rep.own.hdate);
    out_put("; its source has length ");
    out_i64(ln);
    out_put(", write date ");
    out_i64(info[1]);
    out_put("\n");
    if (!same) {
      out_put("    MISMATCH (cert of the book disagrees with the recorded values)\n");
      return ST_MISMATCH;
    }
    if (dep_rep.src_status != ST_MATCH) {
      out_put("    MISMATCH (its source file differs from its cert)\n");
      return ST_MISMATCH;
    }
    return ST_MATCH;
  }
  if (d->hkind == HK_INT) {
    int same = dep_rep.own.hkind == HK_INT && dep_rep.own.hint == d->hint;
    if (!same) {
      out_put("    MISMATCH (recorded checksum differs from its own-entry checksum)\n");
      return ST_MISMATCH;
    }
    if (dep_rep.src_status != ST_MATCH) {
      out_put("    MISMATCH (its source checksum differs from its own entry)\n");
      return ST_MISMATCH;
    }
    if (dep_rep.cert_kind == HK_INT && !dep_rep.cert_ok) {
      out_put("    MISMATCH (its cert checksum differs)\n");
      return ST_MISMATCH;
    }
    return ST_MATCH;
  }
  out_put("    UNVERIFIED (recorded hash form is not supported)\n");
  return ST_UNVERIFIED;
}

int cc_run(uint32_t cert_len, uint32_t lisp_len, int64_t lisp_wdate) {
  int verdict = ST_MATCH; /* 0 PASS, 1 FAIL, 2 UNVERIFIED after folding */
  uint32_t i;
  static const char head[] =
      "ACL2 .cert integrity check. It does NOT replay proofs, does NOT evaluate the ACL2 logic, and does NOT check guards.\n";

  out_len = 0;
  out_buf[0] = 0;
  out_put(head);

  check_pair(cert_buf, cert_len, lisp_buf, lisp_len, lisp_wdate, &parent_rep);
  if (parent_rep.error) {
    out_put("RESULT: cannot check the cert: ");
    out_put(parent_rep.err);
    out_put("\nVERDICT: UNVERIFIED\n");
    return 2;
  }
  out_put("cert: ACL2 version \"");
  out_put(parent_rep.version);
  out_put("\", ");
  out_i64(parent_rep.ncmds);
  out_put(" portcullis commands\n");

  if (parent_rep.cert_kind == HK_INT) {
    out_put(parent_rep.cert_ok ? "cert checksum: MATCH" : "cert checksum: MISMATCH");
    out_put(" (stored ");
    out_i64(parent_rep.cert_stored);
    out_put(", computed ");
    out_i64(parent_rep.cert_computed);
    out_put(")\n");
    if (!parent_rep.cert_ok) verdict = ST_MISMATCH;
  } else {
    out_put("cert checksum: NOT RECORDED (cert-hash is :TRIVIAL-BOOK-HASH, so the cert content is not hashed)\n");
  }

  out_put("source ");
  out_putn((const uint8_t *)parent_rep.own.disp, parent_rep.own.disp_len);
  out_put(": ");
  if (parent_rep.own.hkind == HK_ALIST) {
    out_put("book-hash alist mode, length and write date of the .lisp\n");
    out_put("  length: recorded ");
    out_i64(parent_rep.own.hlen);
    out_put(", file ");
    out_i64((int64_t)lisp_len);
    out_put(parent_rep.own.hlen == (int64_t)lisp_len ? ": MATCH\n" : ": MISMATCH\n");
    out_put("  write date: recorded ");
    out_i64(parent_rep.own.hdate);
    out_put(", file ");
    out_i64(lisp_wdate);
    out_put(lisp_wdate == parent_rep.own.hdate ? ": MATCH\n" : ": MISMATCH\n");
  } else if (parent_rep.own.hkind == HK_INT) {
    out_put("checksum mode: ");
    out_put(parent_rep.src_status == ST_MATCH ? "MATCH" : "MISMATCH");
    out_put(" (stored ");
    out_i64(parent_rep.src_stored);
    out_put(", computed ");
    out_i64(parent_rep.src_computed);
    out_put(")\n");
  } else {
    out_put("UNVERIFIED (own-entry hash form not supported)\n");
  }
  if (parent_rep.src_status == ST_MISMATCH) verdict = ST_MISMATCH;
  if (parent_rep.src_status == ST_UNVERIFIED && verdict == ST_MATCH) verdict = ST_UNVERIFIED;

  out_put("recorded dependencies: ");
  out_i64(parent_rep.ndeps);
  out_put("\n");
  for (i = 0; i < parent_rep.ndeps; i++) {
    const EntryRef *d = &parent_rep.deps[i];
    int st;
    out_put(d->local ? "  (local) " : "  ");
    out_putn((const uint8_t *)d->disp, d->disp_len);
    out_put("\n");
    st = check_dependency(d);
    if (st == ST_MISMATCH) verdict = ST_MISMATCH;
    else if (st == ST_UNVERIFIED && verdict == ST_MATCH) verdict = ST_UNVERIFIED;
  }

  out_put("VERDICT: ");
  out_put(verdict == ST_MATCH ? "PASS" : (verdict == ST_MISMATCH ? "FAIL" : "UNVERIFIED"));
  out_put("\n");
  out_put("PASS means the recorded hashes and lengths and write dates match the files named in the certs. It does not mean the proofs are valid.\n");
  out_put("NOT CHECKED: proof replay, the ACL2 logic, guard verification, and any change that keeps the length and the write date of a .lisp file (alist mode records no content hash). Comment-only edits in checksum mode are not part of the events hash.\n");
  return verdict == ST_MATCH ? 0 : (verdict == ST_MISMATCH ? 1 : 2);
}
