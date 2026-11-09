#!/usr/bin/env python3
"""Syntax highlighting for the blueprint pages, done when the page is generated.

Each function takes source text and returns escaped HTML. Tokens are wrapped in
<span class="tk-..."> elements. The pages need no script and no network access.

  acl2(src)   ACL2 forms
  lean(src)   Lean 4 statements

Token classes: tk-kw keyword, tk-name defined name, tk-const constant or keyword symbol,
tk-type type, tk-num number, tk-str string, tk-com comment, tk-op operator, tk-par parenthesis.
The colours are in TOKEN_CSS, for the light and the dark theme.
"""
import html
import re

TOKEN_CSS = """
:root {
  --tk-kw: #7a2f8f; --tk-name: #1f6b67; --tk-const: #9a3412; --tk-type: #1d4f91;
  --tk-num: #9a3412; --tk-str: #7a4a00; --tk-com: #6a7183; --tk-op: #4a5266; --tk-par: #8a8f9c;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --tk-kw: #c9a0e8; --tk-name: #7fd0c9; --tk-const: #f0a080; --tk-type: #8fb8f0;
    --tk-num: #f0a080; --tk-str: #e0b070; --tk-com: #8a92a3; --tk-op: #b4bac8; --tk-par: #6f7686;
  }
}
:root[data-theme="dark"] {
  --tk-kw: #c9a0e8; --tk-name: #7fd0c9; --tk-const: #f0a080; --tk-type: #8fb8f0;
  --tk-num: #f0a080; --tk-str: #e0b070; --tk-com: #8a92a3; --tk-op: #b4bac8; --tk-par: #6f7686;
}
.tk-kw { color: var(--tk-kw); font-weight: 600; }
.tk-name { color: var(--tk-name); font-weight: 600; }
.tk-const { color: var(--tk-const); }
.tk-type { color: var(--tk-type); }
.tk-num { color: var(--tk-num); }
.tk-str { color: var(--tk-str); }
.tk-com { color: var(--tk-com); font-style: italic; }
.tk-op { color: var(--tk-op); }
.tk-par { color: var(--tk-par); }
"""


def _span(cls, text):
    return f'<span class="tk-{cls}">{html.escape(text)}</span>' if cls else html.escape(text)


# ---------------------------------------------------------------- ACL2

# Heads that introduce a named event. The symbol after the head is the defined name.
ACL2_DEF_HEADS = {
    "defthm", "defthmd", "defun", "defund", "defmacro", "defconst", "defstub", "defaxiom",
    "defun-nx", "defund-nx", "defun-sk", "defchoose", "defequiv", "defcong", "defrefinement",
    "deftheory", "deflabel", "defstobj", "defabsstobj", "defpkg", "defrule", "defruled",
    "define", "defsection", "defxdoc", "defevaluator", "defn", "defnd", "defthm-flag",
}
# Heads highlighted as keywords when they follow an opening parenthesis.
ACL2_FORM_HEADS = {
    "implies", "and", "or", "not", "if", "iff", "equal", "cond", "case", "let", "let*", "b*",
    "mv", "mv-let", "mv-nth", "lambda", "quote", "local", "in-package", "include-book",
    "encapsulate", "progn", "mutual-recursion", "declare", "xargs", "in-theory", "enable",
    "disable", "e/d", "with-output", "make-event", "table", "set-ignore-ok", "verify-guards",
    "forall", "exists", "force", "syntaxp", "bind-free", "case-match", "er", "prog2$", "mbe",
    "mbt", "the", "flet", "when", "unless", "program", "logic",
}
ACL2_CONSTS = {"t", "nil"}

_ACL2_RE = re.compile(
    r"""
    (?P<com>\#\|.*?\|\#|;[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<chr>\#\\(?:[A-Za-z]+|.))
  | (?P<par>[()])
  | (?P<quo>['`]|,@?)
  | (?P<bar>\|[^|]*\|)
  | (?P<sym>[^\s()'`,";|]+)
    """,
    re.S | re.X,
)
_ACL2_NUM = re.compile(r"[-+]?(?:\d+(?:/\d+)?|\d*\.\d+)$|#[xXbBoO][0-9a-fA-F]+$")


