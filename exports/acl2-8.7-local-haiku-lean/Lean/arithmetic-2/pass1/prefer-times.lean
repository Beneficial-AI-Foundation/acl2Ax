module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic»
import «arithmetic-2».pass1.«inequalities»

namespace ACL2.«arithmetic-2».pass1.«prefer-times»

-- prefer-times.lisp. The equalities and the `<` normalizations range over all ACL2 numbers
-- (CRat) for the first two, and over reals (Rat) for the rest. `(/ x)` is CRat.inv x for CRat,
-- and `⁻¹` for Rat. `(fix x)` is fixC x. The `cond` without a true clause is False (decision 19).
-- The local includes basic-arithmetic and inequalities are imported (decision 33).

private axiom «iff-equal» : ∀ w x y z : CRat,
  ((w < x) ↔ (y < z)) ↔ ((w < x) ↔ (y < z))

public axiom «equal-*-/-1» : ∀ x y z : CRat,
  (CRat.inv x * y = z) ↔
    (if fixC x = 0 then z = 0 else acl2NumberPC z ∧ fixC y = x * z)

public axiom «equal-*-/-2» : ∀ x y z : CRat,
  (y * CRat.inv x = z) ↔
    (if fixC x = 0 then z = 0 else acl2NumberPC z ∧ fixC y = z * x)

private axiom «times-one» : ∀ x : CRat,
  acl2NumberPC x → (1 : CRat) * x = x

private axiom «times-minus-one» : ∀ x : CRat,
  acl2NumberPC x → (-1 : CRat) * x = -x

public axiom «normalize-<-/-to-*-1» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (x < y⁻¹ ↔ (if y < 0 then 1 < x * y else if 0 < y then x * y < 1 else x < 0))

public axiom «normalize-<-/-to-*-2» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (y⁻¹ < x ↔ (if y < 0 then x * y < 1 else if 0 < y then 1 < x * y else 0 < x))

public axiom «normalize-<-/-to-*-3-1» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (x < y * z⁻¹ ↔ (if z < 0 then y < x * z else if 0 < z then x * z < y else x < 0))

public axiom «normalize-<-/-to-*-3-2» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (x < z⁻¹ * y ↔ (if z < 0 then y < x * z else if 0 < z then x * z < y else x < 0))

public axiom «normalize-<-/-to-*-3-3» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (y * z⁻¹ < x ↔ (if z < 0 then x * z < y else if 0 < z then y < x * z else 0 < x))

public axiom «normalize-<-/-to-*-3-4» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (z⁻¹ * y < x ↔ (if z < 0 then x * z < y else if 0 < z then y < x * z else 0 < x))

end ACL2.«arithmetic-2».pass1.«prefer-times»
