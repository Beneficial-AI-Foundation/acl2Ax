#!/usr/bin/env node
// cert-check.mjs: integrity checker for an ACL2 .cert file and its book.
//
// It compares recorded lengths, write dates and (where present) hashes with the
// files on disk. It does NOT replay proofs. See README.md for the limits.
//
// Usage: node cert-check.mjs <file.cert> <file.lisp> [--books-root DIR]
// Exit:  0 PASS, 1 FAIL, 2 usage or unreadable input, 3 UNVERIFIED.

import fs from 'node:fs';
import path from 'node:path';

// ---------------------------------------------------------------------------
// Lisp value model.
//   NIL and T are symbols in COMMON-LISP. Symbols are {sym, pkg}.
//   Conses are Cons. Strings are JS strings. Integers are BigInt.
//   Ratios are {rat: true, num, den} (BigInt num and den, den > 1).
//   Complexes are {complex: true, re, im}.
// ---------------------------------------------------------------------------

export const NIL = { sym: 'NIL', pkg: 'COMMON-LISP' };
export const T = { sym: 'T', pkg: 'COMMON-LISP' };

export class Cons {
  constructor(car, cdr) { this.car = car; this.cdr = cdr; }
}

const isSym = (x, pkg, name) => x !== null && typeof x === 'object' && x.sym === name && x.pkg === pkg;
const isKeyword = (x, name) => isSym(x, 'KEYWORD', name);
const isNil = (x) => x === NIL;

// ---------------------------------------------------------------------------
// Binary reader for the #Z serialization format (V1 to V3).
// Each object is preceded by "#Z" in the file. The decoder consumes bytes
// up to the closing magic number and no further.
// ---------------------------------------------------------------------------

class Reader {
  constructor(buf, pos) { this.buf = buf; this.pos = pos; }

  byte() {
    if (this.pos >= this.buf.length) throw new Error(`unexpected end of file at byte ${this.pos}`);
    return this.buf[this.pos++];
  }

  // NAT: little-endian base-128, continue bit in the top bit of each byte.
  // serialize-raw.lisp:165-180 (essay), ser-decode-nat at serialize-raw.lisp:494.
  nat() {
    let x = this.byte();
    if (x < 128) return BigInt(x);
    let value = BigInt(x - 128);
    let shift = 7n;
    for (;;) {
      x = this.byte();
      if (x >= 128) {
        value += BigInt(x - 128) << shift;
        shift += 7n;
      } else {
        value += BigInt(x) << shift;
        return value;
      }
    }
  }

