/-
Copyright (C) 2014, University of Wyoming
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book arithmetic/sumlist.lisp.
-/

import ACL2.Base

namespace ACL2

/-- ACL2 `sumlist`: `(if (consp x) (+ (car x) (sumlist (cdr x))) 0)`. -/
def sumlist : List Rat → Rat
  | [] => 0
  | a :: l => a + sumlist l

axiom «rationalp-sumlist» : ∀ x : List Rat,
  rationalListp x → rationalp (sumlist x)

-- «realp-sumlist» is not generated: sumlist.lisp guards it with
-- #+:non-standard-analysis, so it is absent from the standard ACL2 book.

axiom «sumlist-append» : ∀ x y : List Rat,
  sumlist (x ++ y) = sumlist x + sumlist y

end ACL2
