/*
 * native_main.c -- native test driver for cert_check.c.
 * Usage: cert_check_native [--books-dir DIR] <file.cert> <file.lisp>
 * Exit status: 0 PASS, 1 FAIL, 2 UNVERIFIED or usage error.
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>

uint8_t *cc_cert_buf(void);
uint8_t *cc_lisp_buf(void);
uint32_t cc_cert_cap(void);
uint32_t cc_lisp_cap(void);
char *cc_out_buf(void);
void cc_set_books_dir(const char *s, uint32_t n);
int cc_run(uint32_t cert_len, uint32_t lisp_len, int64_t lisp_wdate);

#define UT_UNIX_OFFSET 2208988800LL

/* Reads a whole file into dst. Returns the byte count, or -1 when it is
 * missing, unreadable, or larger than cap. */
static int32_t read_whole(const char *name, uint8_t *dst, uint32_t cap) {
  FILE *f = fopen(name, "rb");
  size_t n;
  int c;
  if (!f) return -1;
  n = fread(dst, 1, cap, f);
  if (n == cap) {
    c = fgetc(f);
    if (c != EOF) {
      fclose(f);
      return -1;
    }
  }
  fclose(f);
  return (int32_t)n;
}

static void to_name(const uint8_t *path, uint32_t path_len, char *name, size_t cap) {
  if (path_len >= cap) path_len = (uint32_t)cap - 1;
  memcpy(name, path, path_len);
  name[path_len] = 0;
}

int32_t host_read_file(const uint8_t *path, uint32_t path_len, uint8_t *dst,
                       uint32_t cap) {
  char name[2048];
  to_name(path, path_len, name, sizeof name);
  return read_whole(name, dst, cap);
}

int32_t host_file_info(const uint8_t *path, uint32_t path_len, int64_t *out) {
  char name[2048];
  struct stat st;
  to_name(path, path_len, name, sizeof name);
  if (stat(name, &st) != 0) return -1;
  out[0] = (int64_t)st.st_size;
  out[1] = (int64_t)st.st_mtime + UT_UNIX_OFFSET;
  return 0;
}

int main(int argc, char **argv) {
  int32_t cn, ln;
  int verdict;
  int64_t info[2];
  int ai = 1;
  if (argc >= 3 && strcmp(argv[1], "--books-dir") == 0) {
    cc_set_books_dir(argv[2], (uint32_t)strlen(argv[2]));
    ai = 3;
  } else if (argc >= 2) {
    /* Default, as in check.js: the path up to and including the nearest
     * "books" component of the cert path. */
    const char *p = argv[ai];
    size_t n = strlen(p), best = 0;
    for (size_t i = 0; i + 6 <= n; i++) {
      if (memcmp(p + i, "books/", 6) == 0 && (i == 0 || p[i - 1] == '/'))
        best = i + 5;
    }
    if (best > 0) cc_set_books_dir(p, (uint32_t)best);
  }
  if (argc - ai != 2) {
    fprintf(stderr, "usage: %s [--books-dir DIR] <file.cert> <file.lisp>\n", argv[0]);
    return 2;
  }
  cn = read_whole(argv[ai], cc_cert_buf(), cc_cert_cap());
  if (cn < 0) {
    fprintf(stderr, "cannot read %s\n", argv[ai]);
    return 2;
  }
  ln = read_whole(argv[ai + 1], cc_lisp_buf(), cc_lisp_cap());
  if (ln < 0) {
    fprintf(stderr, "cannot read %s\n", argv[ai + 1]);
    return 2;
  }
  if (host_file_info((const uint8_t *)argv[ai + 1], (uint32_t)strlen(argv[ai + 1]), info) != 0) {
    fprintf(stderr, "cannot stat %s\n", argv[ai + 1]);
    return 2;
  }
  verdict = cc_run((uint32_t)cn, (uint32_t)ln, info[1]);
  fputs(cc_out_buf(), stdout);
  return verdict;
}
