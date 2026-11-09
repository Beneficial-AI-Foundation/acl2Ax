# cert-check.mjs

Integrity checker for an ACL2 `.cert` file and its book (`.lisp`). It reads the
certificate, compares the recorded book lengths and write dates with the files
on disk, and reports the result.

It does not replay proofs. A PASS does not show that the proofs in the
certificate are valid, and it does not show that the book is accepted by ACL2.

Requires Node.js (tested with v26.0.0). It uses only the Node built-ins `fs`,
`path` and `url`, and no npm packages.

## Usage

```
node cert-check.mjs <file.cert> <file.lisp> [--books-root DIR]
```

- `--books-root DIR` sets the directory that `(:SYSTEM . "rel")` book names
  resolve against. Without it, the checker searches upward from the directory
  of the `.cert` for the first directory that contains `rel`.

Exit codes:

| Code | Meaning |
| --- | --- |
| 0 | PASS. Every check passed. |
| 1 | FAIL. At least one recorded length or write date differs from a file. |
| 2 | Usage error, or an input file cannot be read. |
| 3 | UNVERIFIED. Nothing failed, but at least one check could not be made. |

Exit code 3 is not in the original specification. It separates "could not check"
from "checked and passed".

## Test

```
node test/run-tests.mjs [path-to-books/arithmetic]
```

The runner checks the original `abs.lisp` and three modified copies, which are
written to a temporary directory. The ACL2 tree is not modified.

## What is verified

- Decoding of every top-level object of the `.cert`. The binary `#Z` format
  (V2 and V3) is decoded in full, and each object is reported as decoded or as
  not understood.
- Structure of the top-level forms: `(in-package "ACL2")`, the ACL2 version
  string, the portcullis commands, the optional expansion alist and cert-data,
  the pre-alist, the post-alist, the cert-hash, and the optional pcert-info.
- Own entry: the recorded length and write date of the book against the file.
- Dependencies: each entry of the post-alist after the own entry, one level
  deep, with the recorded length and write date against its file. The result
  reports the number matched, mismatched and unverified.
- Mode: alist mode is detected from the cert-hash `:TRIVIAL-BOOK-HASH` and from
  the `:BOOK-LENGTH` and `:BOOK-WRITE-DATE` entries.

## What is not verified

- Proofs. The checker never replays events.
- Content of the book. In alist mode the certificate has no content hash, so an
  edit that keeps the length and the write date is not detected.
- Integer (checksum) mode. The checker reports it as UNVERIFIED. The checksum
  needs the events of the book read with ACL2's reader and the `fchecksum-obj`
  function (`basis-b.lisp`, `check-sum-obj` near line 2074). This is not
  implemented.
- The contents of the portcullis commands, the expansion alist, the cert-data,
  the pre-alist and the pcert-info. They are decoded and reported as not checked.
- Dependencies of dependencies. Only the entries recorded in the certificate
  are checked.
- Non-`:SYSTEM` book names other than absolute paths.

## Limits found by testing

- Alist mode with same length and restored mtime passes (test 3). This is the
  known limit described above.
- The `:SYSTEM` directory is not stored in the certificate. Without
  `--books-root`, the search upward from the `.cert` directory can find the
  wrong file if a directory contains a same-named relative path. Pass
  `--books-root` when the layout is unusual.
- The name check for the own entry is informational. A copy of the book in
  another directory is reported as "a different file" and does not change the
  result.
- The write date is the POSIX mtime in whole seconds plus 2208988800, the
  offset from the Common Lisp universal time. The recorded date for `abs.lisp`
  equals this conversion of its mtime (test 1).
- Only the V2 and V3 serialization formats are decoded. V1 objects are reported
  as not understood.

## Sources

Format and decoding: `serialize-raw.lisp` (magic at 329, nat decoder at 494,
rat at 526, string at 591, atoms from 648, package at 795, conses at 1233 and
1269, fals at 1385, top-level decoder at 1518). Certificate layout:
`other-events.lisp` `make-certificate-file1` at 12886. Hash and entry shape:
`cert-hash` at 11403, `include-book-alist-entry-p` at 11427, `book-hash-alist`
at 13421, `include-book-ok-familiar-name-and-hash` at 13821, the LOCAL wrapper
at 13375, the recomputation at 14415 to 14419, and the certify-book entry at
17989. Book names: `basis-a.lisp` `sysfile-p` at 10499. Write date:
`axioms.lisp` `file-write-date$` at 28338. All paths are under
`/Users/cbraga/Dropbox/BAIF/SVIL2006-SFO/ACL2/acl2-8.7/`.
