#!/usr/bin/env python3
"""Find the copyright and license of ACL2 books, and keep them in the files translated from them.

Usage:
  licenses.py check <acl2-books-dir> <book>...
  licenses.py apply <project-dir> [<book>...] --books <acl2-books-dir> [--copyright LINE]...
  licenses.py page <acl2-books-dir> <book> <html-file> [--lean <lean-file>]

  <book>   path below the books directory, with or without .lisp, for example std/basic/nfix

check   Prints the copyright and the license file of each book. Exits with 2 if a book's license is
        not identified. Stop and check such a book by hand before export.
apply   For each book (default: every book with a module under <project-dir>/Lean), writes or
        replaces the comment at the top of its module, copies its license file to
        <project-dir>/LICENSES/acl2/<path in the ACL2 source tree>, writes or replaces the notice
        block of its blueprint page if the page exists, and rewrites <project-dir>/NOTICE.md. It also
        copies the license of acl2Ax, whose templates the project uses, to
        <project-dir>/LICENSES/acl2Ax/LICENSE unless <project-dir>/LICENSE is that license.
        --copyright adds a translator's copyright line, for example
        "Copyright (c) 2026, Beneficial AI Foundation". Lines already in a module's comment are kept;
        to remove one, edit the comment by hand. Every book of the project must be identified, and
        every file is checked before the first one is written: on any problem, nothing changes.
page    Writes or replaces the notice block of one blueprint page, for pages whose name differs from
        <project-dir>/blueprint/<book>-blueprint.html. The copyright lines are read from the module
        comment given by --lean.

The license of a book is found from the comments before its first form (line comments and #| |#
block comments), in this order:
  1. they name a copyright and "the LICENSE file distributed with ACL2" or 3BSD-mod.txt;
  2. they say "See the top-level <dir> LICENSE file": the copyright is read from that file;
  3. they name no copyright and no license: the nearest LICENSE file in the book's directory or a
     parent below the books directory, whose copyright is read from it.
A copyright or license notice in a comment after the first form makes the book not identified. The
license file, apart from its copyright lines, must be one of the texts in KNOWN_LICENSES, which were
reviewed by hand. To accept another text, review it and add the key that `check` prints.
"""
import argparse
import hashlib
import html
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import landing  # noqa: E402  the list of books that have a module

SKILL = pathlib.Path(__file__).resolve().parents[1]

# Reviewed license texts of the ACL2 8.7 sources, keyed by license_key. All are 3-clause BSD.
KNOWN_LICENSES = {
    "8aa307036c28814e": "LICENSE of ACL2",
    "990db609e1f9a2ea": "books/3BSD-mod.txt (Kestrel's 3-clause BSD variant)",
    "012514a97a8cb0a9": "books/arithmetic-2/LICENSE",
    "cf8ea2c5d28d51e3": "books/arithmetic-3/LICENSE",
    "6baf708e3b75749f": "books/acl2s/LICENSE",
}

HEADER_RE = re.compile(
    r"\A/-\n((?:Copyright[^\n]*\n)+)License: 3-clause BSD, see [^\n]*\n"
    r"Translated from the ACL2 book [^\n]*\n-/\n\n?")
NOTICE_RE = re.compile(r"  <!-- acl2-license -->\n.*?\n  <!-- /acl2-license -->", re.S)
PAGE_ANCHOR = '  </div>\n\n  <details class="decisions">\n    <summary>Embedding decisions, general</summary>'
LATE_NOTICE_RE = re.compile(r"^(Copyright\b|License:)|GNU General Public|\bGPL\b", re.I)


def book_rel(book):
    """Return the book path with .lisp."""
    return book if book.endswith(".lisp") else f"{book}.lisp"


