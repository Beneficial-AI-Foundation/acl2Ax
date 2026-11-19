/-
Copyright (C) 2024 Kestrel Institute (http://www.kestrel.edu)
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book std/basic/rfix.lisp.
-/

/-
Translation of ACL2 book `std/basic/rfix` (Standard Basic Library, Kestrel Institute).
The book includes `xdoc/constructors` from the system directory, which is not in the
books tree, so it has no module and is not imported here.
-/

module

public import ACL2.Base

namespace ACL2.std.basic.rfix

/-- `rfix-when-rationalp`, `std/basic/rfix.lisp`, defthm, inside `defsection std/basic/rfix`. -/
public axiom «rfix-when-rationalp» : ∀ (x : Rat), rationalp x → rfix x = x

/-- `rationalp-of-rfix`, `std/basic/rfix.lisp`, defthmd, inside `defsection std/basic/rfix`.
No hypothesis makes `x` rational, so `x` ranges over `CRat`, with `rfix` read as `rfixC` and
`rationalp` as `realrationalpC` (decision 71). -/
public axiom «rationalp-of-rfix» : ∀ x : CRat, realrationalpC (rfixC x)

end ACL2.std.basic.rfix
