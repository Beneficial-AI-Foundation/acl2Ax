#!/usr/bin/env python3
"""Check one generated Lean module against the ACL2 book it represents.

Usage: check_axioms.py <project-dir> <book> --books <acl2-books-dir> --check N|converge

  <book>     path below the books directory without extension, for example arithmetic/binomial
  --check    N, a positive integer: stop after N passes.
             converge: stop at the first pass after which the module, the decisions file and
             Base.lean are unchanged since the previous pass, and the names agree.

Compares the names of the axioms in Lean/<book>.lean with the names of the
`defthm`, `defthmd` and `defaxiom` forms in <book>.lisp, including forms inside `local`.
A name that is recorded in EMBEDDING_DECISIONS.md under a `### name` heading whose text
contains the word "excluded" is expected to be absent from the module.

Each call is one pass. The pass count, a hash of the checked files and the result are written to
the manifest entry of the book under "check". The output ends with "stop" when the stopping rule
is met, or "continue" when another pass, after any edits, is needed.
Exit 0 on stop with names agreeing, 1 on continue, 2 on usage, missing input or an unknown book.
This script checks names only. It does not check statements. The statements are checked
by reading the ACL2 source against the Lean axiom, as SKILL.md describes.
"""
import argparse
import hashlib
import json
import pathlib
import re
import sys


def strip_block_comments(text):
    """Remove #| ... |# block comments, which may nest."""
    out, depth, i = [], 0, 0
    while i < len(text):
        if text.startswith("#|", i):
            depth += 1
            i += 2
        elif depth and text.startswith("|#", i):
            depth -= 1
            i += 2
        elif depth == 0:
            out.append(text[i])
            i += 1
        else:
            i += 1
    return "".join(out)


def strip_line_comments(text):
    """Remove ; comments to the end of each line. A ; inside a string is not treated specially."""
    return "\n".join(line.split(";", 1)[0] for line in text.split("\n"))


def acl2_names(lisp_text):
    lisp_text = strip_line_comments(strip_block_comments(lisp_text))
    names = []
    for m in re.finditer(r"\(defthmd?\s+([^\s()]+)", lisp_text):
        names.append(m.group(1))
    for m in re.finditer(r"\(defaxiom\s+([^\s()]+)", lisp_text):
        names.append(m.group(1))
    return names


def lean_names(lean_text):
    lean_text = "\n".join(l for l in lean_text.split("\n") if not l.lstrip().startswith("--"))
    return [m.group(1)[1:-1] for m in re.finditer(r"axiom («[^»]*»)", lean_text)]


def excluded_names(decisions_text):
    out = set()
    for blk in re.split(r"\n### ", "\n" + decisions_text)[1:]:
        head, _, body = blk.partition("\n")
        if "excluded" in body.lower():
            out.add(head.strip())
    return out


def parse_check(value):
    if value == "converge":
        return value
    if value.isdigit() and int(value) >= 1:
        return int(value)
    sys.exit("--check takes a positive integer or converge")


def state_hash(paths):
    h = hashlib.sha256()
    for p in paths:
        h.update(p.read_bytes())
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("book")
    ap.add_argument("--books", required=True)
    ap.add_argument("--check", required=True)
    a = ap.parse_args()
    rule = parse_check(a.check)

    project = pathlib.Path(a.project).resolve()
    book_dir, _, book_name = a.book.rpartition("/")
    lisp = pathlib.Path(a.books).resolve() / f"{a.book}.lisp"
    lean = project / "Lean" / book_dir / f"{book_name}.lean"
    decisions = project / "EMBEDDING_DECISIONS.md"
    base = project / "Lean" / "ACL2" / "Base.lean"
    for p in (lisp, lean):
        if not p.is_file():
            print(f"missing input: {p}")
            sys.exit(2)

    manifest_path = project / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entry = next((b for b in manifest["books"] if b["path"] == f"{a.book}.lisp"), None)
    if entry is None:
        print(f"no manifest entry for {a.book}.lisp")
        sys.exit(2)
    prev = entry.get("check", {"passes": 0, "hash": None})
    state = state_hash([p for p in (lean, decisions, base) if p.is_file()])
    unchanged = prev.get("hash") == state
    excluded = excluded_names(decisions.read_text(encoding="utf-8")) if decisions.is_file() else set()

    want = [n for n in acl2_names(lisp.read_text(encoding="utf-8")) if n not in excluded]
    have = lean_names(lean.read_text(encoding="utf-8"))
    want_set, have_set = set(want), set(have)

    problems = 0
    for n in want:
        if n not in have_set:
            print(f"MISSING axiom for ACL2 form {n}")
            problems += 1
    for n in have:
        if n not in want_set:
            print(f"EXTRA axiom {n}: no matching ACL2 defthm, defthmd or defaxiom")
            problems += 1
    for n in sorted(have_set):
        if have.count(n) > 1:
            print(f"DUPLICATE axiom {n}")
            problems += 1
    passes = prev.get("passes", 0) + 1
    clean = problems == 0
    if isinstance(rule, int):
        stop = passes >= rule
        reason = f"{passes} of {rule} passes"
    else:
        stop = clean and unchanged
        reason = "no change since the previous pass" if stop else "changes since the previous pass or first pass"
    entry["check"] = {
        "requested": a.check,
        "passes": passes,
        "hash": state,
        "result": "clean" if clean else "discrepancies remain",
    }
    manifest_path.write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")

    print(f"{a.book}: {len(want)} ACL2 forms, {len(have)} axioms, {problems} discrepancies")
    print(f"pass {passes}: {reason}")
    print("stop" if stop else "continue")
    sys.exit(0 if stop and clean else 1)


if __name__ == "__main__":
    main()
