module

public import ACL2.Base
import «arithmetic-3».pass1.«basic-arithmetic»
import «arithmetic-3».pass1.«inequalities»
import «arithmetic-3».pass1.«prefer-times»
import «arithmetic-3».pass1.«expt»

namespace ACL2.«arithmetic-3».pass1.«mini-theories»

-- mini-theories.lisp. The `in-theory`, `deftheory` and `theory-invariant` forms are rule-set
-- bookkeeping and are not generated. `(fix x)` is fixC x, `(/ x)` is CRat.inv x, and `expt`
-- is exptC (decision 29). The local includes are imported (decision 33).

public axiom «rewrite-linear-equalities-to-iff» : ∀ w x y z : CRat,
  ((w < x) ↔ (y < z)) ↔ ((w < x) ↔ (y < z))

private axiom «Uniqueness-of-*-inverses-lemma-2» : ∀ x y : CRat,
  (x * y = 1) ↔ (¬ (x = 0) ∧ acl2NumberPC x ∧ y = CRat.inv x)

public axiom «Uniqueness-of-*-inverses» : ∀ x y : CRat,
  (x * y = 1) ↔ (¬ (fixC x = 0) ∧ y = CRat.inv x)

public axiom «expts-add-aggressive» : ∀ x : CRat, ∀ i j : Rat,
  integerp i → integerp j →
  exptC x (i + j) =
    (if i + j = 0 then 1
     else if fixC x = 0 then 0
     else exptC x i * exptC x j)

public axiom «expts-add-inverse» : ∀ x : CRat, ∀ i j : Rat,
  integerp i → integerp j →
  exptC x i * exptC x j =
    (if i = 0 ∧ j = 0 then 1
     else if fixC x = 0 then 0
     else exptC x (i + j))

end ACL2.«arithmetic-3».pass1.«mini-theories»
