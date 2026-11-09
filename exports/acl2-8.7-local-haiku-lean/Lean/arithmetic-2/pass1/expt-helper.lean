module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic»
import «arithmetic-2».pass1.«inequalities»
import «arithmetic-2».pass1.«prefer-times»

namespace ACL2.«arithmetic-2».pass1.«expt-helper»

-- expt-helper.lisp. `expt` is exptC on CRat, with a rational exponent. `(fc e)` is inlined.
-- The local defun Math-induction-start-at-k (line 22) is an induction scheme used only in hints.
-- It is not generated (decision 37). The local includes are imported (decision 33).

private axiom «justify-induction» : ∀ i r : Rat,
  integerp i → 1 < r → realrationalp r →
  exptC (↑r : CRat) i < exptC (↑r : CRat) (1 + i)

public axiom «expt-is-increasing-for-base>1» : ∀ r i j : Rat,
  1 < r → i < j → realrationalp r → integerp i → integerp j →
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

end ACL2.«arithmetic-2».pass1.«expt-helper»
