#!/usr/bin/env python3
"""Write the landing page blueprint/index.html of a project: project information and a table of contents
in a left pane, with one section per top-level directory of translated books.

Usage:
  landing.py <project-dir> --books <acl2-books-dir> [--embedding shallow|deep]

Reads manifest.json, the module files under Lean/, EMBEDDING_DECISIONS.md and lean-toolchain.
Output: <project-dir>/blueprint/index.html
"""
import argparse
import datetime
import html
import json
import pathlib
import re
import sys

PAGE_CSS = """
:root {
  --bg: #fafaf9; --panel: #ffffff; --ink: #1c1c1e; --muted: #6b6b70; --line: #e4e4e7;
  --accent: #2f5bd3; --ok: #15803d; --bad: #b42318; --code: #f4f4f5;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #111114; --panel: #18181c; --ink: #ececf0; --muted: #9a9aa3; --line: #2a2a30;
    --accent: #8ea8ff; --ok: #4ade80; --bad: #f97066; --code: #1f1f25;
  }
}
:root[data-theme="dark"] {
  --bg: #111114; --panel: #18181c; --ink: #ececf0; --muted: #9a9aa3; --line: #2a2a30;
  --accent: #8ea8ff; --ok: #4ade80; --bad: #f97066; --code: #1f1f25;
}
* { box-sizing: border-box; }
html, body { margin: 0; background: var(--bg); color: var(--ink);
  font: 15px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; }
.layout { display: grid; grid-template-columns: 300px 1fr; min-height: 100vh; }
.toc { position: sticky; top: 0; height: 100vh; overflow-y: auto; border-right: 1px solid var(--line);
  background: var(--panel); padding: 20px 16px; }
.toc h1 { font-size: 15px; margin: 0 0 4px; }
.toc .sub { color: var(--muted); font-size: 12px; margin-bottom: 16px; }
.toc input { width: 100%; padding: 6px 8px; border: 1px solid var(--line); border-radius: 6px;
  background: var(--bg); color: var(--ink); margin-bottom: 12px; }
.toc a { color: var(--ink); text-decoration: none; display: block; padding: 4px 8px; border-radius: 6px; }
.toc a:hover { background: var(--code); }
.toc .group { margin-top: 10px; }
.toc .group > a { font-weight: 600; }
.toc .group ul { list-style: none; margin: 2px 0 0 10px; padding: 0; border-left: 1px solid var(--line); }
.toc .group li a { font-size: 13px; color: var(--muted); padding: 2px 8px; }
.toc .count { color: var(--muted); font-weight: 400; font-size: 12px; }
main { padding: 32px 40px; max-width: 1080px; }
header h1 { font-size: 26px; margin: 0 0 4px; }
header p { color: var(--muted); margin: 0 0 24px; }
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin-bottom: 28px; }
.card { background: var(--panel); border: 1px solid var(--line); border-radius: 10px; padding: 14px 16px; }
.card .k { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .04em; }
.card .v { font-size: 22px; font-weight: 600; margin-top: 2px; }
.card .v.ok { color: var(--ok); } .card .v.bad { color: var(--bad); }
dl.info { display: grid; grid-template-columns: max-content 1fr; gap: 6px 18px; background: var(--panel);
  border: 1px solid var(--line); border-radius: 10px; padding: 16px 20px; margin: 0 0 28px; }
dl.info dt { color: var(--muted); }
dl.info dd { margin: 0; word-break: break-all; }
code { font: 13px ui-monospace, Menlo, monospace; background: var(--code); padding: 1px 5px; border-radius: 4px; }
section.dir { margin-bottom: 28px; scroll-margin-top: 16px; }
section.dir h2 { font-size: 18px; margin: 0 0 10px; display: flex; gap: 10px; align-items: baseline; }
section.dir h2 .n { color: var(--muted); font-size: 13px; font-weight: 400; }
table { width: 100%; border-collapse: collapse; background: var(--panel); border: 1px solid var(--line);
  border-radius: 10px; overflow: hidden; }
th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--line); vertical-align: top; }
th { font-size: 12px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); background: var(--code); }
tr:last-child td { border-bottom: none; }
td a { color: var(--accent); text-decoration: none; font-family: ui-monospace, Menlo, monospace; font-size: 13px; }
td a:hover { text-decoration: underline; }
td.num { text-align: right; font-variant-numeric: tabular-nums; }
.pill { display: inline-block; font-size: 12px; padding: 1px 8px; border-radius: 999px; border: 1px solid var(--line); }
.pill.ok { color: var(--ok); border-color: var(--ok); }
.pill.ex { color: var(--muted); }
.pill.pend { color: var(--bad); border-color: var(--bad); }
ol.rules { background: var(--panel); border: 1px solid var(--line); border-radius: 10px; padding: 16px 16px 16px 44px; margin: 0; }
ol.rules li { margin: 0 0 8px; }
.rules-intro { color: var(--muted); margin: -4px 0 10px; }
.foot { color: var(--muted); font-size: 12px; margin-top: 32px; }
@media (max-width: 860px) {
  .layout { grid-template-columns: 1fr; }
  .toc { position: static; height: auto; border-right: none; border-bottom: 1px solid var(--line); }
  main { padding: 20px 16px; }
}
"""

