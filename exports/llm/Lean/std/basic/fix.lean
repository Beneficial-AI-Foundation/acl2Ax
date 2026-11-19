/-
Copyright (C) 2024 Kestrel Institute (http://www.kestrel.edu)
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book std/basic/fix.lisp.
-/

/-
Translation of std/basic/fix.lisp (ACL2 8.7 books).
Shallow embedding. The function `fix` and the predicate `acl2-numberp` are the
ACL2.Base declarations `fixC` and `acl2NumberPC` on `CRat` (decisions 50 and 71), so this module
declares neither.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«fix»

/-- The ACL2 theorem `fix-when-acl2-numberp` (std/basic/fix.lisp, lines 21 to 23).
`acl2-numberp` does not make `x` rational, so `x` ranges over `CRat` (decision 71). `acl2-numberp` is `True` on `CRat`, and the hypothesis is kept as an implication. -/
public axiom «fix-when-acl2-numberp» : ∀ x : CRat, acl2NumberPC x → fixC x = x

/-- The ACL2 theorem `acl2-numberp-of-fix` (std/basic/fix.lisp, lines 25 to 26), a `defthmd`
exported by the defsection. Its statement is `(acl2-numberp (fix x))`, with `x` over `CRat`
(decision 71). -/
public axiom «acl2-numberp-of-fix» : ∀ x : CRat, acl2NumberPC (fixC x)

end ACL2.std.basic.«fix»