def comments(text):
    """Return (leading, late): the comment lines before the first form and those after it, without
    semicolons. Block comments #| |# may nest, as in check_axioms.strip_block_comments."""
    leading, late, depth, i, seen_form = [], [], 0, 0, False
    current = []
    def flush():
        (late if seen_form else leading).extend(l.strip() for l in "".join(current).split("\n"))
        current.clear()
    while i < len(text):
        if text.startswith("#|", i):
            depth += 1
            i += 2
        elif depth and text.startswith("|#", i):
            depth -= 1
            i += 2
            if depth == 0:
                flush()
        elif depth:
            current.append(text[i])
            i += 1
        elif text[i] == ";":
            j = text.find("\n", i)
            j = len(text) if j < 0 else j
            current.append(text[i:j].lstrip(";"))
            flush()
            i = j
        else:
            if not text[i].isspace():
                seen_form = True
            i += 1
    return [l for l in leading if l], [l for l in late if l]


def copyright_lines(text):
    return [l.strip() for l in text.split("\n") if l.strip().startswith("Copyright")]


def license_key(text):
    """A fingerprint of a license text without its copyright lines and whitespace differences."""
    keep = [l for l in text.split("\n")
            if not l.strip().startswith("Copyright") and l.strip() != "All rights reserved."]
    return hashlib.sha256(" ".join(" ".join(keep).split()).encode()).hexdigest()[:16]


def book_license(books, book):
    """Return a dict: book, copyright (list of lines), license (path in the ACL2 source tree or
    None), bsd3 (True if identified) and note (how it was found, or why it was not)."""
    books = pathlib.Path(books).resolve()
    rel = book_rel(book)
    info = {"book": rel, "copyright": [], "license": None, "bsd3": False, "note": ""}
    if pathlib.PurePosixPath(rel).is_absolute() or ".." in pathlib.PurePosixPath(rel).parts:
        info["note"] = "the book path must be relative to the books directory"
        return info
    lisp = books / rel
    if not lisp.is_file():
        info["note"] = "no such book"
        return info
    root = books.parent
    leading, late = comments(lisp.read_text(encoding="utf-8", errors="replace"))
    stray = [l for l in late if LATE_NOTICE_RE.search(l)]
    if stray:
        info["note"] = f"a copyright or license notice follows the first form: {stray[0]!r}"
        return info
    joined = " ".join(leading)
    cr = [c for c in leading if c.startswith("Copyright")]
    names_license = re.search(r"licen[cs]e|\bGNU\b|\bGPL\b", joined, re.I)
    lic = None
    m = re.search(r"See the top-level (\S+) LICENSE file", joined)
    if m:
        lic = next((d / "LICENSE" for d in lisp.parents if d.name == m.group(1) and books in d.parents),
                   books / m.group(1) / "LICENSE")
        info["note"] = "the book names its directory's LICENSE file"
    elif cr and re.search(r"License:.*3BSD-mod\.txt", joined):
        lic = books / "3BSD-mod.txt"
        info["note"] = "book header"
    elif cr and re.search(r"License:.*LICENSE file distributed with\s+ACL2", joined):
        lic = root / "LICENSE"
        info["note"] = "book header"
    elif not cr and not names_license:
        lic = next((d / "LICENSE" for d in lisp.parents
                    if books in d.parents and (d / "LICENSE").is_file()), None)
        info["note"] = "nearest LICENSE file; the book names none"
    if lic is None or not lic.is_file():
        info["note"] = "no copyright and license found that this script recognises"
        return info
    text = lic.read_text(encoding="utf-8", errors="replace")
    info["copyright"] = cr or copyright_lines(text)
    info["license"] = lic.relative_to(root).as_posix()
    key = license_key(text)
    if key not in KNOWN_LICENSES:
        info["note"] = (f"{info['license']} is not one of the reviewed license texts (key {key}); "
                        "review it and add the key to KNOWN_LICENSES in licenses.py")
    elif not info["copyright"]:
        info["note"] = "no copyright line"
    else:
        info["bsd3"] = True
    return info


def header(info, lines):
    return ("/-\n" + "".join(f"{l}\n" for l in lines)
            + f"License: 3-clause BSD, see LICENSES/acl2/{info['license']}.\n"
            + f"Translated from the ACL2 book {info['book']}.\n-/\n\n")


def merged(*groups):
    """Concatenate lists of lines, keeping the first occurrence of each line."""
    out = []
    for g in groups:
        out.extend(l for l in g if l not in out)
    return out