  // A NAT used as a count, index or length. Refuses values that do not fit a JS number.
  natNum() {
    const n = this.nat();
    if (n > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('count too large');
    return Number(n);
  }
}

const MAGIC_TAIL = [0xAC, 0x12, 0x0B];

// Decodes one object that starts at the magic number (the "#Z" is already consumed).
// Mirrors ser-decode-from-stream, serialize-raw.lisp:1518.
function decodeObject(r) {
  // Magic number, serialize-raw.lisp:329-348 (ser-decode-magic).
  // The fourth byte selects the version: C7 V1, C8 V2, C9 V3.
  const m = [r.byte(), r.byte(), r.byte(), r.byte()];
  if (m[0] !== MAGIC_TAIL[0] || m[1] !== MAGIC_TAIL[1] || m[2] !== MAGIC_TAIL[2]) {
    throw new Error('invalid serialized object, magic number incorrect');
  }
  let version;
  if (m[3] === 0xC7) version = 1;
  else if (m[3] === 0xC8) version = 2;
  else if (m[3] === 0xC9) version = 3;
  else throw new Error('invalid serialized object, magic number incorrect');
  if (version === 1) throw new Error('V1 serialized objects are not decoded by this checker');

  // size/idx, serialize-raw.lisp:1518-1545. For V2 and V3, 0 means a
  // two-element array (NIL and T) and the final object is at index 0.
  const sizeIdx = r.natNum();
  const arrSize = sizeIdx === 0 ? 2 : sizeIdx + 1;
  const finalObj = sizeIdx;
  const arr = new Array(arrSize);
  arr[0] = NIL;
  arr[1] = T;
  let free = 2;

  const loadN = (n, make) => {
    if (free + n > arrSize) throw new Error('invalid serialized object, too many atoms');
    for (let i = 0; i < n; i++) arr[free++] = make();
  };

  // NATS, serialize-raw.lisp:648 (ser-decode-and-load-nats).
  loadN(r.natNum(), () => r.nat());

  // RATS, serialize-raw.lisp:673 and ser-decode-rat at 526. Each rat is SIGN NUM DEN.
  loadN(r.natNum(), () => readRat(r));

  // COMPLEXES, serialize-raw.lisp:697 and ser-decode-complex at 559. Each is RAT RAT.
  loadN(r.natNum(), () => {
    const re = readRat(r);
    const im = readRat(r);
    return { complex: true, re, im };
  });

  // CHARS, serialize-raw.lisp:721. One byte per character (ISO-8859-1).
  loadN(r.natNum(), () => String.fromCharCode(r.byte()));

  // STRS, serialize-raw.lisp:745 and ser-decode-str at 591.
  // The header is LEN for V2 and LEN*2+NORMP for V3.
  loadN(r.natNum(), () => readStr(r, version));

  // PACKAGES, serialize-raw.lisp:840 and ser-decode-and-load-package at 795.
  // Each package is NAME COUNT then COUNT symbol names.
  const npkg = r.natNum();
  for (let p = 0; p < npkg; p++) {
    const pkgName = readStr(r, version);
    const nsym = r.natNum();
    if (free + nsym > arrSize) throw new Error('invalid serialized object, too many symbols');
    for (let s = 0; s < nsym; s++) {
      const name = readStr(r, version);
      arr[free++] = { sym: name, pkg: pkgName };
    }
  }

  // CONSES, serialize-raw.lisp:1269 and the loop at 1233. Each cons is
  // CAR-INDEX-AND-HONS-BIT then CDR-INDEX. For V2 and V3, the car index is
  // the first NAT shifted right by one (the low bit is the hons flag).
  const ncons = r.natNum();
  if (free + ncons > arrSize) throw new Error('invalid serialized object, too many conses');
  for (let c = 0; c < ncons; c++) {
    const first = r.nat();
    const carIdx = Number(first >> 1n);
    const cdrIdx = r.natNum();
    if (!(carIdx < free && cdrIdx < free)) throw new Error('cons index out of bounds');
    arr[free++] = new Cons(arr[carIdx], arr[cdrIdx]);
  }
  if (free !== arrSize) throw new Error(`invalid serialized object, decoded ${free} of ${arrSize} objects`);

  // FALS, only in V3, serialize-raw.lisp:1385. A list of FAL indices ended by 0.
  // Each index is followed by a COUNT NAT when hons-mode is not :never.
  if (version === 3) {
    let idx = r.natNum();
    while (idx !== 0) {
      if (idx >= arrSize) throw new Error('FAL index too large');
      r.natNum();
      idx = r.natNum();
    }
  }

  // Closing magic, serialize-raw.lisp:1541-1546 (magic repeated after the body).
  const m2 = [r.byte(), r.byte(), r.byte(), r.byte()];
  if (m2.join() !== m.join()) throw new Error('magic number mismatch at end of object');

  return arr[finalObj];
}

function readRat(r) {
  // serialize-raw.lisp:526 (ser-decode-rat): sign 0 or 1, numerator, denominator.
  const sign = r.nat();
  const num = r.nat();
  const den = r.nat();
  if (sign !== 0n && sign !== 1n) throw new Error('invalid rational sign');
  if (den === 0n) throw new Error('rational with zero denominator');
  const n = sign === 1n ? -num : num;
  const g = gcd(num, den);
  const d = den / (g === 0n ? 1n : g);
  const nn = n / (g === 0n ? 1n : g);
  return d === 1n ? nn : { rat: true, num: nn, den: d };
}

function gcd(a, b) { while (b !== 0n) { [a, b] = [b, a % b]; } return a < 0n ? -a : a; }

// serialize-raw.lisp:591. V3 headers carry a NORMP bit in the low bit.
function readStr(r, version) {
  const header = r.natNum();
  const len = version === 3 ? Math.floor(header / 2) : header;
  let s = '';
  for (let i = 0; i < len; i++) s += String.fromCharCode(r.byte());
  return s;
}

// Reads every #Z object in the file, in order.
// make-certificate-file1 (other-events.lisp:12886) writes one object per top-level form,
// each preceded by a newline, so the only bytes between objects are whitespace.
export function readForms(buf) {
  const forms = [];
  let pos = 0;
  for (;;) {
    while (pos < buf.length && (buf[pos] === 0x0A || buf[pos] === 0x0D || buf[pos] === 0x20 || buf[pos] === 0x09)) pos++;
    if (pos >= buf.length) break;
    if (buf[pos] !== 0x23 || buf[pos + 1] !== 0x5A) {
      forms.push({ ok: false, offset: pos, error: 'bytes are not a #Z object' });
      break;
    }
    const r = new Reader(buf, pos + 2);
    try {
      const value = decodeObject(r);
      forms.push({ ok: true, offset: pos, end: r.pos, value });
      pos = r.pos;
    } catch (e) {
      forms.push({ ok: false, offset: pos, error: e.message });
      break;
    }
  }
  return forms;
}

// ---------------------------------------------------------------------------
// Printing for the report.
// ---------------------------------------------------------------------------

export function show(x) {
  if (x === NIL) return 'NIL';
  if (typeof x === 'string') return JSON.stringify(x);
  if (typeof x === 'bigint') return x.toString();
  if (x instanceof Cons) {
    const parts = [];
    let c = x;
    while (c instanceof Cons) { parts.push(show(c.car)); c = c.cdr; }
    return '(' + parts.join(' ') + (c === NIL ? '' : ' . ' + show(c)) + ')';
  }
  if (x && x.sym !== undefined) return (x.pkg === 'KEYWORD' ? ':' : x.pkg + '::') + x.sym;
  if (x && x.rat) return `${x.num}/${x.den}`;
  if (x && x.complex) return `#C(${show(x.re)} ${show(x.im)})`;
  return String(x);
}

// Spreads a Lisp list into its elements and its final cdr.
function listParts(x) {
  const items = [];
  let c = x;
  while (c instanceof Cons) { items.push(c.car); c = c.cdr; }
  return { items, tail: c };
}

// ---------------------------------------------------------------------------
// Certificate structure.
// ---------------------------------------------------------------------------

// Parses one include-book-alist entry, possibly wrapped as (LOCAL entry).
// Entry shape: (full-book-name user-book-name familiar-name cert-annotations . book-hash).
// other-events.lisp:13003 (post-alist shape) and 13375-13386 (LOCAL unwrapping).
// book-hash is ((:BOOK-LENGTH . n) (:BOOK-WRITE-DATE . d)) in alist mode and an
// integer in integer mode, other-events.lisp:11427-11441 (include-book-alist-entry-p).
export function parseEntry(e) {
  let local = false;
  let v = e;
  if (v instanceof Cons && isSym(v.car, 'ACL2', 'LOCAL')) {
    local = true;
    v = v.cdr instanceof Cons ? v.cdr.car : NIL;
  }
  if (!(v instanceof Cons)) return { ok: false, reason: 'entry is not a cons' };
  const { items, tail } = listParts(v);
  if (items.length < 4) return { ok: false, reason: 'entry has fewer than four fields' };
  const [fullName, userName, familiarName, annotations] = items;
  const hashItems = items.slice(4);
  let hash = null;
  if (typeof tail === 'bigint' && hashItems.length === 0) {
    hash = { kind: 'integer', value: tail };
  } else if (tail === NIL && hashItems.length === 2 &&
             hashItems[0] instanceof Cons && isKeyword(hashItems[0].car, 'BOOK-LENGTH') &&
             typeof hashItems[0].cdr === 'bigint' &&
             hashItems[1] instanceof Cons && isKeyword(hashItems[1].car, 'BOOK-WRITE-DATE') &&
             typeof hashItems[1].cdr === 'bigint') {
    hash = { kind: 'alist', length: hashItems[0].cdr, date: hashItems[1].cdr };
  }
  let name = null;
  if (typeof fullName === 'string') name = { kind: 'path', path: fullName };
  else if (fullName instanceof Cons && isKeyword(fullName.car, 'SYSTEM') && typeof fullName.cdr === 'string') {
    name = { kind: 'system', rel: fullName.cdr };
  }
  return {
    ok: true, local, fullName, name,
    userName, familiarName, annotations, hash,
    raw: show(v),
  };
}

// ---------------------------------------------------------------------------
// Filesystem helpers.
// ---------------------------------------------------------------------------

// Common Lisp universal time (seconds since 1900) is Unix time plus 2208988800.
// axioms.lisp:28338 (file-write-date$ returns the CL file-write-date).
const UNIVERSAL_TIME_OFFSET = 2208988800n;

function fileFacts(file) {
  const st = fs.statSync(file);
  const length = BigInt(st.size);
  const date = BigInt(Math.floor(st.mtimeMs / 1000)) + UNIVERSAL_TIME_OFFSET;
  return { length, date };
}

// A (:SYSTEM . rel) name is relative to the books directory of the ACL2 tree.
// basis-a.lisp:10499-10506 (sysfile-p): a full-book-name is an absolute path or a sysfile.
// The cert does not record that directory, so it is found by searching upward from
// the cert directory unless --books-root is given.
function resolveSystem(rel, certDir, booksRoot) {
  if (booksRoot) {
    const f = path.join(booksRoot, rel);
    return fs.existsSync(f) ? f : null;
  }
  let dir = certDir;
  for (;;) {
    const f = path.join(dir, rel);
    if (fs.existsSync(f)) return f;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

function resolveName(name, certDir, booksRoot) {
  if (!name) return null;
  if (name.kind === 'path') return path.isAbsolute(name.path) && fs.existsSync(name.path) ? name.path : null;
  return resolveSystem(name.rel, certDir, booksRoot);
}

// ---------------------------------------------------------------------------
// Checks.
// ---------------------------------------------------------------------------

export function check(certFile, lispFile, options = {}) {
  const lines = [];
  const counts = { PASS: 0, FAIL: 0, UNVERIFIED: 0, INFO: 0 };
  const add = (status, text) => { counts[status]++; lines.push(`  [${status}] ${text}`); };
  const section = (title) => lines.push('', title);
  let mode = null;

  const certDir = path.dirname(path.resolve(certFile));
  const buf = fs.readFileSync(certFile);
  const forms = readForms(buf);

  lines.push(`cert-check: ${certFile}`);
  lines.push(`        book: ${lispFile}`);
  lines.push('Scope: this checker does not replay proofs. It compares recorded lengths, write dates');
  lines.push('       and hashes with files on disk. A PASS does not show that the proofs are valid.');

  // ---- Top-level forms -------------------------------------------------------
  section('Decoding top-level forms');
  forms.forEach((f, i) => {
    if (!f.ok) add('UNVERIFIED', `object ${i + 1} at byte ${f.offset}: ${f.error}`);
  });
  const decoded = forms.filter((f) => f.ok).map((f) => f.value);
  add(decoded.length === forms.length ? 'PASS' : 'UNVERIFIED', `${decoded.length} of ${forms.length} objects decoded`);

  // Expected order, other-events.lisp:12886-12990 (make-certificate-file1):
  //   (in-package "ACL2"), acl2-version, :BEGIN-PORTCULLIS-CMDS, cmds, :END-PORTCULLIS-CMDS,
  //   [:EXPANSION-ALIST expansion-alist], [:CERT-DATA cert-data], pre-alist,
  //   post-alist, cert-hash, [:PCERT-INFO pcert-info].
  let i = 0;
  const next = () => decoded[i++];
  let postAlist = null;
  let certHash = null;

  if (decoded.length >= 4) {
    const inPkg = next();
    if (inPkg instanceof Cons && isSym(inPkg.car, 'COMMON-LISP', 'IN-PACKAGE')) {
      add('PASS', `form 1 is (IN-PACKAGE "ACL2"): ${show(inPkg)}`);
    } else {
      add('UNVERIFIED', `form 1 is not an IN-PACKAGE form: ${show(inPkg)}`);
    }
    const version = next();
    if (typeof version === 'string') add('INFO', `form 2 acl2-version: ${JSON.stringify(version)}`);
    else add('UNVERIFIED', `form 2 is not a version string: ${show(version)}`);

    if (isKeyword(next(), 'BEGIN-PORTCULLIS-CMDS')) {
      // The cmds are read until :END-PORTCULLIS-CMDS.
      let n = 0;
      while (i < decoded.length && !isKeyword(decoded[i], 'END-PORTCULLIS-CMDS')) { i++; n++; }
      if (i < decoded.length) { i++; add('INFO', `portcullis commands: ${n} decoded, content not checked`); }
      else add('UNVERIFIED', 'no :END-PORTCULLIS-CMDS marker found');
    } else {
      add('UNVERIFIED', 'form 3 is not :BEGIN-PORTCULLIS-CMDS');
    }
    if (i < decoded.length && isKeyword(decoded[i], 'EXPANSION-ALIST')) { i++; next(); add('INFO', 'expansion-alist decoded, content not checked'); }
    if (i < decoded.length && isKeyword(decoded[i], 'CERT-DATA')) { i++; next(); add('INFO', 'cert-data decoded, content not checked'); }

    const preAlist = next();
    if (preAlist instanceof Cons || preAlist === NIL) add('INFO', 'pre-alist decoded, content not checked');
    else add('UNVERIFIED', 'pre-alist is not a list');

    postAlist = next();
    if (!(postAlist instanceof Cons)) add('UNVERIFIED', 'post-alist is not a non-empty list');

    certHash = next();
    if (isKeyword(certHash, 'TRIVIAL-BOOK-HASH')) add('INFO', 'cert-hash is :TRIVIAL-BOOK-HASH');
    else if (typeof certHash === 'bigint') add('INFO', `cert-hash is integer ${certHash}`);
    else add('UNVERIFIED', `cert-hash is not understood: ${show(certHash)}`);

    if (i < decoded.length && isKeyword(decoded[i], 'PCERT-INFO')) { i++; next(); add('INFO', 'pcert-info decoded, content not checked'); }
    if (i < decoded.length) add('UNVERIFIED', `${decoded.length - i} trailing objects not understood`);
  } else {
    add('UNVERIFIED', 'too few objects to form a certificate');
  }

  // ---- Own entry -------------------------------------------------------------
  section('Own entry');
  let own = null;
  if (postAlist instanceof Cons) {
    own = parseEntry(postAlist.car);
  }
  let lispFacts = null;
  try {
    lispFacts = fileFacts(lispFile);
  } catch (e) {
    lispFacts = null;
    add('UNVERIFIED', `cannot stat ${lispFile}: ${e.message}`);
  }
  if (!own || !own.ok) {
    add('UNVERIFIED', `own entry not understood${own && own.reason ? ': ' + own.reason : ''}`);
  } else {
    add('INFO', `recorded name ${show(own.fullName)}, user name ${JSON.stringify(own.userName)}, familiar name ${JSON.stringify(own.familiarName)}`);
    add('INFO', `recorded cert-annotations ${show(own.annotations)}`);
    if (own.hash && own.hash.kind === 'alist') {
      mode = 'alist';
      add('INFO', `recorded length ${own.hash.length}, recorded write date ${own.hash.date}`);
      if (lispFacts) {
        if (lispFacts.length === own.hash.length) add('PASS', `length ${lispFacts.length} matches the recorded length`);
        else add('FAIL', `length of ${lispFile} is ${lispFacts.length}, recorded ${own.hash.length}`);
        if (lispFacts.date === own.hash.date) add('PASS', `write date ${lispFacts.date} matches the recorded write date`);
        else add('FAIL', `write date of ${lispFile} is ${lispFacts.date}, recorded ${own.hash.date}`);
      }
    } else if (own.hash && own.hash.kind === 'integer') {
      mode = 'integer';
      add('UNVERIFIED', `own entry records integer hash ${own.hash.value}; length and write date are not recorded`);
    } else {
      add('UNVERIFIED', 'own entry book-hash is not understood');
    }
    const resolved = resolveName(own.name, certDir, options.booksRoot);
    if (resolved) {
      const same = fs.realpathSync(resolved) === fs.realpathSync(lispFile);
      add('INFO', `recorded name resolves to ${resolved}; given book is ${same ? 'the same file' : 'a different file'}`);
    } else {
      add('INFO', `recorded name ${show(own.fullName)} does not resolve on this machine`);
    }
  }

  // ---- Dependencies ----------------------------------------------------------
  section('Dependencies (one level, each entry against its own book file)');
  const deps = postAlist instanceof Cons ? listParts(postAlist).items.slice(1) : [];
  const tally = { matched: 0, mismatched: 0, unverified: 0 };
  for (const e of deps) {
    const d = parseEntry(e);
    const label = d.ok ? show(d.fullName) : '(unparsed entry)';
    if (!d.ok) { tally.unverified++; add('UNVERIFIED', `dependency ${label}: ${d.reason}`); continue; }
    if (d.hash && d.hash.kind === 'integer') { tally.unverified++; add('UNVERIFIED', `dependency ${label}: integer hash, not checked`); continue; }
    if (!d.hash || d.hash.kind !== 'alist') { tally.unverified++; add('UNVERIFIED', `dependency ${label}: hash not understood`); continue; }
    const file = resolveName(d.name, certDir, options.booksRoot);
    if (!file) { tally.unverified++; add('UNVERIFIED', `dependency ${label}: file not found`); continue; }
    let facts;
    try { facts = fileFacts(file); } catch (err) { tally.unverified++; add('UNVERIFIED', `dependency ${label}: ${err.message}`); continue; }
    const okLen = facts.length === d.hash.length;
    const okDate = facts.date === d.hash.date;
    if (okLen && okDate) { tally.matched++; }
    else {
      tally.mismatched++;
      add('FAIL', `dependency ${file}: length ${facts.length} vs recorded ${d.hash.length}, write date ${facts.date} vs recorded ${d.hash.date}`);
    }
  }
  add('INFO', `dependency entries: ${deps.length}`);
  lines.push(`  matched ${tally.matched}, mismatched ${tally.mismatched}, unverified ${tally.unverified}`);

  // ---- Mode ------------------------------------------------------------------
  section('Mode');
  if (isKeyword(certHash, 'TRIVIAL-BOOK-HASH') && mode === 'alist') {
    add('INFO', 'alist mode: the cert records length and write date per book, and no content hash');
    add('INFO', 'limit: an edit that keeps the length and the write date is not detected');
  } else if (typeof certHash === 'bigint' || mode === 'integer') {
    mode = 'integer';
    add('UNVERIFIED', 'integer (checksum) mode: the checksum is not recomputed by this checker');
  } else {
    add('UNVERIFIED', 'mode not determined');
  }

  // ---- Result ----------------------------------------------------------------
  let result;
  if (counts.FAIL > 0 || tally.mismatched > 0) result = 'FAIL';
  else if (counts.UNVERIFIED > 0 || tally.unverified > 0) result = 'UNVERIFIED';
  else result = 'PASS';
  const code = { PASS: 0, FAIL: 1, UNVERIFIED: 3 }[result];
  lines.push('', `Result: ${result}`);
  return { lines, result, code, counts, tally, mode };
}

// ---------------------------------------------------------------------------
// Command line.
// ---------------------------------------------------------------------------

function main(argv) {
  const args = argv.slice(2);
  let booksRoot = null;
  const pos = [];
  for (let k = 0; k < args.length; k++) {
    if (args[k] === '--books-root') { booksRoot = args[++k]; }
    else pos.push(args[k]);
  }
  if (pos.length !== 2 || args.includes('-h') || args.includes('--help')) {
    process.stderr.write('usage: node cert-check.mjs <file.cert> <file.lisp> [--books-root DIR]\n');
    return 2;
  }
  const [certFile, lispFile] = pos;
  try {
    fs.accessSync(certFile, fs.constants.R_OK);
    fs.accessSync(lispFile, fs.constants.R_OK);
  } catch (e) {
    process.stderr.write(`cannot read input: ${e.message}\n`);
    return 2;
  }
  let res;
  try {
    res = check(certFile, lispFile, { booksRoot: booksRoot ? path.resolve(booksRoot) : null });
  } catch (e) {
    process.stderr.write(`cannot decode certificate: ${e.message}\n`);
    return 2;
  }
  process.stdout.write(res.lines.join('\n') + '\n');
  return res.code;
}

// Run only when executed directly, so tests can import the module.
if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  process.exitCode = main(process.argv);
}
