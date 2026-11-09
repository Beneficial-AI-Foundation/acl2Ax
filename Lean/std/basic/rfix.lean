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

/-- `rationalp-of-rfix`, `std/basic/rfix.lisp`, defthmd, inside `defsection std/basic/rfix`. -/
public axiom «rationalp-of-rfix» : ∀ (x : Rat), rationalp (rfix x)

end ACL2.std.basic.rfix
