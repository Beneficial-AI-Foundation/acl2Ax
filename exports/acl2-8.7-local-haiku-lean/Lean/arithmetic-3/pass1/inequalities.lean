module

public import ACL2.Base
import «arithmetic-3».pass1.«basic-arithmetic»

namespace ACL2.«arithmetic-3».pass1.«inequalities»

-- inequalities.lisp. All variables are real, so they range over Rat. The hypotheses `(rationalp x)`
-- are kept as `rationalp x`, which Base.lean interprets as True on Rat. `(fc e)` is the identity
-- macro (line 21) and is inlined. `cond` without a true clause is False (decision 19). The local
-- include of basic-arithmetic is imported (decision 34).

private axiom «iff-equal» : ∀ w x y z : Rat,
  ((w < x) ↔ (y < z)) ↔ ((w < x) ↔ (y < z))

public axiom «/-preserves-positive» : ∀ x : Rat,
  rationalp x → (0 < x⁻¹ ↔ 0 < x)

public axiom «/-preserves-negative» : ∀ x : Rat,
  rationalp x → (x⁻¹ < 0 ↔ x < 0)

public axiom «<-0-minus» : ∀ x : Rat, (0 < -x ↔ x < 0)

public axiom «<-minus-zero» : ∀ x : Rat, (-x < 0 ↔ 0 < x)

public axiom «<-minus-minus» : ∀ x y : Rat, (-x < -y ↔ y < x)

public axiom «<-0-+-negative-1» : ∀ x y : Rat, (0 < -y + x ↔ y < x)

public axiom «<-0-+-negative-2» : ∀ x y : Rat, (0 < x + -y ↔ y < x)

public axiom «<-+-negative-0-1» : ∀ x y : Rat, (-y + x < 0 ↔ x < y)

public axiom «<-+-negative-0-2» : ∀ x y : Rat, (x + -y < 0 ↔ x < y)

public axiom «<-*-0» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (x * y < 0 ↔ (¬ (x = 0) ∧ ¬ (y = 0) ∧ ((x < 0) ↔ (0 < y))))

public axiom «0-<-*» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (0 < x * y ↔ (¬ (x = 0) ∧ ¬ (y = 0) ∧ ((0 < x) ↔ (0 < y))))

public axiom «<-*-right-cancel» : ∀ x y z : Rat,
  rationalp x → rationalp y → rationalp z →
  (x * z < y * z ↔ (if 0 < z then x < y else if z < 0 then y < x else False))

public axiom «<-*-left-cancel» : ∀ x y z : Rat,
  rationalp x → rationalp y → rationalp z →
  (z * x < z * y ↔ (if 0 < z then x < y else if z < 0 then y < x else False))

public axiom «<-*-x-y-y» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (x * y < y ↔ (if 0 < y then x < 1 else if y < 0 then 1 < x else False))

public axiom «<-*-y-x-y» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (y * x < y ↔ (if 0 < y then x < 1 else if y < 0 then 1 < x else False))

public axiom «<-y-*-x-y» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (y < x * y ↔ (if 0 < y then 1 < x else if y < 0 then x < 1 else False))

public axiom «<-y-*-y-x» : ∀ x y : Rat,
  rationalp x → rationalp y →
  (y < y * x ↔ (if 0 < y then 1 < x else if y < 0 then x < 1 else False))

end ACL2.«arithmetic-3».pass1.«inequalities»