def module_copyright(lean):
    """Return the copyright lines of a module's comment, or [] if it has none."""
    if not lean or not pathlib.Path(lean).is_file():
        return []
    m = HEADER_RE.match(pathlib.Path(lean).read_text(encoding="utf-8"))
    return m.group(1).splitlines() if m else []


def notice_html(books, book, lean=None, lines=None):
    """Return the notice block of a blueprint page, without a trailing newline. The copyright lines
    are `lines`, or those of the module comment, or the book's. Raises ValueError if the book's
    license is not identified."""
    info = book_license(books, book)
    if not info["bsd3"]:
        raise ValueError(f"{info['book']}: license not identified: {info['note']}")
    lines = lines or module_copyright(lean) or info["copyright"]
    text = (pathlib.Path(books).resolve().parent / info["license"]).read_text(encoding="utf-8")
    body = ("<p>" + "<br>".join(html.escape(l) for l in lines) + "</p>\n"
            f"<p>The ACL2 source on this page is from {html.escape(info['book'])}. The page and "
            f"the Lean translation are under a 3-clause BSD license, the ACL2 file "
            f"{html.escape(info['license'])}:</p>\n"
            f"<pre>{html.escape(text.rstrip())}</pre>")
    summary = "Copyright and license: " + html.escape("; ".join(lines))
    return ("  <!-- acl2-license -->\n  <details class=\"decisions\">\n"
            f"    <summary>{summary}</summary>\n  <div class=\"prose\">\n{body}\n  </div>\n  </details>\n"
            "  <!-- /acl2-license -->")


def with_notice(page_text, notice):
    """Return the page text with the notice block written or replaced. Raises ValueError if the
    page has no place for it."""
    if NOTICE_RE.search(page_text):
        return NOTICE_RE.sub(lambda _: notice, page_text, count=1)
    if page_text.count(PAGE_ANCHOR) == 1:
        return page_text.replace(PAGE_ANCHOR, PAGE_ANCHOR.replace("\n\n", f"\n\n{notice}\n", 1))
    raise ValueError("no place for the notice (expected the status row before the general decisions)")


def notice_md(infos, translator, acl2ax_license):
    rows = "".join(
        f"| `{i['book']}` | {'<br>'.join(l.replace('|', '&#124;') for l in i['copyright'])} | "
        f"`LICENSES/acl2/{i['license']}` |\n" for i in infos)
    also = ("\nThe translations also carry: " + "; ".join(translator) + ".\n") if translator else ""
    holder = "; ".join(copyright_lines((SKILL / "LICENSE").read_text(encoding="utf-8")))
    if acl2ax_license == "LICENSE":
        own = ("The other files of the project, among them `Lean/ACL2/Base.lean`, `EMBEDDING_DECISIONS.md`\n"
               "and the stylesheets and scripts of the blueprint pages, are acl2Ax's own:\n"
               f"{holder}, under the BSD 3-Clause license in `LICENSE`.\n")
    else:
        own = ("The project was made with the acl2-to-lean-ax skill of acl2Ax. The files that start from\n"
               "its templates (`Lean/ACL2/Base.lean`, `EMBEDDING_DECISIONS.md`) and the stylesheets and\n"
               f"scripts of the blueprint pages are {holder},\n"
               f"under the BSD 3-Clause license in `{acl2ax_license}`.\n")
    return ("# Notices\n\n"
            "This file is written by `licenses.py`. Do not edit it by hand.\n\n"
            "The Lean modules in `Lean/` and their blueprint pages translate or quote the ACL2 books below.\n"
            "Each keeps the copyright of its book and is under the book's license. The license texts are\n"
            "copied under `LICENSES/acl2/`, at their paths in the ACL2 source tree.\n"
            f"{also}\n{own}"
            f"\n| Book | Copyright | License |\n| --- | --- | --- |\n{rows}")


