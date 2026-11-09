module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic-helper»

-- Local includes that are not yet imported: basic-arithmetic-helper. Each is imported with a plain `import`
-- once its module exists (EMBEDDING_DECISIONS.md, decision 30).

namespace ACL2.«arithmetic-2».pass1.«basic-arithmetic»

-- basic-arithmetic.lisp. The statements range over all ACL2 numbers, that is over CRat.
-- `(/ x)` is CRat.inv x, `(fix x)` is fixC x, `(numerator r)` is numeratorC r.
-- The `syntaxp` hypotheses are `syntaxpW` and `quotepC`, always-inhabited types (decision 25). The only include is local, so
-- no module is imported.

public axiom «commutativity-2-of-+» : ∀ x y z : CRat,
  x + (y + z) = y + (x + z)

public axiom «functional-self-inversion-of-minus» : ∀ x : CRat,
  -(-x) = fixC x

public axiom «distributivity-of-minus-over-+» : ∀ x y : CRat,
  -(x + y) = -x + -y

public axiom «minus-cancellation-on-right» : ∀ x y : CRat,
  x + y + -x = fixC y

public axiom «minus-cancellation-on-left» : ∀ x y : CRat,
  x + -x + y = fixC y

public axiom «right-cancellation-for-+» : ∀ x y z : CRat,
  (x + z = y + z) ↔ (fixC x = fixC y)

public axiom «left-cancellation-for-+» : ∀ x y z : CRat,
  (x + y = x + z) ↔ (fixC y = fixC z)

public axiom «equal-minus-0» : ∀ x : CRat,
  (-x = 0) ↔ (fixC x = 0)

-- The syntaxp hypothesis is (not (and (consp y) ...)), which holds for every CRat y.
public axiom «equal-+-x-y-0» : ∀ x y : CRat,
  syntaxpW → (x + y = 0) ↔ (fixC x = -y ∧ -x = fixC y)

public axiom «equal-+-x-y-x» : ∀ x y : CRat,
  (x + y = x) ↔ (acl2NumberPC x ∧ fixC y = 0)

public axiom «equal-+-x-y-y» : ∀ x y : CRat,
  (x + y = y) ↔ (acl2NumberPC y ∧ fixC x = 0)

public axiom «equal-minus-minus» : ∀ a b : CRat,
  (-a = -b) ↔ (fixC a = fixC b)

public axiom «fold-consts-in-+» : ∀ x y z : CRat,
  quotepC x → quotepC y → x + (y + z) = (x + y) + z

public axiom «commutativity-2-of-*» : ∀ x y z : CRat,
  x * (y * z) = y * (x * z)

public axiom «functional-self-inversion-of-/» : ∀ x : CRat,
  CRat.inv (CRat.inv x) = fixC x

public axiom «distributivity-of-/-over-*» : ∀ x y : CRat,
  CRat.inv (x * y) = CRat.inv x * CRat.inv y

public axiom «/-cancellation-on-right» : ∀ x y : CRat,
  y * x * CRat.inv y = (if ¬ (fixC y = 0) then fixC x else 0)

public axiom «/-cancellation-on-left» : ∀ x y : CRat,
  y * CRat.inv y * x = (if ¬ (fixC y = 0) then fixC x else 0)

public axiom «right-cancellation-for-*» : ∀ x y z : CRat,
  (x * z = y * z) ↔ (0 = fixC z ∨ fixC x = fixC y)

public axiom «left-cancellation-for-*» : ∀ x y z : CRat,
  (z * x = z * y) ↔ (0 = fixC z ∨ fixC x = fixC y)

public axiom «equal-/-0» : ∀ x : CRat,
  (CRat.inv x = 0) ↔ (fixC x = 0)

public axiom «equal-*-x-y-0» : ∀ x y : CRat,
  (x * y = 0) ↔ (fixC x = 0 ∨ fixC y = 0)

public axiom «equal-*-x-y-x» : ∀ x y : CRat,
  (x * y = x) ↔ (acl2NumberPC x ∧ (x = 0 ∨ y = 1))

public axiom «equal-*-y-x-x» : ∀ x y : CRat,
  (y * x = x) ↔ (acl2NumberPC x ∧ (x = 0 ∨ y = 1))

public axiom «equal-/-/» : ∀ a b : CRat,
  (CRat.inv a = CRat.inv b) ↔ (fixC a = fixC b)

public axiom «fold-consts-in-*» : ∀ x y z : CRat,
  quotepC x → quotepC y → x * (y * z) = (x * y) * z

public axiom «equal-/» : ∀ x y : CRat,
  (CRat.inv x = y) ↔ (if ¬ (fixC x = 0) then 1 = x * y else y = 0)

public axiom «numerator-nonzero-forward» : ∀ r : CRat,
  ¬ (numeratorC r = 0) → (¬ (r = 0) ∧ acl2NumberPC r)

public axiom «times-zero» : ∀ x : CRat,
  0 * x = 0

public axiom «functional-commutativity-of-minus-*-right» : ∀ x y : CRat,
  x * (-y) = -(x * y)

public axiom «functional-commutativity-of-minus-*-left» : ∀ x y : CRat,
  (-x) * y = -(x * y)

public axiom «reciprocal-minus-a» : ∀ x : CRat,
  CRat.inv (-x) = -(CRat.inv x)

end ACL2.«arithmetic-2».pass1.«basic-arithmetic»
