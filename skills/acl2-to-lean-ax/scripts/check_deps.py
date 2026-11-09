#!/usr/bin/env python3
"""Check that every generated module depends only on generated modules.

Usage: check_deps.py <project-dir> --books <acl2-books-dir>

For each Lean/**/*.lean module, the script compares its imports with the include-book forms of
the ACL2 book the module represents:
- a non-local include must be a `public import` of that book's module;
- a local include must be a plain `import` of that module;
- an import with no matching include is an error, and so is a missing one.
Exit 0 when every module agrees, 1 otherwise.
"""
import argparse, pathlib, re, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument("project")
ap.add_argument("--books", required=True)
a = ap.parse_args()
project = pathlib.Path(a.project).resolve()
lean = project / "Lean"
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))

def lean_to_book(path):
    rel = path.relative_to(lean).with_suffix("").as_posix()
    return rel

def module_name(rel):
    return ".".join(p.strip("«»") if False else p for p in rel.split("/"))

def imports_of(text):
    return [m.group(1).strip("«»") for m in re.finditer(r"^(?:public )?import\s+(\S+)", text, re.M)]

bad = 0
modules = {lean_to_book(p) for p in lean.rglob("*.lean")}
lisp_src = open(here / "order.py").read().split("# Kahn")[0]
ns = {}
sys.argv = ["order.py", a.books, "/dev/null"]
exec(lisp_src, ns)
B = pathlib.Path(a.books).resolve()

def resolve(book, target, is_sys):
    if is_sys:
        cand = target
    else:
        import os
        cand = os.path.normpath((pathlib.PurePosixPath(book).parent / target).as_posix())
    return re.sub(r"\.lisp$", "", cand)

for f in sorted(lean.rglob("*.lean")):
    rel = lean_to_book(f)
    if rel == "ACL2/Base":
        continue
    text = f.read_text(encoding="utf-8")
    lisp = (B / (rel + ".lisp")).read_text(encoding="utf-8", errors="replace")
    # Kind of each ACL2 dependency: public if any non-local include, plain if only local.
    kind = {}
    for target, is_local, is_sys in ns["scan"](lisp):
        dep = resolve(rel, target, is_sys)
        if dep not in modules:
            continue
        kind[dep] = kind.get(dep, True) and is_local  # True means only local so far
        if not is_local:
            kind[dep] = False
    # Imports in the Lean file, with their kind.
    have = {}
    for m in re.finditer(r"^(public )?import\s+(\S+)", text, re.M):
        name = m.group(2).replace("«", "").replace("»", "")
        if name == "ACL2.Base":
            continue
        have[name] = bool(m.group(1))
    def dotted(d):
        return ".".join(d.split("/"))
    for dep, only_local in sorted(kind.items()):
        name = dotted(dep)
        if name not in have:
            print(f"{rel}: ACL2 includes {dep}, which is not imported")
            bad += 1
        elif only_local and have[name]:
            print(f"{rel}: {dep} is a local include, so it must be a plain import")
            bad += 1
        elif (not only_local) and not have[name]:
            print(f"{rel}: {dep} is a non-local include, so it must be a public import")
            bad += 1
    for name in have:
        if name.replace(".", "/") not in kind:
            print(f"{rel}: imports {name}, which the ACL2 book does not include")
            bad += 1
print("ok" if bad == 0 else f"{bad} import problems")
sys.exit(0 if bad == 0 else 1)