def apply(project, books, chosen, copyright_opt):
    project = pathlib.Path(project).resolve()
    books = pathlib.Path(books).resolve()
    modules = [m[0] for m in landing.collect(project)[0]]
    chosen = [book_rel(b)[:-5] for b in chosen] or modules
    infos = {b: book_license(books, b) for b in sorted(set(modules) | set(chosen))}
    bad = [i for i in infos.values() if not i["bsd3"]]
    for i in bad:
        print(f"{i['book']}: not identified: {i['note']}", file=sys.stderr)
    if bad:
        print("NOTICE.md lists every module, so every module's book must be identified.", file=sys.stderr)
        sys.exit(2)
    # Plan every write first, so that a problem stops the run before any file changes.
    writes = {}
    def plan(path, data):
        if isinstance(data, str):
            data = data.encode("utf-8")
        if not path.is_file() or path.read_bytes() != data:
            writes[path] = data
    def copy(src, dst):
        if dst.is_file() and dst.read_bytes() != src.read_bytes():
            sys.exit(f"{dst} differs from {src}; check which one is right")
        plan(dst, src.read_bytes())
    own = SKILL / "LICENSE"
    if (project / "LICENSE").is_file() and (project / "LICENSE").read_bytes() == own.read_bytes():
        acl2ax_license = "LICENSE"
    else:
        acl2ax_license = "LICENSES/acl2Ax/LICENSE"
        copy(own, project / acl2ax_license)
    headers = {}
    for b in modules:
        lean = project / "Lean" / f"{b}.lean"
        s = lean.read_text(encoding="utf-8")
        old = HEADER_RE.match(s)
        lines = merged(infos[b]["copyright"], old.group(1).splitlines() if old else [],
                       copyright_opt if b in chosen else [])
        headers[b] = lines
        if b in chosen:
            plan(lean, header(infos[b], lines) + (s[old.end():] if old else s))
    for b in chosen:
        info = infos[b]
        copy(books.parent / info["license"], project / "LICENSES" / "acl2" / info["license"])
        page = project / "blueprint" / f"{b.replace('/', '__')}-blueprint.html"
        if page.is_file():
            try:
                plan(page, with_notice(page.read_text(encoding="utf-8"),
                                       notice_html(books, b, lines=headers.get(b) or info["copyright"])))
            except ValueError as e:
                sys.exit(f"{page}: {e}")
    translator = merged(*[[l for l in headers[b] if l not in infos[b]["copyright"]] for b in sorted(modules)])
    plan(project / "NOTICE.md", notice_md([infos[b] for b in sorted(modules)], translator, acl2ax_license))
    for path, data in writes.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    print(f"applied to {len(chosen)} books; NOTICE.md lists {len(modules)}; {len(writes)} files written")


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("check", "apply", "page"):
        sys.exit(__doc__)
    cmd = sys.argv[1]
    ap = argparse.ArgumentParser(prog=f"licenses.py {cmd}", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    if cmd == "check":
        ap.add_argument("books")
        ap.add_argument("book", nargs="+")
        args = ap.parse_args(sys.argv[2:])
        status = 0
        for b in args.book:
            i = book_license(args.books, b)
            if i["bsd3"]:
                print(f"{i['book']}: 3-clause BSD, {i['license']}; {'; '.join(i['copyright'])}")
            else:
                print(f"{i['book']}: not identified: {i['note']}")
                status = 2
        sys.exit(status)
    if cmd == "apply":
        ap.add_argument("project")
        ap.add_argument("book", nargs="*")
        ap.add_argument("--books", required=True)
        ap.add_argument("--copyright", action="append", default=[])
        # Intermixed parsing accepts the books before or after the options.
        args = ap.parse_intermixed_args(sys.argv[2:])
        apply(args.project, args.books, args.book, args.copyright)
    if cmd == "page":
        ap.add_argument("books")
        ap.add_argument("book")
        ap.add_argument("html")
        ap.add_argument("--lean")
        args = ap.parse_args(sys.argv[2:])
        page = pathlib.Path(args.html)
        if not page.is_file():
            sys.exit(f"{page}: no such file")
        try:
            s = page.read_text(encoding="utf-8")
            new = with_notice(s, notice_html(args.books, args.book, args.lean))
        except ValueError as e:
            print(f"{page}: {e}", file=sys.stderr)
            sys.exit(2)
        if new != s:
            page.write_text(new, encoding="utf-8")
        print(f"{args.html}: {'notice written' if new != s else 'unchanged'}")


if __name__ == "__main__":
    main()
