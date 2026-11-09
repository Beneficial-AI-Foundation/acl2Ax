/-
Translation of the ACL2 book `std/basic/nfix.lisp` (ACL2 8.7 books).
Shallow embedding. The function `nfix` is the ACL2.Base declaration (decision 50).
The predicate `natp` is not in ACL2.Base, so it is declared here (see the fragment file).
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«nfix»

/-- The ACL2 theorem `nfix-when-natp` (std/basic/nfix.lisp, line 21). -/
public axiom «nfix-when-natp» : ∀ x : Rat, natp x → nfix x = x

/-- The ACL2 theorem `natp-of-nfix` (std/basic/nfix.lisp, line 25), a `defthmd`. -/
public axiom «natp-of-nfix» : ∀ x : Rat, natp (nfix x)

end ACL2.std.basic.«nfix»
