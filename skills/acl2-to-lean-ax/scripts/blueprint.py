#!/usr/bin/env python3
"""Write the HTML blueprint of one ACL2 book and its Lean axioms.

Usage:
  blueprint.py <project-dir> <book> --books <acl2-books-dir> --github <blob-base> --embedding shallow|deep [--no-build]

  <book>          path below the books directory without extension, for example arithmetic/abs
  --books         the ACL2 books directory the book lives in
  --github        URL prefix of the same tree on the web, for example
                  https://github.com/acl2/acl2/blob/8.7/books  (line anchors are added)
  --no-build      skip the lake build step and report the build as not run

The page states whether <book>.cert exists. If it does not, the page says the book is not
certified and omits the certificate dump.

Inputs in <project-dir>:
  Lean/<book-dir>/<book>.lean        one `axiom` per ACL2 theorem or lemma
  EMBEDDING_DECISIONS.md             general decisions, interpretation table, element decisions
Output:
  <project-dir>/blueprint/<book>-blueprint.html
The stylesheet is read from assets/style.css next to this skill.
The module highlight.py colours the ACL2 source and the Lean axiom of each theorem.
"""
import argparse
import hashlib
import html
import json
import pathlib
import re
import subprocess
import sys

SKILL = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import landing  # noqa: E402  shared table of contents
import highlight  # noqa: E402  ACL2 and Lean syntax highlighting


def thm_source(lines, name):
    """Return the ACL2 form for `name` and its 1-based start line.
    Matches defthm and defthmd anywhere on a line, so local forms such as (local (defthm ...)) are found."""
    pat = re.compile(r"\(defthmd?\s+" + re.escape(name) + r"(?=\s|\)|$)", re.M)
    m = pat.search("\n".join(lines))
    if m:
        i = "\n".join(lines)[:m.start()].count("\n")
        out, depth = [], 0
        for l in lines[i:]:
            out.append(l)
            depth += l.count("(") - l.count(")")
            if depth <= 0:
                break
        return "\n".join(out), i + 1
    raise SystemExit(f"no defthm {name} in the book")


def inline(text):
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", html.escape(text))


def md_to_html(md):
    out, in_ol, in_table = [], False, False
    for line in md.split("\n"):
        if line.startswith("## "):
            if in_ol:
                out.append("</ol>"); in_ol = False
            out.append("<h3>" + html.escape(line[3:]) + "</h3>")
        elif line.startswith("# "):
            continue
        elif re.match(r"^\d+\. ", line):
            if not in_ol:
                out.append("<ol>"); in_ol = True
            out.append("<li>" + inline(re.sub(r"^\d+\. ", "", line)) + "</li>")
        elif line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if set("".join(cells)) <= set("-"):
                continue
            if not in_table:
                out.append('<div class="tablewrap"><table>'); in_table = True
                out.append("<tr>" + "".join("<th>" + inline(c) + "</th>" for c in cells) + "</tr>")
            else:
                out.append("<tr>" + "".join("<td><code>" + html.escape(c.replace("`", "")) + "</code></td>" for c in cells) + "</tr>")
        else:
            if in_table:
                out.append("</table></div>"); in_table = False
            if line.strip() == "":
                continue
            if in_ol:
                out.append("</ol>"); in_ol = False
            out.append("<p>" + inline(line) + "</p>")
    if in_ol:
        out.append("</ol>")
    if in_table:
        out.append("</table></div>")
    return "\n".join(out)


