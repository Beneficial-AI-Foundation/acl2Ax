module

public import ACL2.Base

namespace ACL2.«arithmetic-2».pass1.«basic-arithmetic-helper»

-- basic-arithmetic-helper.lisp: the statements range over all ACL2 numbers, that is over CRat.
-- `(/ x)` is CRat.inv x, and `(fix x)` is fixC x. The `encapsulate` forms are transparent,
-- and the local theorems inside them are included as axioms (general decisions 11 and 24).

private axiom «commutativity-2-of-*-lemma» : ∀ x y z : CRat,
  acl2NumberPC x → acl2NumberPC y → acl2NumberPC z →
  (x * y) * z = (y * x) * z

public axiom «commutativity-2-of-*» : ∀ x y z : CRat,
  x * (y * z) = y * (x * z)

private axiom «equiv-1-implies-equiv-*» : ∀ x1 x2 y : CRat,
  x1 = x2 → x1 * y = x2 * y

public axiom «right-cancellation-for-*» : ∀ x y z : CRat,
  (x * z = y * z) ↔ (0 = fixC z ∨ fixC x = fixC y)

private axiom «uniqueness-of-*-inverses-lemma» : ∀ x y : CRat,
  acl2NumberPC x → ¬ (x = 0) → acl2NumberPC y → x * y = 1 →
  CRat.inv x = y

public axiom «equal-/» : ∀ x y : CRat,
  (CRat.inv x = y) ↔ (if ¬ (fixC x = 0) then 1 = x * y else y = 0)

public axiom «functional-self-inversion-of-/» : ∀ x : CRat,
  CRat.inv (CRat.inv x) = fixC x

private axiom «distributivity-of-/-over-*-lemma» : ∀ x y : CRat,
  acl2NumberPC x → ¬ (x = 0) → acl2NumberPC y → ¬ (y = 0) →
  CRat.inv (x * y) = CRat.inv x * CRat.inv y

public axiom «distributivity-of-/-over-*» : ∀ x y : CRat,
  CRat.inv (x * y) = CRat.inv x * CRat.inv y

private axiom «uniqueness-of-+-inverses-lemma» : ∀ x y : CRat,
  acl2NumberPC x → acl2NumberPC y → x + y = 0 → -x = y

public axiom «functional-commutativity-of-minus-*-right» : ∀ x y : CRat,
  x * (-y) = -(x * y)

private axiom «equal-/-/-lemma» : ∀ a b : CRat,
  acl2NumberPC a → acl2NumberPC b → ¬ (a = 0) → ¬ (b = 0) →
  (CRat.inv a = CRat.inv b ↔ a = b)

public axiom «equal-/-/» : ∀ a b : CRat,
  (CRat.inv a = CRat.inv b) ↔ (fixC a = fixC b)

end ACL2.«arithmetic-2».pass1.«basic-arithmetic-helper»
