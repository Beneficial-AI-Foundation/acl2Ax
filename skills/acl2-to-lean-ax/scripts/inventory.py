#!/usr/bin/env python3
"""Inventory the certified books of an ACL2 books tree and prepare a Lean project.

Usage: inventory.py <acl2-books-dir> <project-dir> [--cert yes|no]

A certified book is a .lisp file with a .cert file of the same name in the same directory.
The script always reports how many .lisp files have a .cert and how many do not.
--cert yes (the default) puts only certified books in the manifest.
--cert no puts every .lisp file in the manifest, with "cert": false for the uncertified ones.
Each manifest entry has "cert": true or false, and status "pending".
Creates <project-dir>/Lean/<book-dir>/ for every directory that holds a book.
The path of the books tree is taken from the argument and is not stored anywhere else.
"""
import json
import pathlib
import sys


def main() -> None:
    argv = sys.argv[1:]
    cert_mode = "yes"
    if "--cert" in argv:
        i = argv.index("--cert")
        if i + 1 >= len(argv) or argv[i + 1] not in ("yes", "no"):
            sys.exit("--cert takes yes or no")
        cert_mode = argv[i + 1]
        del argv[i:i + 2]
    any_lisp = cert_mode == "no"
    args = argv
    if len(args) != 2:
        sys.exit(__doc__)
    books = pathlib.Path(args[0]).resolve()
    project = pathlib.Path(args[1]).resolve()
    if not books.is_dir():
        sys.exit(f"not a directory: {books}")

    lisp_files = sorted(books.rglob("*.lisp"))
    certified, uncertified = [], []
    for lisp in lisp_files:
        rel = lisp.relative_to(books).as_posix()
        if lisp.with_suffix(".cert").is_file():
            certified.append(rel)
        else:
            uncertified.append(rel)
    print(f".lisp files: {len(lisp_files)}; with .cert: {len(certified)}; without .cert: {len(uncertified)}")

    entries = [{"path": p, "cert": True, "status": "pending"} for p in certified]
    if any_lisp:
        entries += [{"path": p, "cert": False, "status": "pending"} for p in uncertified]
    entries.sort(key=lambda e: e["path"])
    manifest = {"source": str(books), "books": entries}
    project.mkdir(parents=True, exist_ok=True)
    (project / "manifest.json").write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")

    dirs = sorted({str(pathlib.PurePosixPath(e["path"]).parent) for e in entries})
    for d in dirs:
        (project / "Lean" / d).mkdir(parents=True, exist_ok=True)
    print(f"{len(entries)} books in manifest (--cert {cert_mode}), {len(dirs)} directories, manifest at {project / 'manifest.json'}")


if __name__ == "__main__":
    main()
