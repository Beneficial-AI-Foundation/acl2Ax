"""Dependency order of certified books from non-local include-book forms.

Reads every certified .lisp under BOOKS, finds include-book forms, local ones included, resolves each target to a book path, and writes a topological order.
Usage: order2.py BOOKS OUT
"""
"""Dependency order of certified books, with local includes as edges.

Usage: order.py <acl2-books-dir> <out-file>

Every include-book form outside comments and outside quoted or defmacro bodies is an edge,
local ones included. Writes one book per line, `<path>.lisp`, dependencies first. Ties are broken
by name. Exits 1 when the graph has a cycle, which ACL2 does not allow.
"""
import os, pathlib, re, sys, heapq
if len(sys.argv) != 3:
    sys.exit(__doc__)
B = pathlib.Path(sys.argv[1]).resolve()
OUT = pathlib.Path(sys.argv[2])
books = sorted(p.relative_to(B).as_posix()[:-5] for p in B.rglob("*.lisp") if p.with_suffix(".cert").is_file())
bset = set(books)

def scan(text):
    """Yield (include_target, is_local, is_system) for each include-book form outside comments."""
    i, n, stack = 0, len(text), []   # stack holds (head_is_local) for each open paren
    out = []
    while i < n:
        c = text[i]
        if text.startswith("#|", i):
            d, i = 1, i + 2
            while i < n and d:
                if text.startswith("#|", i): d += 1; i += 2
                elif text.startswith("|#", i): d -= 1; i += 2
                else: i += 1
            continue
        if c == ";":
            while i < n and text[i] != "\n": i += 1
            continue
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            if i >= 0 and out == [] or True:
                pass
            i = j + 1
            continue
        if c == "(":
            m = re.match(r"\(\s*([^\s()\"]*)", text[i:i + 80])
            head = m.group(1).lower() if m else ""
            quoted = i > 0 and text[i - 1] in "'`"
            if quoted:
                head = "quote"
            stack.append(head)
            i += 1
            if head == "include-book":
                m2 = re.match(r'\(\s*include-book\s+"([^"]+)"([^()]*)', text[i - 1:i + 400])
                if m2:
                    opts = m2.group(2)
                    enclosing = stack[:-1]
                    is_local = "local" in enclosing
                    is_dead = any(h in ("quote", "defmacro") for h in enclosing)
                    if not is_dead:
                        out.append((m2.group(1), is_local, ":dir :system" in opts))
                    # local status: any enclosing open form is local
            continue
        if c == ")":
            if stack: stack.pop()
            i += 1
            continue
        i += 1
    return out

edges = {b: set() for b in books}
for b in books:
    text = (B / (b + ".lisp")).read_text(encoding="utf-8", errors="replace")
    for target, is_local, is_sys in scan(text):
        if is_sys:
            cand = target
        else:
            # Resolve "..": a relative include is taken from the directory of the including book.
            cand = os.path.normpath((pathlib.PurePosixPath(b).parent / target).as_posix())
        cand = re.sub(r"\.lisp$", "", cand)
        if cand in bset and cand != b:
            edges[b].add(cand)

# Kahn's algorithm, ties broken by the name order used for the manifest.
indeg = {b: 0 for b in books}
rev = {b: [] for b in books}
for b, deps in edges.items():
    for d in deps:
        indeg[b] += 1
        rev[d].append(b)
heap = [b for b in books if indeg[b] == 0]
heapq.heapify(heap)
order = []
while heap:
    b = heapq.heappop(heap)
    order.append(b)
    for c in rev[b]:
        indeg[c] -= 1
        if indeg[c] == 0:
            heapq.heappush(heap, c)
cyc = [b for b in books if indeg[b] > 0]
OUT.write_text("\n".join(o + ".lisp" for o in order) + "\n")
print(f"books {len(books)}, edges {sum(len(v) for v in edges.values())}, ordered {len(order)}, in cycles {len(cyc)}")
if cyc:
    print("cycle members, first 10:", cyc[:10])
    sys.exit(1)
