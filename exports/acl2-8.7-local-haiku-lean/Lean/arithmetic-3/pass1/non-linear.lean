module

public import ACL2.Base
import «arithmetic-3».pass1.«basic-arithmetic»
import «arithmetic-3».pass1.«expt»

namespace ACL2.«arithmetic-3».pass1.«non-linear»

-- non-linear.lisp: a minimal theory for the non-linear extension to the linear arithmetic
-- decision procedure. Both includes are local, so the module imports them without re-export
-- (general decision 30). The statements follow the arithmetic-3 text. A product of three factors,
-- `(* x y z)`, is the ACL2 macro expansion `(* x (* y z))`.

public axiom «arith-associativity-of-*» : ∀ x y z : CRat,
  (x * y) * z = x * (y * z)

public axiom «arith-commutativity-of-*» : ∀ x y : CRat,
  x * y = y * x

public axiom «arith-commutativity-2-of-*» : ∀ x y z : CRat,
  x * (y * z) = y * (x * z)

public axiom «arith-unicity-of-1» : ∀ x : CRat,
  (1 * x = fixC x) ∧ (x * 1 = fixC x)

public axiom «arith-times-zero» : ∀ x : CRat,
  (0 * x = 0) ∧ (x * 0 = 0)

public axiom «arith-inverse-of-*-1» : ∀ x : Rat,
  rationalp x → ¬ (x = 0) →
  x * x⁻¹ = 1

public axiom «arith-inverse-of-*-2» : ∀ x : Rat, ∀ y : CRat,
  rationalp x → ¬ (x = 0) →
  (↑x : CRat) * (CRat.inv (↑x : CRat) * y) = fixC y

public axiom «arith-inverse-of-*-3» : ∀ x : Rat, ∀ y : CRat,
  rationalp x → ¬ (x = 0) →
  (↑x : CRat) * (y * CRat.inv (↑x : CRat)) = fixC y

public axiom «arith-functional-self-inversion-of-/» : ∀ x : CRat,
  CRat.inv (CRat.inv x) = fixC x

public axiom «arith-distributivity-of-/-over-*» : ∀ x y : CRat,
  CRat.inv (x * y) = CRat.inv x * CRat.inv y

public axiom «arith-functional-commutativity-of-minus-*-right» : ∀ x y : CRat,
  x * (-y) = -(x * y)

public axiom «arith-functional-commutativity-of-minus-*-left» : ∀ x y : CRat,
  (-x) * y = -(x * y)

public axiom «arith-reciprocal-minusa» : ∀ x : CRat,
  CRat.inv (-x) = -CRat.inv x

public axiom «arith-distributivity-1» : ∀ x y z : CRat,
  x * (y + z) = x * y + x * z

public axiom «arith-distributivity-2» : ∀ x y z : CRat,
  (y + z) * x = x * y + x * z

public axiom «arith-fold-consts-in-*» : ∀ c d x : CRat,
  syntaxpW → syntaxpW →
  c * (d * x) = (c * d) * x

public axiom «arith-expt-0» : ∀ x i : CRat,
  (exptC x 0 = 1) ∧ (exptC 0 i = (if zipC i then 1 else 0))

public axiom «arith-expt-1» : ∀ x i : CRat,
  (exptC x 1 = fixC x) ∧ (exptC 1 i = 1)

public axiom «arith-expt-minus-1» : ∀ x : CRat,
  exptC x (-1) = CRat.inv x

public axiom «arith-functional-commutativity-of-expt-/» : ∀ r i : CRat,
  CRat.inv (exptC r i) = exptC (CRat.inv r) i

public axiom «arith-expt-minus-exponent» : ∀ r i : CRat,
  exptC r (-i) = exptC (CRat.inv r) i

public axiom «arith-expt-negative-constant-exponent» : ∀ r i j : CRat,
  syntaxpW →
  exptC (CRat.inv r) (i * j) = exptC r ((-i) * j)

public axiom «arith-exponents-multiply» : ∀ r : CRat, ∀ i j : Rat,
  integerp i → integerp j →
  exptC (exptC r i) j = exptC r (i * j)

public axiom «arith-distributivity-of-expt-over-*» : ∀ a b i : CRat,
  exptC (a * b) i = exptC a i * exptC b i

public axiom «arith-fix-revealed» : ∀ x : CRat,
  acl2NumberPC x → fixC x = x

public axiom «arith-Rational-implies2» : ∀ x : Rat,
  rationalp x →
  ((x.num : Int) : Rat) * ((x.den : Int) : Rat)⁻¹ = x

public axiom «arith-exponents-add-1» : ∀ r : CRat, ∀ i j : Rat,
  integerp i → integerp j → ¬ (i + j = 0) →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «arith-exponents-add-for-nonpos-exponentsa» : ∀ r : CRat, ∀ i j : Rat,
  i ≤ 0 → j ≤ 0 → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «arith-exponents-add-for-nonneg-exponentsa» : ∀ r : CRat, ∀ i j : Rat,
  0 ≤ i → 0 ≤ j → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

public axiom «arith-exponents-add-2» : ∀ r : CRat, ∀ i j : Rat,
  ¬ (0 = r) → acl2NumberPC r → integerp i → integerp j →
  exptC r (i + j) = exptC r i * exptC r j

end ACL2.«arithmetic-3».pass1.«non-linear»