JS = """
const q = document.getElementById('filter');
q.addEventListener('input', () => {
  const v = q.value.toLowerCase();
  document.querySelectorAll('.toc li').forEach(li => {
    li.style.display = li.textContent.toLowerCase().includes(v) ? '' : 'none';
  });
});
"""


TOC_CSS = PAGE_CSS[:PAGE_CSS.index("main { padding")] + """
.toc li.current a { background: var(--code); color: var(--accent); font-weight: 600; }
.toc ul { list-style: none; margin: 2px 0 0 10px; padding: 0; border-left: 1px solid var(--line); }
.layout main { min-width: 0; }
@media (max-width: 860px) {
  .layout { grid-template-columns: 1fr; }
  .toc { position: static; height: auto; border-right: none; border-bottom: 1px solid var(--line); }
}
"""


def collect(project):
    """Return (modules, status): modules is a list of (book, axiom count, page file name or None)."""
    project = pathlib.Path(project)
    manifest = json.loads((project / "manifest.json").read_text(encoding="utf-8"))
    status = {b["path"][:-5]: b.get("status", "") for b in manifest["books"]}
    lean_root = project / "Lean"
    modules = []
    for p in sorted(lean_root.rglob("*.lean")):
        rel = p.relative_to(lean_root)
        if rel.parts[0] == "ACL2":
            continue
        book = "/".join(rel.parts)[:-5]
        page = project / "blueprint" / f"{book.replace('/', '__')}-blueprint.html"
        modules.append((book, module_axiom_count(p), page.name if page.is_file() else None))
    return modules, status


def toc_html(modules, current=None):
    """Return the contents of the left pane: overview link and one group per top-level directory."""
    groups = {}
    for book, n, page in modules:
        top = book.split("/")[0] if "/" in book else "(root)"
        groups.setdefault(top, []).append((book, n, page))
    parts = ['<h1>ACL2 to Lean blueprint</h1>',
             f'<div class="sub">{len(modules)} modules, {sum(n for _, n, _ in modules)} axioms</div>',
             '<input id="filter" type="search" placeholder="Filter books">',
             '<div><a href="index.html">Overview</a></div>',
             '<div><a href="index.html#rules">Embedding rules</a></div>']
    for top in sorted(groups):
        anchor = "d-" + re.sub(r"[^a-z0-9]+", "-", top.lower()).strip("-")
        items = []
        for book, n, page in groups[top]:
            label = html.escape(book[len(top) + 1:] if "/" in book else book)
            cls = ' class="current"' if current and page == current else ""
            target = html.escape(page) if page else "#"
            items.append(f'<li{cls}><a href="{target}">{label}</a></li>')
        parts.append(f'<div class="group"><a href="index.html#{anchor}">{html.escape(top)} '
                     f'<span class="count">({len(groups[top])})</span></a><ul>{"".join(items)}</ul></div>')
    return "".join(parts)


def toc_script():
    return JS


def module_axiom_count(path):
    text = path.read_text(encoding="utf-8")
    return len(re.findall(r"^(?:public |private )?axiom «", text, re.M))


def plural(n, word):
    return f"{n} {word}" if n == 1 else f"{n} {word}s"


