"""Generate the HTML blueprint for one ACL2 book and its Lean axioms.

Usage: python3 tools/blueprint/build_blueprint.py [book]   (default book: abs)

Inputs:
  ACL2_BOOKS          the ACL2 source books directory (SVIL2006-SFO/ACL2/acl2-8.7/books)
  Lean/<dir>/<book>.lean   the Lean axioms, one `axiom` per ACL2 theorem
  EMBEDDING_DECISIONS.md   general decisions and element decisions
  tools/blueprint/style.css   stylesheet inlined into the page
Output:
  tools/blueprint/<book>-blueprint.html
"""
import html
import pathlib
import re
import subprocess
import sys

PROJ = pathlib.Path(__file__).resolve().parents[2]
ACL2_BOOKS = pathlib.Path("/Users/cbraga/Dropbox/BAIF/SVIL2006-SFO/ACL2/acl2-8.7/books")
GITHUB = "https://github.com/acl2/acl2/blob/8.7"

book = sys.argv[1] if len(sys.argv) > 1 else "abs"
book_dir, book_name = book.split("/") if "/" in book else ("arithmetic", book)
book_rel = f"{book_dir}/{book_name}"

lisp_path = ACL2_BOOKS / f"{book_rel}.lisp"
cert_path = ACL2_BOOKS / f"{book_rel}.cert"
lean_path = PROJ / "Lean" / book_dir / f"{book_name}.lean"
out_path = PROJ / "tools" / "blueprint" / f"{book_name}-blueprint.html"

lines = lisp_path.read_text(encoding="utf-8").split("\n")
lean = lean_path.read_text(encoding="utf-8")
lean_code = "\n".join(l for l in lean.split("\n") if not l.startswith("--"))
axioms = re.findall(r"axiom («[^»]*») : (.*?)(?=\n\naxiom|\n\nend ACL2)", lean_code, re.S)


def thm_source(name):
    """Return the ACL2 form for `name` and its 1-based start line.
    Local theorems are indented inside a (local ...) form, so the match allows leading spaces."""
    pat = re.compile(r"^\s*\(defthm " + re.escape(name) + r"(\s|\)|$)")
    for i, line in enumerate(lines):
        if pat.match(line):
            indent = len(line) - len(line.lstrip())
            out = []
            depth = 0
            for l in lines[i:]:
                out.append(l)
                depth += l.count("(") - l.count(")")
                if depth <= 0:
                    break
            return "\n".join(out), i + 1
    raise SystemExit(f"no defthm {name} in {lisp_path}")


def inline(text):
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", html.escape(text))


def md_to_html(md):
    out, in_ol, in_table = [], False, False
    for line in md.split("\n"):
        if line.startswith("## "):
            if in_ol:
                out.append("</ol>")
                in_ol = False
            out.append("<h3>" + html.escape(line[3:]) + "</h3>")
        elif line.startswith("# "):
            continue
        elif re.match(r"^\d+\. ", line):
            if not in_ol:
                out.append("<ol>")
                in_ol = True
            out.append("<li>" + inline(re.sub(r"^\d+\. ", "", line)) + "</li>")
        elif line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if set("".join(cells)) <= set("-"):
                continue
            if not in_table:
                out.append('<div class="tablewrap"><table>')
                in_table = True
                out.append("<tr>" + "".join("<th>" + inline(c) + "</th>" for c in cells) + "</tr>")
            else:
                out.append("<tr>" + "".join("<td><code>" + html.escape(c.replace("`", "")) + "</code></td>" for c in cells) + "</tr>")
        else:
            if in_table:
                out.append("</table></div>")
                in_table = False
            if line.strip() == "":
                continue
            if in_ol:
                out.append("</ol>")
                in_ol = False
            out.append("<p>" + inline(line) + "</p>")
    if in_ol:
        out.append("</ol>")
    if in_table:
        out.append("</table></div>")
    return "\n".join(out)


decisions = (PROJ / "EMBEDDING_DECISIONS.md").read_text(encoding="utf-8")
general_md, elem_md = decisions.split("## Element decisions", 1)
elem_blocks = {}
for blk in re.split(r"\n### ", "\n" + elem_md)[1:]:
    head, body = blk.split("\n", 1)
    elem_blocks[head.strip()] = body

