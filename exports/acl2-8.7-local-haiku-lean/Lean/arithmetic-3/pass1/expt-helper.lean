module

public import ACL2.Base
import «arithmetic-3».pass1.«basic-arithmetic»
import «arithmetic-3».pass1.«inequalities»
import «arithmetic-3».pass1.«prefer-times»

namespace ACL2.«arithmetic-3».pass1.«expt-helper»

-- expt-helper.lisp. `expt` is exptC on CRat, with a rational exponent. `(fc e)` is inlined.
-- The local defun Math-induction-start-at-k (line 30) is an opaque signature (decision 41, revising
-- decision 37). The local includes are imported as plain imports (decision 33).

public axiom «expt-crock» : ∀ x : CRat,
  exptC x 1 = fixC x

private opaque «Math-induction-start-at-k» : Rat → Rat → Prop

private axiom «justify-induction» : ∀ i r : Rat,
  integerp i → 1 < r → rationalp r →
  exptC (↑r : CRat) i < exptC (↑r : CRat) (1 + i)

public axiom «expt-is-increasing-for-base>1» : ∀ r i j : Rat,
  1 < r → i < j → rationalp r → integerp i → integerp j →
  exptC (↑r : CRat) i < exptC (↑r : CRat) j

public axiom «exponents-add-for-nonpos-exponents» : ∀ r : CRat, ∀ i j : Rat,
  i ≤ 0 → j ≤ 0 → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «exponents-add-for-nonneg-exponents» : ∀ r : CRat, ∀ i j : Rat,
  0 ≤ i → 0 ≤ j → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «exponents-add-2» : ∀ r : CRat, ∀ i j : Rat,
  ¬ (0 = r) → acl2NumberPC r → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «exponents-add-1» : ∀ r : CRat, ∀ i j : Rat,
  integerp i → integerp j →
  exptC r (i + j) = (if i + j = 0 then 1 else exptC r i * exptC r j)

end ACL2.«arithmetic-3».pass1.«expt-helper»
