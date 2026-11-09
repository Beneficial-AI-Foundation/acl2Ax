/-
Translation of std/basic/fix.lisp (ACL2 8.7 books).
Shallow embedding. The function `fix` and the predicate `acl2NumberP` are the
ACL2.Base declarations (decision 50), so this module declares neither.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«fix»

/-- The ACL2 theorem `fix-when-acl2-numberp` (std/basic/fix.lisp, lines 21 to 23).
Variables range over `Rat`, and `acl2-numberp` is `True` on `Rat`, so the hypothesis is kept as an implication. -/
public axiom «fix-when-acl2-numberp» : ∀ (x : Rat), acl2NumberP x → fix x = x

/-- The ACL2 theorem `acl2-numberp-of-fix` (std/basic/fix.lisp, lines 25 to 26), a `defthmd`
exported by the defsection. Its statement is `(acl2-numberp (fix x))`. -/
public axiom «acl2-numberp-of-fix» : ∀ (x : Rat), acl2NumberP (fix x)

end ACL2.std.basic.«fix»
