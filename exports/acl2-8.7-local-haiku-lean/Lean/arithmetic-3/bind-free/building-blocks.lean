/-
Stub for ACL2 `arithmetic-3/bind-free/building-blocks.lisp`. Excluded: metaprogramming (SKILL.md Scope).

The book is not translated. Its functions take ACL2 terms as data (`numeric-constant-p`,
`fns-present`, `negative-addends-p`) or the metafunction context `mfc` with `state`
(`rewriting-goal-literal`, `proveably-integer`, `proveably-non-zero`). The book has no defthm.
Metaprogramming is out of scope for this version of the skill, so this module declares no axiom.

Recorded in EMBEDDING_DECISIONS.md, section "Excluded books: metaprogramming".
-/

module

public import ACL2.Base

namespace ACL2.«arithmetic-3».«bind-free».«building-blocks»

end ACL2.«arithmetic-3».«bind-free».«building-blocks»