def status_pill(st):
    if st.startswith(("axioms", "no theorems")):
        return '<span class="pill ok">built</span>'
    if st.startswith("excluded"):
        return f'<span class="pill ex">{html.escape(st)}</span>'
    return f'<span class="pill pend">{html.escape(st or "pending")}</span>'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("--books", required=True)
    ap.add_argument("--embedding", default="shallow", choices=["shallow", "deep"])
    a = ap.parse_args()
    project = pathlib.Path(a.project).resolve()
    manifest = json.loads((project / "manifest.json").read_text(encoding="utf-8"))
    status = {b["path"][:-5]: b.get("status", "") for b in manifest["books"]}

    lean_root = project / "Lean"
    modules = []
    for p in sorted(lean_root.rglob("*.lean")):
        rel = p.relative_to(lean_root)
        if rel.parts[0] == "ACL2":
            continue
        book = "/".join(rel.parts)[:-5]
        page = project / "blueprint" / f"{book.replace('/', '__')}-blueprint.html"
        modules.append((book, module_axiom_count(p), page.name if page.is_file() else None))

    groups = {}
    for book, n, page in modules:
        top = book.split("/")[0] if "/" in book else "(root)"
        groups.setdefault(top, []).append((book, n, page))

    total_axioms = sum(n for _, n, _ in modules)
    built = sum(1 for s in status.values() if s.startswith(("axioms", "no theorems")))
    excluded = sum(1 for s in status.values() if s.startswith("excluded"))
    pending = sum(1 for s in status.values() if s == "pending")
    total = len(status)
    # Decisions are numbered 1 to N in the general list. The element sections have their own numbered
    # items, so the count is the highest decision number, not the number of numbered lines.
    decisions = max(int(n) for n in re.findall(r"^(\d+)\. ", (project / "EMBEDDING_DECISIONS.md").read_text(encoding="utf-8"), re.M))
    toolchain = (project / "lean-toolchain").read_text(encoding="utf-8").strip()
    decision_text = (project / "EMBEDDING_DECISIONS.md").read_text(encoding="utf-8")
    general = decision_text.split("## Interpretation table", 1)[0]
    # Decisions that apply to every book. Element-specific decisions (CRat, alists, primitives) are excluded.
    GENERAL_RULES = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 30, 32, 35, 40, 41, 48}
    rules = [(n, t) for n, t in re.findall(r"^(\d+)\. (.+)$", general, re.M) if int(n) in GENERAL_RULES]
    today = datetime.date.today().isoformat()

    toc_items, sections = [], []
    for top in sorted(groups):
        anchor = "d-" + re.sub(r"[^a-z0-9]+", "-", top.lower()).strip("-")
        items = []
        for book, n, page in groups[top]:
            label = html.escape(book[len(top) + 1:] if "/" in book else book)
            target = html.escape(page) if page else "#"
            items.append(f'<li><a href="{target}">{label}</a></li>')
        toc_items.append(f'<div class="group"><a href="#{anchor}">{html.escape(top)} '
                         f'<span class="count">({len(groups[top])})</span></a><ul>{"".join(items)}</ul></div>')
        rows = []
        for book, n, page in groups[top]:
            st = status.get(book, "")
            name = html.escape(book[len(top) + 1:] if "/" in book else book)
            link = f'<a href="{html.escape(page)}">{name}</a>' if page else name
            rows.append(f'<tr><td>{link}</td><td class="num">{n}</td><td>{status_pill(st)}</td></tr>')
        sections.append(
            f'<section class="dir" id="{anchor}"><h2>{html.escape(top)} '
            f'<span class="n">{plural(len(groups[top]), "module")}, {plural(sum(n for _, n, _ in groups[top]), "axiom")}</span></h2>'
            f'<table><tr><th>Book</th><th class="num">Axioms</th><th>Status</th></tr>{"".join(rows)}</table></section>')

    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ACL2 to Lean blueprint</title>
<style>{PAGE_CSS}</style></head>
<body>
<div class="layout">
<aside class="toc">
  <h1>ACL2 to Lean blueprint</h1>
  <div class="sub">{len(modules)} modules, {total_axioms} axioms</div>
  <input id="filter" type="search" placeholder="Filter books">
  <div><a href="#overview">Overview</a></div>
  <div><a href="#rules">Embedding rules</a></div>
  {"".join(toc_items)}
</aside>
<main>
<header id="overview">
  <h1>ACL2 books translated to Lean</h1>
  <p>Shallow embedding of the certified ACL2 books in <code>{html.escape(a.books)}</code>.
  Each book has one Lean module of axioms and one blueprint page with the ACL2 source, the Lean axiom
  and the embedding decisions.</p>
</header>
<div class="cards">
  <div class="card"><div class="k">Modules</div><div class="v">{len(modules)}</div></div>
  <div class="card"><div class="k">Axioms</div><div class="v">{total_axioms}</div></div>
  <div class="card"><div class="k">Books built</div><div class="v ok">{built}</div></div>
  <div class="card"><div class="k">Excluded</div><div class="v">{excluded}</div></div>
  <div class="card"><div class="k">Pending</div><div class="v bad">{pending}</div></div>
  <div class="card"><div class="k">Decisions</div><div class="v">{decisions}</div></div>
</div>
<dl class="info">
  <dt>ACL2 source</dt><dd><code>{html.escape(a.books)}</code></dd>
  <dt>Embedding</dt><dd>{html.escape(a.embedding)}</dd>
  <dt>Lean toolchain</dt><dd><code>{html.escape(toolchain)}</code></dd>
  <dt>Books in manifest</dt><dd>{total} ({built} built, {excluded} excluded, {pending} pending)</dd>
  <dt>Generated</dt><dd>{today}</dd>
</dl>
<section class="dir" id="rules"><h2>Embedding rules <span class="n">{len(rules)} general decisions</span></h2>
<p class="rules-intro">These rules apply to every book. Each element of a book may add its own decision, shown on its blueprint page.</p>
<ol class="rules">{"".join(f'<li>{re.sub(r"`([^`]+)`", lambda m: "<code>" + m.group(1) + "</code>", html.escape(t))}</li>' for _, t in rules)}</ol></section>
{"".join(sections)}
<p class="foot">Excluded books are listed with their reason. Pending books have no module yet.</p>
</main>
</div>
<script>{JS}</script>
</body></html>
"""
    out = project / "blueprint" / "index.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page, encoding="utf-8")
    print(f"wrote {out}: {len(modules)} modules, {total_axioms} axioms")


if __name__ == "__main__":
    sys.exit(main())
