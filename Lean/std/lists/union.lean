/-
Translation of std/lists/union.lisp (ACL2 8.7 books).
Shallow embedding. The primitive `union-equal` (axioms.lisp, line 7476) is declared in
`Lean/ACL2/Base.lean` as `unionEqual` (decision 53, fragment file), so this module does not declare it.
`trueListp` is the ACL2.Base declaration (decision 50), so this module does not declare it.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/top (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.lists.«union»

/-- The ACL2 theorem `true-listp-of-union-equal` (std/lists/union.lisp, line 21).
The ACL2 `equal` of two truth values is the biconditional. -/
public axiom «true-listp-of-union-equal» : ∀ {α : Type} [DecidableEq α] (x y : List α), trueListp (unionEqual x y) ↔ trueListp y

/-- The ACL2 theorem `true-listp-of-union-equal-type` (std/lists/union.lisp, line 25).
Its `:rule-classes :type-prescription` is not part of the statement. -/
public axiom «true-listp-of-union-equal-type» : ∀ {α : Type} [DecidableEq α] (x y : List α), trueListp y → trueListp (unionEqual x y)

end ACL2.std.lists.«union»
