/-
Translation of the ACL2 book `std/system/arity.lisp` (acl2-8.7 books tree).

Pending import: `include-book "xdoc/top" :dir :system` has no module yet
(Lean/xdoc is empty). It is documentation only, and the statement of this book does not use it.

The system functions `arity`, `function-symbolp` and `consp` are not in ACL2.Base. They are
declared below in the namespace ACL2, for the coordinator to move to Base.lean (decision 41).
`consp` is restricted to the symbols, so the cons case of `fn` is excluded (see the fragment file).
-/

module

public import ACL2.Base

namespace ACL2.«std».«system».«arity»

public section

/-- ACL2 `defthm` `arity-iff`: `(arity fn wrld)` is non-nil exactly when `fn` is a cons or a function symbol. -/
public axiom «arity-iff» : ∀ (fn : ACLSymbol) (wrld : World), (arity fn wrld).isSome = true ↔ (consp fn ∨ «function-symbolp» fn wrld)

end

end ACL2.«std».«system».«arity»