# Certificate: binary, so the page shows an xxd hex dump of the full file.
hex_dump = subprocess.run(["xxd", str(cert_path)], capture_output=True, text=True, check=True).stdout
cert_size = cert_path.stat().st_size

css = (PROJ / "tools" / "blueprint" / "style.css").read_text(encoding="utf-8")

# Interpretation rows come from the table in EMBEDDING_DECISIONS.md.
defs_rows = []
for row in re.findall(r"^\| `([^`]+)` \| (.*?) \|$", general_md, re.M):
    defs_rows.append(f'    <div class="def"><code>{html.escape(row[0])}</code><span>{inline(row[1])}</span></div>')
defs_html = "\n".join(defs_rows)

# Build status from the real lake build, not from a fixed string.
build = subprocess.run(["lake", "build"], cwd=PROJ, capture_output=True, text=True)
build_ok = build.returncode == 0
build_text = "lake build passes" if build_ok else "lake build fails"
build_cls = "ok" if build_ok else "bad"

nodes = []
for name_q, stmt in axioms:
    name = name_q[1:-1]
    src, ln = thm_source(name)
    nodes.append((name, stmt.strip(), src, ln))

node_html = []
for name, stmt, src, ln in nodes:
    node_html.append(f"""  <section class="node">
    <div class="node-head"><span class="node-name">{html.escape(name)}</span><span class="src"><a href="{GITHUB}/books/{book_rel}.lisp#L{ln}" target="_blank" rel="noopener">{book_name}.lisp line {ln}</a> · <span class="ok">ACL2 certified</span> · <span class="{build_cls}">{"Lean builds" if build_ok else "Lean build fails"}</span></span></div>
    <div class="pair">
      <div><p class="lbl">ACL2 source</p><pre class="acl2">{html.escape(src)}</pre></div>
      <div><p class="lbl">Lean axiom</p><pre>axiom «{html.escape(name)}» : {html.escape(stmt)}</pre></div>
    </div>
    <details class="decisions"><summary>Embedding decisions for this element</summary><div class="prose">{md_to_html(elem_blocks.get(name, "No element decisions recorded."))}</div></details>
  </section>""")

page = f"""<meta name="claude:viewport-fit-sides" content="cover">
<title>ACL2 {book_name} Blueprint</title>
<style>{css}</style>
<main>
  <p class="label">Blueprint, {book_rel}</p>
  <h1>ACL2 {book_name}, shallow embedding</h1>
  <p class="sub">The theorems of the ACL2 book {book_rel}, each shown as the ACL2 source and as its Lean axiom over the rational numbers.</p>

  <div class="status">
    <div><span class="label">Book</span><b>{book_rel}.lisp</b></div>
    <div><span class="label">Axioms</span><b>{len(nodes)}</b></div>
    <div><span class="label">Embedding</span><b>Shallow, Rat</b></div>
    <div><span class="label">ACL2 certification</span><b class="ok">{book_name}.cert present</b></div>
    <div><span class="label">Lean build</span><b class="{build_cls}">{build_text}</b></div>
  </div>

  <details class="decisions">
    <summary>Embedding decisions, general</summary>
  <div class="prose">
{md_to_html(general_md.replace("# EMBEDDING_DECISIONS", "").replace("This file records every deviation from the ACL2 source in the Lean axioms.", "Every deviation from the ACL2 source in the Lean axioms is listed here or under its element."))}
  </div>
  </details>

  <h2>Interpretations of ACL2 primitives and definitions</h2>
  <div class="defs">
{defs_html}
  </div>

  <h2>Theorems and axioms</h2>
{chr(10).join(node_html)}

  <details>
    <summary>Certificate file {book_name}.cert (ACL2 book certificate)</summary>
    <p class="sub2">Source: SVIL2006-SFO/ACL2/acl2-8.7/books/{book_rel}.cert, not tracked in the GitHub repository at tag 8.7.</p>
    <p class="sub2">The file is binary, so the page shows its full content as a hex dump (xxd format, {cert_size} bytes).</p>
    <pre class="acl2">{html.escape(hex_dump)}</pre>
  </details>
</main>
"""

out_path.write_text(page, encoding="utf-8")
print(f"wrote {out_path} with {len(nodes)} axioms")
