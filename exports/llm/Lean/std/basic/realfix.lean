/-
Copyright (C) 2024 Kestrel Institute (http://www.kestrel.edu)
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book std/basic/realfix.lisp.
-/

/-
Translation of std/basic/realfix.lisp (ACL2 8.7 books).
Shallow embedding. The primitive `realfix` is the ACL2.Base declaration `realfix` on `Rat`
(decision 52) and `realfixC` on `CRat` (decision 71). Its ACL2 definition is
`(defun realfix (x) (if (real/rationalp x) x 0))`, and on `Rat` every value satisfies
`real/rationalp`, so `realfix` is the identity there.
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
a `defthmd`, exported as a public axiom. No hypothesis makes `x` rational, so `x` ranges over
`CRat`, with `real/rationalp` read as `realrationalpC` (decision 71). -/
public axiom «real/rationalp-of-realfix» : ∀ x : CRat, realrationalpC (realfixC x)

end ACL2.std.basic.«realfix»
