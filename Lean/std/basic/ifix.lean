/-
Translation of std/basic/ifix.lisp (ACL2 8.7 books).
Shallow embedding. The ACL2 function `ifix` is the ACL2.Base declaration `ifixR` (decision 29),
so this module declares no function.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.ifix

/-- The ACL2 theorem `ifix-when-integerp` (std/basic/ifix.lisp, line 21).
`(implies (integerp x) (equal (ifix x) x))`, with `ifix` read as `ifixR`. -/
public axiom «ifix-when-integerp» : ∀ (x : Rat), integerp x → ifixR x = x

/-- The ACL2 theorem `integerp-of-ifix` (std/basic/ifix.lisp, line 25), a `defthmd`.
`(integerp (ifix x))`, with `ifix` read as `ifixR`. -/
public axiom «integerp-of-ifix» : ∀ (x : Rat), integerp (ifixR x)

end ACL2.std.basic.ifix
