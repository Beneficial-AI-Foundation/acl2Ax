/-
Copyright (C) 2014, University of Wyoming
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book arithmetic/abs.lisp.
-/

import ACL2.Base

namespace ACL2

axiom «abs-*» : ∀ x y : Rat,
  realrationalp x → realrationalp y → abs (x * y) = abs x * abs y

axiom «abs-uminus» : ∀ x : Rat, abs (-x) = abs (fix x)

axiom «realp-abs» : ∀ x : Rat, realrationalp x → realrationalp (abs x)

axiom «numberp-abs» : ∀ x : Rat, acl2NumberP x → acl2NumberP (abs x)

axiom «abs-x->-0» : ∀ x : Rat, realrationalp x → 0 ≤ x → abs x = x

axiom «abs-x-=-0-iff-x=0» : ∀ x : Rat, realrationalp x → ¬ (0 = x) → 0 < abs x

axiom «not-abs-x-<-0» : ∀ x : Rat, ¬ (abs x < 0)

axiom «abs-x-generalize-weak» : ∀ x : Rat, realrationalp x →
  (0 ≤ abs x ∧ realrationalp (abs x))

axiom «abs-x-generalize-strong» : ∀ x : Rat, realrationalp x → ¬ (x = 0) → 0 < abs x

axiom «abs-triangle» : ∀ x y : Rat, abs (x + y) ≤ abs x + abs y

end ACL2
