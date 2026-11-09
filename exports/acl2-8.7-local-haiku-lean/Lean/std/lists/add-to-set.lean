/-
Translation of std/lists/add-to-set.lisp (ACL2 8.7 books).
Shallow embedding. The primitive `add-to-set-equal` (axioms.lisp, line 6595) is declared here as
`addToSetEqual`, because `Lean/ACL2/Base.lean` does not declare it (decision 50, fragment file).
`trueListp` is the ACL2.Base declaration (decision 50), so this module does not declare it.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/top (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.lists.«add-to-set»

/-- The ACL2 theorem `true-listp-of-add-to-set-equal` (std/lists/add-to-set.lisp, line 21).
The ACL2 `equal` of two truth values is the biconditional. -/
public axiom «true-listp-of-add-to-set-equal» : ∀ {α : Type} [DecidableEq α] (a : α) (x : List α), trueListp (addToSetEqual a x) ↔ trueListp x

/-- The ACL2 theorem `true-listp-of-add-to-set-equal-type` (std/lists/add-to-set.lisp, line 25).
Its `:rule-classes :type-prescription` is not part of the statement. -/
public axiom «true-listp-of-add-to-set-equal-type» : ∀ {α : Type} [DecidableEq α] (a : α) (x : List α), trueListp x → trueListp (addToSetEqual a x)

end ACL2.std.lists.«add-to-set»