def acl2(src):
    """Return `src`, an ACL2 form, as highlighted HTML."""
    out, pos = [], 0
    at_head = False      # the previous token is an opening parenthesis
    expect_name = False  # the previous symbol is a defining head
    for m in _ACL2_RE.finditer(src):
        out.append(html.escape(src[pos:m.start()]))
        pos = m.end()
        kind, text = m.lastgroup, m.group()
        if kind == "com":
            out.append(_span("com", text))
            continue  # a comment keeps the head and name state
        if kind in ("str", "chr"):
            out.append(_span("str", text))
        elif kind == "par":
            out.append(_span("par", text))
            at_head = text == "("
            if text == "(":
                expect_name = False
            continue
        elif kind == "quo":
            out.append(_span("op", text))
            continue
        else:
            low = text.lower()
            if expect_name:
                cls = "name"
            elif at_head and low in ACL2_DEF_HEADS:
                cls = "kw"
            elif at_head and low in ACL2_FORM_HEADS:
                cls = "kw"
            elif low.startswith(":") and len(low) > 1:
                cls = "const"
            elif low in ACL2_CONSTS:
                cls = "const"
            elif _ACL2_NUM.match(text):
                cls = "num"
            else:
                cls = ""
            out.append(_span(cls, text))
            expect_name = at_head and low in ACL2_DEF_HEADS
            at_head = False
            continue
        at_head = False
        expect_name = False
    out.append(html.escape(src[pos:]))
    return "".join(out)


# ---------------------------------------------------------------- Lean

LEAN_KEYWORDS = {
    "axiom", "theorem", "lemma", "def", "abbrev", "instance", "structure", "inductive", "class",
    "opaque", "noncomputable", "partial", "unsafe", "private", "public", "protected", "namespace",
    "end", "open", "import", "section", "variable", "universe", "fun", "let", "in", "have", "show",
    "from", "if", "then", "else", "match", "with", "do", "return", "where", "by", "at", "forall",
    "exists", "deriving", "mutual", "set_option", "attribute", "example",
}
LEAN_CONSTS = {"True", "False", "true", "false", "none", "some"}
LEAN_SORTS = {"Prop", "Type", "Sort"}

_LEAN_RE = re.compile(
    r"""
    (?P<com>/-.*?-/|--[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<name>«[^»]*»)
  | (?P<num>\d+(?:\.\d+)?)
  | (?P<id>[^\W\d][\w'!?]*(?:\.[^\W\d][\w'!?]*)*)
  | (?P<bind>[∀∃λΠΣ])
  | (?P<par>[()\[\]{}⟨⟩])
  | (?P<op>:=|[→←↔∧∨¬≤≥≠=<>+\-*/:,|^∘×∣%∈∉⊆∩∪·.]+)
    """,
    re.S | re.X,
)


def lean(src):
    """Return `src`, a Lean 4 statement, as highlighted HTML."""
    out, pos = [], 0
    expect_name = False  # the previous token is a declaration keyword
    for m in _LEAN_RE.finditer(src):
        out.append(html.escape(src[pos:m.start()]))
        pos = m.end()
        kind, text = m.lastgroup, m.group()
        if kind == "com":
            out.append(_span("com", text))
            continue
        if kind == "name":
            # A guillemet name is the defined name only right after a declaration keyword.
            out.append(_span("name" if expect_name else "", text))
        elif kind == "id":
            if text in LEAN_KEYWORDS:
                out.append(_span("kw", text))
                expect_name = text in ("axiom", "theorem", "lemma", "def", "abbrev", "opaque")
                continue
            if expect_name:
                cls = "name"
            elif text in LEAN_CONSTS:
                cls = "const"
            elif text in LEAN_SORTS or text.rsplit(".", 1)[-1][0].isupper():
                cls = "type"
            else:
                cls = ""
            out.append(_span(cls, text))
        elif kind == "bind":
            out.append(_span("kw", text))
        else:
            out.append(_span(kind, text))
        expect_name = False
    out.append(html.escape(src[pos:]))
    return "".join(out)


if __name__ == "__main__":
    import sys
    fn = {"acl2": acl2, "lean": lean}[sys.argv[1]]
    sys.stdout.write(fn(sys.stdin.read()))
