#!/usr/bin/env node
// check.js -- Node harness for cert_check.wasm.
// Usage: node check.js [--books-dir DIR] <file.cert> <file.lisp>
// Exit status: 0 PASS, 1 FAIL, 2 UNVERIFIED or usage error.
"use strict";
const fs = require("fs");
const path = require("path");

const UT_UNIX_OFFSET = 2208988800n;

function defaultBooksDir(certPath) {
  // The nearest ancestor directory named "books" of the cert.
  let d = path.resolve(path.dirname(certPath));
  for (;;) {
    if (path.basename(d) === "books") return d;
    const up = path.dirname(d);
    if (up === d) return "";
    d = up;
  }
}

async function main() {
  const args = process.argv.slice(2);
  let booksDir = null;
  if (args[0] === "--books-dir") {
    booksDir = args[1];
    args.splice(0, 2);
  }
  if (args.length !== 2) {
    console.error("usage: node check.js [--books-dir DIR] <file.cert> <file.lisp>");
    return 2;
  }
  const certPath = path.resolve(args[0]);
  const lispPath = path.resolve(args[1]);
  if (booksDir === null) booksDir = defaultBooksDir(certPath);

  const wasmBytes = fs.readFileSync(path.join(__dirname, "cert_check.wasm"));
  let memory = null;
  const view = () => Buffer.from(memory.buffer);
  const readName = (ptr, len) => view().subarray(ptr, ptr + len).toString("utf8");

  const imports = {
    env: {
      // host_read_file(path, path_len, dst, cap) -> byte count or -1
      host_read_file(pathPtr, pathLen, dstPtr, cap) {
        try {
          const data = fs.readFileSync(readName(pathPtr, pathLen));
          if (data.length > cap) return -1;
          data.copy(view(), dstPtr);
          return data.length;
        } catch (e) {
          return -1;
        }
      },
      // host_file_info(path, path_len, out) writes [size, write date] as int64
      host_file_info(pathPtr, pathLen, outPtr) {
        try {
          const st = fs.statSync(readName(pathPtr, pathLen));
          const dv = new DataView(memory.buffer);
          dv.setBigInt64(outPtr, BigInt(st.size), true);
          const writeDate = BigInt(Math.floor(st.mtimeMs / 1000)) + UT_UNIX_OFFSET;
          dv.setBigInt64(outPtr + 8, writeDate, true);
          return 0;
        } catch (e) {
          return -1;
        }
      },
    },
  };

  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  const x = instance.exports;
  memory = x.memory;

  const certBytes = fs.readFileSync(certPath);
  const lispBytes = fs.readFileSync(lispPath);
  const lispWriteDate = BigInt(Math.floor(fs.statSync(lispPath).mtimeMs / 1000)) + UT_UNIX_OFFSET;
  if (certBytes.length > x.cc_cert_cap() || lispBytes.length > x.cc_lisp_cap()) {
    console.error("input file too large for the static buffers");
    return 2;
  }
  const booksBytes = Buffer.from(booksDir, "utf8");
  if (booksBytes.length > 0) {
    booksBytes.copy(view(), x.cc_books_buf());
    x.cc_set_books_dir_len(booksBytes.length);
  }
  certBytes.copy(view(), x.cc_cert_buf());
  lispBytes.copy(view(), x.cc_lisp_buf());

  const verdict = x.cc_run(certBytes.length, lispBytes.length, lispWriteDate);
  const outPtr = x.cc_out_buf();
  let end = outPtr;
  const mem = view();
  while (mem[end] !== 0) end++;
  process.stdout.write(mem.subarray(outPtr, end).toString("utf8"));
  return verdict;
}

main().then((code) => process.exit(code), (err) => {
  console.error(err);
  process.exit(2);
});
