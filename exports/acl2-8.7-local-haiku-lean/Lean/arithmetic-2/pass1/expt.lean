module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic»
import «arithmetic-2».pass1.«inequalities»
import «arithmetic-2».pass1.«prefer-times»
import «arithmetic-2».pass1.«expt-helper»

-- once its module exists (EMBEDDING_DECISIONS.md, decision 30).

namespace ACL2.«arithmetic-2».pass1.«expt»

-- expt.lisp. `expt` is exptC, on complex rationals, with a rational exponent.
-- `fc` is the identity macro (expt.lisp, line 15), so `(fc e)` is written as `e`.
-- `(#+:non-standard-analysis ...)` forms are not generated (general decision 12).
-- The `(in-theory ...)` and `:hints` are dropped.

public axiom «expt-type-prescription-rationalp» : ∀ r : CRat, ∀ i : Rat,
  realrationalpC r → realrationalpC (exptC r i)

public axiom «expt-type-prescription-positive-1» : ∀ r i : Rat,
  0 < r → realrationalp r → (0 : CRat) < exptC (↑r : CRat) i

public axiom «expt-type-prescription-positive-2» : ∀ r i : Rat,
  0 ≤ r → realrationalp r → acl2le 0 (exptC (↑r : CRat) i)

public axiom «expt-type-prescription-nonzero» : ∀ r : CRat, ∀ i : Rat,
  acl2NumberPC r → ¬ (r = 0) → ¬ (exptC r i = 0)

public axiom «expt-type-prescription-integerp» : ∀ r i : Rat,
  0 ≤ i → integerp r → integerpC (exptC (↑r : CRat) i)

public axiom «equal-expt-0» : ∀ x : CRat, ∀ i : Rat,
  (exptC x i = 0) ↔ (fixC x = 0 ∧ ¬ (ifixR i = 0))

public axiom «expt-0» : ∀ x : CRat, ∀ i : Rat,
  (exptC x 0 = 1) ∧ (exptC 0 i = (if zipR i then 1 else 0))

public axiom «expt-1» : ∀ x : CRat, ∀ i : Rat,
  (exptC x 1 = fixC x) ∧ (exptC 1 i = 1)

private axiom «expt-minus» : ∀ r : CRat, ∀ i : Rat,
  exptC r (-i) = CRat.inv (exptC r i)

public axiom «exponents-add-1» : ∀ r : CRat, ∀ i j : Rat,
  integerp i → integerp j →
  exptC r (i + j) = (if i + j = 0 then 1 else exptC r i * exptC r j)

public axiom «exponents-add-for-nonpos-exponents» : ∀ r : CRat, ∀ i j : Rat,
  i ≤ 0 → j ≤ 0 → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «exponents-add-for-nonneg-exponents» : ∀ r : CRat, ∀ i j : Rat,
  0 ≤ i → 0 ≤ j → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «exponents-add-2» : ∀ r : CRat, ∀ i j : Rat,
  ¬ (0 = r) → acl2NumberPC r → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «distributivity-of-expt-over-*» : ∀ a b : CRat, ∀ i : Rat,
  exptC (a * b) i = exptC a i * exptC b i

public axiom «functional-commutativity-of-expt-/-base» : ∀ r : CRat, ∀ i : Rat,
  exptC (CRat.inv r) i = CRat.inv (exptC r i)

public axiom «Exponents-multiply» : ∀ r : CRat, ∀ i j : Rat,
  integerp i → integerp j → exptC (exptC r i) j = exptC r (i * j)

public axiom «expt-is-increasing-for-base>1» : ∀ r i j : Rat,
  1 < r → i < j → realrationalp r → integerp i → integerp j →
  exptC (↑r : CRat) i < exptC (↑r : CRat) j

public axiom «Expt-is-decreasing-for-pos-base<1» : ∀ r i j : Rat,
  0 < r → r < 1 → i < j → realrationalp r → integerp i → integerp j →
  exptC (↑r : CRat) j < exptC (↑r : CRat) i

public axiom «Expt-is-weakly-increasing-for-base>1» : ∀ r i j : Rat,
  1 ≤ r → i ≤ j → realrationalp r → integerp i → integerp j →
  acl2le (exptC (↑r : CRat) i) (exptC (↑r : CRat) j)

public axiom «Expt-is-weakly-decreasing-for-pos-base<1» : ∀ r i j : Rat,
  0 < r → r ≤ 1 → i ≤ j → realrationalp r → integerp i → integerp j →
  acl2le (exptC (↑r : CRat) j) (exptC (↑r : CRat) i)

-- stupid-hack (local)
private axiom «stupid-hack» : ∀ x : Rat, ∀ a : CRat, ∀ b : Rat,
  realrationalp x → ¬ (x = 0) →
  ((↑x : CRat) * CRat.inv (↑x : CRat)) * exptC a b = exptC a b

public axiom «expt->-1-1» : ∀ r i : Rat,
  1 < r → 0 < i → realrationalp r → integerp i →
  (1 : CRat) < exptC (↑r : CRat) i

public axiom «expt->-1-2» : ∀ r i : Rat,
  0 < r → r < 1 → i < 0 → realrationalp r → integerp i →
  (1 : CRat) < exptC (↑r : CRat) i

public axiom «expt-<-1-1» : ∀ r i : Rat,
  0 < r → r < 1 → 0 < i → realrationalp r → integerp i →
  exptC (↑r : CRat) i < 1

public axiom «expt-<-1-2» : ∀ r i : Rat,
  1 < r → i < 0 → realrationalp r → integerp i →
  exptC (↑r : CRat) i < 1

end ACL2.«arithmetic-2».pass1.«expt»
