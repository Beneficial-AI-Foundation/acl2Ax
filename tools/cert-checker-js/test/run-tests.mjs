#!/usr/bin/env node
// Runs the four required checks on books/arithmetic/abs.cert in the ACL2 8.7 tree.
// Copies of abs.lisp are made in a fresh temporary directory. Nothing in the ACL2 tree is written.
// Usage: node test/run-tests.mjs [path-to-arithmetic-dir]

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { check } from '../cert-check.mjs';

const arith = path.resolve(process.argv[2] || '/Users/cbraga/Dropbox/BAIF/SVIL2006-SFO/ACL2/acl2-8.7/books/arithmetic');
const cert = path.join(arith, 'abs.cert');
const orig = path.join(arith, 'abs.lisp');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cert-check-'));
const data = fs.readFileSync(orig);
const cases = [];

// Test 1: original book, expect PASS (exit 0).
cases.push({ name: 'original abs.lisp', file: orig, expect: 0 });

// Test 2: one character removed, length changes, expect FAIL (exit 1).
const i2 = data.indexOf('reserved');
const f2 = path.join(tmp, 't2.lisp');
fs.writeFileSync(f2, Buffer.concat([data.subarray(0, i2 + 7), data.subarray(i2 + 8)]));
cases.push({ name: 'one character removed', file: f2, expect: 1 });

// Test 3: same length, one character changed, mtime restored. Expect PASS (known limit).
const i3 = data.indexOf('Copyright');
const f3 = path.join(tmp, 't3.lisp');
fs.writeFileSync(f3, Buffer.concat([data.subarray(0, i3), Buffer.from('D'), data.subarray(i3 + 1)]));
const st = fs.statSync(orig);
fs.utimesSync(f3, st.atime, st.mtime);
cases.push({ name: 'same length, one character changed, mtime restored (known limit)', file: f3, expect: 0 });

// Test 4: one byte appended, expect FAIL (exit 1).
const f4 = path.join(tmp, 't4.lisp');
fs.writeFileSync(f4, Buffer.concat([data, Buffer.from('\n')]));
cases.push({ name: 'one byte appended', file: f4, expect: 1 });

let failures = 0;
for (const c of cases) {
  const res = check(cert, c.file, {});
  const ok = res.code === c.expect;
  if (!ok) failures++;
  console.log(`${ok ? 'ok  ' : 'BAD '} ${c.name}: result ${res.result}, exit ${res.code}, expected ${c.expect}`);
}
fs.rmSync(tmp, { recursive: true, force: true });
if (failures) { console.log(`${failures} case(s) differ from expectation`); process.exitCode = 1; }
else console.log('all cases as expected');