def hexdump(data: bytes) -> str:
    rows = []
    for off in range(0, len(data), 16):
        chunk = data[off:off + 16]
        pairs = " ".join(
            (f"{chunk[i]:02x}" + (f"{chunk[i+1]:02x}" if i + 1 < len(chunk) else "  "))
            if i < len(chunk) else "    "
            for i in range(0, 16, 2)
        )
        asc = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        rows.append(f"{off:08x}: {pairs}  {asc}")
    return "\n".join(rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("book")
    ap.add_argument("--books", required=True)
    ap.add_argument("--github", required=True)
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--embedding", required=True, choices=["shallow", "deep"])
    a = ap.parse_args()
    embedding_label = "Shallow, Rat" if a.embedding == "shallow" else "Deep, ACL2 values V"
    embedding_title = "shallow embedding" if a.embedding == "shallow" else "deep embedding"

    project = pathlib.Path(a.project).resolve()
    books = pathlib.Path(a.books).resolve()
    book_rel = a.book
    book_dir, book_name = (book_rel.rsplit("/", 1) if "/" in book_rel else (".", book_rel))
    lisp_path = books / f"{book_rel}.lisp"
    cert_path = books / f"{book_rel}.cert"
    lean_path = project / "Lean" / (book_dir if book_dir != "." else "") / f"{book_name}.lean"
    out_path = project / "blueprint" / f"{book_rel.replace('/', '__')}-blueprint.html"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines = lisp_path.read_text(encoding="utf-8").split("\n")
    manifest = json.loads((project / "manifest.json").read_text(encoding="utf-8"))
    manifest_status = next((b.get("status", "") for b in manifest["books"] if b["path"] == f"{book_rel}.lisp"), "")
    excluded = manifest_status.startswith("excluded")
    lean_code = "" if not lean_path.is_file() else "\n".join(l for l in lean_path.read_text(encoding="utf-8").split("\n") if not l.startswith("--"))
    axioms = re.findall(r"(?:public |private )?axiom («[^»]*») : (.*?)(?=\n\n(?:/--.*?-/\n)?(?:public |private )?axiom|\n\nend |\Z)", lean_code, re.S)

    decisions = (project / "EMBEDDING_DECISIONS.md").read_text(encoding="utf-8")
    general_md, elem_md = decisions.split("## Element decisions", 1)
    elem_blocks = {}
    for blk in re.split(r"\n### ", "\n" + elem_md)[1:]:
        head, body = blk.split("\n", 1)
        elem_blocks[head.strip()] = body

    lisp_words = set(re.findall(r"[A-Za-z][A-Za-z0-9*+<>=/!?-]*", "\n".join(lines).lower()))
    def used_in_book(key):
        # Keep an interpretation row only when its ACL2 name occurs in the book source.
        return key.lower() in lisp_words or any(w in lisp_words for w in re.findall(r"[a-z0-9*+<>=/!?-]+", key.lower()) if len(w) > 2)
    defs_html = "\n".join(
        f'    <div class="def"><code>{html.escape(k)}</code><span>{inline(v)}</span></div>'
        for k, v in re.findall(r"^\| `([^`]+)` \| (.*?) \|$", general_md, re.M)
        if used_in_book(k)
    )

    if excluded:
        build_ok, build_note = None, f"not built: {manifest_status}"
    elif a.no_build:
        build_ok, build_note = None, "lake build not run"
    else:
        r = subprocess.run(["lake", "build"], cwd=project, capture_output=True, text=True)
        build_ok = r.returncode == 0
        build_note = "lake build passes" if build_ok else "lake build fails"
    build_cls = "bad" if build_ok is False else ("ok" if build_ok else "")

    cert_bytes = cert_path.read_bytes() if cert_path.is_file() else None
    css = (SKILL / "assets" / "style.css").read_text(encoding="utf-8")

    nodes = []
    if excluded:
        for acl2_name in dict.fromkeys(re.findall(r"^\s*\(defthmd? (\S+)", "\n".join(lines), re.M)):
            src, ln = thm_source(lines, acl2_name)
            decision = elem_blocks.get(acl2_name, "No element decisions recorded.")
            nodes.append(f"""  <section class="node">
    <div class="node-head"><span class="node-name">{html.escape(acl2_name)}</span><span class="src"><a href="{a.github}/{book_rel}.lisp#L{ln}" target="_blank" rel="noopener">{book_name}.lisp line {ln}</a> · <span>{html.escape(manifest_status)}</span></span></div>
    <div class="pair">
      <div><p class="lbl">ACL2 source</p><pre class="acl2">{highlight.acl2(src)}</pre></div>
      <div><p class="lbl">Lean axiom</p><pre>none: {html.escape(manifest_status)}</pre></div>
    </div>
    <details class="decisions"><summary>Embedding decisions for this element</summary><div class="prose">{md_to_html(decision)}</div></details>
  </section>""")
    for name_q, stmt in axioms:
        name = name_q[1:-1]
        src, ln = thm_source(lines, name)
        decision = elem_blocks.get(name, "No element decisions recorded.")
        nodes.append(f"""  <section class="node">
    <div class="node-head"><span class="node-name">{html.escape(name)}</span><span class="src"><a href="{a.github}/{book_rel}.lisp#L{ln}" target="_blank" rel="noopener">{book_name}.lisp line {ln}</a> · <span class="{build_cls}">{build_note}</span></span></div>
    <div class="pair">
      <div><p class="lbl">ACL2 source</p><pre class="acl2">{highlight.acl2(src)}</pre></div>
      <div><p class="lbl">Lean axiom</p><pre class="lean">{highlight.lean(f"axiom «{name}» : {stmt.strip()}")}</pre></div>
    </div>
    <details class="decisions"><summary>Embedding decisions for this element</summary><div class="prose">{md_to_html(decision)}</div></details>
  </section>""")

    cert_block = ""
    if cert_bytes is None:
        cert_block = f"""
  <details>
    <summary>Certificate file {book_name}.cert: absent</summary>
    <p class="sub2">No {book_name}.cert exists beside {book_rel}.lisp. The book is not certified, so its axioms have no ACL2 certificate to check against.</p>
  </details>"""
    else:
        digest = hashlib.sha256(cert_bytes).hexdigest()
        version = re.search(rb"ACL2 Version ([0-9.]+)", cert_bytes)
        version = version.group(1).decode() if version else "not stated"
        runs = re.findall(rb"[\x20-\x7e]{4,}", cert_bytes)
        paths = sorted({r.decode() for r in runs if b"/" in r and re.fullmatch(rb"[A-Za-z0-9_./\-]+", r)})
        path_items = "".join(f"<li><code>{html.escape(x)}</code></li>" for x in paths) or "<li>none found</li>"
        cert_block = f"""
  <details open>
    <summary>Certificate {book_name}.cert</summary>
    <table class="certinfo">
      <tr><td>File</td><td><a href="{cert_path.as_uri()}">{html.escape(str(cert_path))}</a></td></tr>
      <tr><td>Size</td><td>{len(cert_bytes)} bytes</td></tr>
      <tr><td>SHA-256</td><td><code>{digest}</code></td></tr>
      <tr><td>ACL2 version</td><td>{html.escape(version)}</td></tr>
      <tr><td>Book paths named in the certificate</td><td><ul>{path_items}</ul></td></tr>
    </table>
    <details>
      <summary>Hex dump of the certificate ({len(cert_bytes)} bytes)</summary>
      <pre class="acl2">{html.escape(hexdump(cert_bytes))}</pre>
    </details>
  </details>"""

    modules_all, _status = landing.collect(project)
    toc = landing.toc_html(modules_all, current=out_path.name)
    page = f"""<meta charset="utf-8">
<meta name="claude:viewport-fit-sides" content="cover">
<title>ACL2 {book_name} Blueprint</title>
<style>{css}</style>
<style>{landing.TOC_CSS}</style>
<style>{highlight.TOKEN_CSS}</style>
<div class="layout">
<aside class="toc">{toc}</aside>
<main>
  <p class="label">Blueprint, {book_rel}</p>
  <h1>ACL2 {book_name}, {embedding_title}</h1>
  <p class="sub">The theorems of the ACL2 book {book_rel}, each shown as the ACL2 source and as its Lean axiom.</p>
  {"" if cert_bytes is not None else '<p class="sub2 bad">Not certified: no .cert file exists for this book.</p>'}

  <div class="status">
    <div><span class="label">Book</span><b>{book_rel}.lisp</b></div>
    <div><span class="label">Axioms</span><b>{len(axioms)}</b></div>
    <div><span class="label">Embedding</span><b>{embedding_label}</b></div>
    <div><span class="label">ACL2 certificate</span><b class="{"ok" if cert_bytes is not None else "bad"}">{book_name}.cert {"present" if cert_bytes is not None else "absent: book not certified"}</b></div>
    <div><span class="label">Lean build</span><b class="{build_cls}">{build_note}</b></div>
  </div>

  <details class="decisions">
    <summary>Embedding decisions, general</summary>
  <div class="prose">
{md_to_html(general_md.replace("# EMBEDDING_DECISIONS", "").replace("This file records every deviation from the ACL2 source in the Lean axioms.", "Every deviation from the ACL2 source in the Lean axioms is listed here or under its element."))}
  </div>
  </details>

{("  <h2>Interpretations of ACL2 primitives and definitions</h2>\n  <div class=\"defs\">\n" + defs_html + "\n  </div>") if defs_html else ""}

  <h2>Theorems and axioms</h2>
{chr(10).join(nodes)}
{cert_block}
</main>
</div>
<script>{landing.toc_script()}</script>
"""
    out_path.write_text(page, encoding="utf-8")
    print(f"wrote {out_path} with {len(axioms)} axioms; {build_note}")


if __name__ == "__main__":
    main()
