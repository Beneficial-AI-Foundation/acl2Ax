module

public import ACL2.Base
import «arithmetic-3».pass1.«basic-arithmetic»
import «arithmetic-3».pass1.«inequalities»
import «arithmetic-3».pass1.«prefer-times»
import «arithmetic-3».pass1.«non-linear»
import «arithmetic-3».pass1.«num-and-denom-helper»

namespace ACL2.«arithmetic-3».pass1.«numerator-and-denominator»

-- numerator-and-denominator.lisp (arithmetic-3). The statements are those of the arithmetic-2
-- book, which the arithmetic-3 text repeats. The variables range over CRat, because the ACL2
-- statements have no integer hypothesis. `numerator` is numeratorC (decision 26), `denominator`
-- is denominatorC (decision 42), `rationalp` is realrationalpC, and `integerp` is integerpC.
-- `(fix r)` is fixC r. The local includes are imported as plain imports (decision 44).

public axiom «numerator-minus» : ∀ i : CRat,
  numeratorC (-i) = -numeratorC i

public axiom «denominator-minus» : ∀ x : CRat,
  realrationalpC x → denominatorC (-x) = denominatorC x

private axiom «numerator-integerp-lemma-1» : ∀ x : CRat,
  realrationalpC x →
  numeratorC x * (denominatorC x)⁻¹ * denominatorC x = numeratorC x

private axiom «numerator-integerp-lemma» : ∀ x : CRat,
  realrationalpC x →
  (↑(numeratorC x * (denominatorC x)⁻¹) : CRat) = x →
  (↑(numeratorC x) : CRat) = x * ↑(denominatorC x)

public axiom «numerator-when-integerp» : ∀ x : Rat,
  integerp x → numeratorC (↑x) = x

public axiom «integerp==>denominator=1» : ∀ x : Rat,
  integerp x → denominatorC (↑x) = 1

public axiom «equal-denominator-1» : ∀ x : CRat,
  (denominatorC x = 1) ↔ (integerpC x ∨ ¬ realrationalpC x)

public axiom «*-r-denominator-r» : ∀ r : CRat,
  r * ↑(denominatorC r) = (if realrationalpC r then ↑(numeratorC r) else fixC r)

end ACL2.«arithmetic-3».pass1.«numerator-and-denominator»
