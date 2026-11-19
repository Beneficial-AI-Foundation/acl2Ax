/-
Copyright (C) 2024 Kestrel Institute (http://www.kestrel.edu)
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book std/basic/nfix.lisp.
-/

/-
Translation of the ACL2 book `std/basic/nfix.lisp` (ACL2 8.7 books).
Shallow embedding. The function `nfix` and the predicate `natp` are the ACL2.Base declarations
`nfix` and `natp` on `Rat` (decisions 50 and 52), and `nfixC` and `natpC` on `CRat` (decisions 69
and 71).
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«nfix»

/-- The ACL2 theorem `nfix-when-natp` (std/basic/nfix.lisp, line 21). -/
public axiom «nfix-when-natp» : ∀ x : Rat, natp x → nfix x = x

/-- The ACL2 theorem `natp-of-nfix` (std/basic/nfix.lisp, line 25), a `defthmd`. No hypothesis
makes `x` rational, so `x` ranges over `CRat` (decision 71). -/
public axiom «natp-of-nfix» : ∀ x : CRat, natpC (nfixC x)

end ACL2.std.basic.«nfix»
