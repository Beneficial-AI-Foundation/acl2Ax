module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic»

namespace ACL2.«arithmetic-2».pass1.«inequalities»

-- inequalities.lisp. A variable under a rationalp or real/rationalp hypothesis ranges over Rat. An unconstrained
-- variable ranges over CRat, with `<` as the lexicographic order (decisions 15 and 68). `(fc e)` is the identity
-- macro (line 15) and is inlined. `cond` without a true clause is False (decision 19).
-- The local include of basic-arithmetic is imported (decision 33).

private axiom «iff-equal» : ∀ w x y z : CRat,
  ((w < x) ↔ (y < z)) ↔ ((w < x) ↔ (y < z))

public axiom «/-preserves-positive» : ∀ x : Rat,
  realrationalp x → (0 < x⁻¹ ↔ 0 < x)

public axiom «/-preserves-negative» : ∀ x : Rat,
  realrationalp x → (x⁻¹ < 0 ↔ x < 0)

public axiom «<-0-minus» : ∀ x : CRat, (0 < -x ↔ x < 0)

public axiom «<-minus-zero» : ∀ x : CRat, (-x < 0 ↔ 0 < x)

public axiom «<-minus-minus» : ∀ x y : CRat, (-x < -y ↔ y < x)

public axiom «<-0-+-negative-1» : ∀ x y : CRat, (0 < -y + x ↔ y < x)

public axiom «<-0-+-negative-2» : ∀ x y : CRat, (0 < x + -y ↔ y < x)

public axiom «<-+-negative-0-1» : ∀ x y : CRat, (-y + x < 0 ↔ x < y)

public axiom «<-+-negative-0-2» : ∀ x y : CRat, (x + -y < 0 ↔ x < y)

public axiom «<-*-0» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (x * y < 0 ↔ (¬ (x = 0) ∧ ¬ (y = 0) ∧ ((x < 0) ↔ (0 < y))))

public axiom «0-<-*» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (0 < x * y ↔ (¬ (x = 0) ∧ ¬ (y = 0) ∧ ((0 < x) ↔ (0 < y))))

public axiom «<-*-right-cancel» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (x * z < y * z ↔ (if 0 < z then x < y else if z < 0 then y < x else False))

public axiom «<-*-left-cancel» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (z * x < z * y ↔ (if 0 < z then x < y else if z < 0 then y < x else False))

public axiom «<-*-x-y-y» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (x * y < y ↔ (if 0 < y then x < 1 else if y < 0 then 1 < x else False))

public axiom «<-*-y-x-y» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (y * x < y ↔ (if 0 < y then x < 1 else if y < 0 then 1 < x else False))

public axiom «<-y-*-x-y» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (y < x * y ↔ (if 0 < y then 1 < x else if y < 0 then x < 1 else False))

public axiom «<-y-*-y-x» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (y < y * x ↔ (if 0 < y then 1 < x else if y < 0 then x < 1 else False))

end ACL2.«arithmetic-2».pass1.«inequalities»
