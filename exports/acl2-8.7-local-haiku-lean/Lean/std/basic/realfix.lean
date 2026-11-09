/-
Translation of std/basic/realfix.lisp (ACL2 8.7 books).
Shallow embedding. The primitive `realfix` is not in ACL2.Base, so it is declared here
(see the fragment file, part (a)). Its ACL2 definition is
`(defun realfix (x) (if (real/rationalp x) x 0))`, and on `Rat` every value satisfies
`real/rationalp`, so `realfix` is the identity.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«realfix»

/-- The ACL2 theorem `realfix-when-real/rationalp` (std/basic/realfix.lisp, lines 21 to 23).
The hypothesis `real/rationalp x` is `realrationalp x`. -/
public axiom «realfix-when-real/rationalp» : ∀ (x : Rat), realrationalp x → realfix x = x

/-- The ACL2 theorem `real/rationalp-of-realfix` (std/basic/realfix.lisp, lines 25 to 26),
a `defthmd`, exported as a public axiom. -/
public axiom «real/rationalp-of-realfix» : ∀ (x : Rat), realrationalp (realfix x)

end ACL2.std.basic.«realfix»
