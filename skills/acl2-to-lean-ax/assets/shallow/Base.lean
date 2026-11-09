/-
Shallow interpretation of the ACL2 primitives used by the arithmetic books.
The domain is `Rat`, which corresponds to the ACL2 rationals. Each ACL2
function is interpreted on `Rat`. Deviations are recorded in EMBEDDING_DECISIONS.md.
-/

module

namespace ACL2

public section

/-- `real/rationalp` on the rationals, interpreted as membership in `Rat`. -/
def realrationalp (_x : Rat) : Prop := True

/-- `acl2-numberp` on the rationals, interpreted as membership in `Rat`. -/
def acl2NumberP (_x : Rat) : Prop := True

/-- `rationalp` on the rationals, interpreted as membership in `Rat`. -/
def rationalp (_x : Rat) : Prop := True

/-- `rational-listp` on lists of rationals, interpreted as membership in `List Rat`. -/
def rationalListp (_l : List Rat) : Prop := True

/-- ACL2 `integerp` on the rationals: the denominator is 1. -/
def integerp (r : Rat) : Prop := r.den = 1

instance (r : Rat) : Decidable (integerp r) :=
  inferInstanceAs (Decidable (r.den = 1))

/-- ACL2 `zp`: `(if (integerp x) (<= x 0) t)`. -/
def zp (x : Rat) : Prop := integerp x → x ≤ 0

instance (x : Rat) : Decidable (zp x) :=
  inferInstanceAs (Decidable (integerp x → x ≤ 0))

/-- ACL2 `fix` on numbers: `(if (acl2-numberp x) x 0)`. -/
def fix (x : Rat) : Rat := x

/-- ACL2 `nfix`: `(if (and (integerp x) (>= x 0)) x 0)`. -/
def nfix (x : Rat) : Rat := if integerp x ∧ 0 ≤ x then x else 0

/-- ACL2 `abs`: `(if (minusp x) (- x) x)`, from axioms.lisp. -/
def abs (x : Rat) : Rat := if x < 0 then -x else x

/-- ACL2 `expt` on an integer exponent, following axioms.lisp:
`(cond ((zip i) 1) ((= (fix r) 0) 0) ((> i 0) (* r (expt r (+ i -1))))
       (t (* (/ r) (expt r (+ i +1)))))`. -/
def exptInt (r : Rat) (i : Int) : Rat :=
  if i = 0 then 1
  else if r = 0 then 0
  else if 0 < i then r * exptInt r (i - 1)
  else r⁻¹ * exptInt r (i + 1)
termination_by i.natAbs
decreasing_by all_goals omega

/-- ACL2 `expt` on the rationals: an integer exponent `i` gives `exptInt r i.num`,
and a non-integer exponent gives 1, because `zip` holds for it. -/
def expt (r i : Rat) : Rat := if integerp i then exptInt r i.num else 1

/-! ## Complex rationals

ACL2 numbers that are not real are complex rationals `a + b i` with `a`, `b` rational.
`CRat` is the pair of rationals with the field operations, and `<` is the lexicographic
order of `completion-of-<` in axioms.lisp (lines 25364 to 25374). -/

/-- An ACL2 complex rational: the real part `re` and the imaginary part `im`. -/
structure CRat where
  re : Rat
  im : Rat
  deriving DecidableEq

namespace CRat

instance : OfNat CRat n := ⟨⟨n, 0⟩⟩

instance : Coe Rat CRat := ⟨fun r => ⟨r, 0⟩⟩

instance : Add CRat := ⟨fun a b => ⟨a.re + b.re, a.im + b.im⟩⟩

instance : Neg CRat := ⟨fun a => ⟨-a.re, -a.im⟩⟩

instance : Sub CRat := ⟨fun a b => ⟨a.re - b.re, a.im - b.im⟩⟩

instance : Mul CRat := ⟨fun a b => ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩⟩

/-- ACL2 `(/ x)`: the inverse of a nonzero complex rational, and 0 for 0. -/
def inv (a : CRat) : CRat :=
  let n := a.re * a.re + a.im * a.im
  if n = 0 then 0 else ⟨a.re / n, -a.im / n⟩

instance : Div CRat := ⟨fun a b => a * inv b⟩

/-- ACL2 `realpart`. -/
def realpart (a : CRat) : Rat := a.re

/-- ACL2 `imagpart`. -/
def imagpart (a : CRat) : Rat := a.im

/-- ACL2 `<` on complex rationals, from `completion-of-<` in axioms.lisp. -/
def lt (x y : CRat) : Prop := x.re < y.re ∨ (x.re = y.re ∧ x.im < y.im)

instance : LT CRat := ⟨lt⟩

instance (x y : CRat) : Decidable (x < y) :=
  inferInstanceAs (Decidable (x.re < y.re ∨ (x.re = y.re ∧ x.im < y.im)))

end CRat

/-- ACL2 `acl2-numberp` on the complex rationals: always true. -/
def acl2NumberPC (_x : CRat) : Prop := True

/-- ACL2 `complex` on rationals: `(complex x y)` is `x + y i`. -/
def complex (x y : Rat) : CRat := ⟨x, y⟩

/-- ACL2 `real/rationalp` on a complex rational: its imaginary part is 0, because
`(complex x 0)` is the rational `x`. -/
def realrationalpC (c : CRat) : Prop := c.im = 0

/-- ACL2 `fix` on complex rationals: the identity. -/
def fixC (c : CRat) : CRat := c


/-- ACL2 `<=` on complex rationals: `(not (< y x))`, the definition of `<=?` in axioms.lisp, lines 11614 to 11618. -/
def acl2le (x y : CRat) : Prop := ¬ (y < x)

/-- ACL2 `numerator` on complex rationals: `completion-of-numerator` (axioms.lisp, line 25668)
gives the numerator of a rational and 0 otherwise. A complex rational is rational when its
imaginary part is 0. -/
def numeratorC (c : CRat) : Rat := if c.im = 0 then ((c.re.num : Int) : Rat) else 0

/-- ACL2 `quotep` on a complex rational, as a hypothesis carrier. The representation of
`quotep` and `syntaxp` is deferred (EMBEDDING_DECISIONS.md, decision 25). Until it is decided,
each hypothesis is the type `PUnit`, which is always inhabited, so it imposes no condition. -/
def quotepC (_c : CRat) : Type := PUnit

/-- ACL2 `syntaxp` hypothesis, as an always-inhabited type. Deferred, as `quotepC`. -/
def syntaxpW : Type := PUnit

/-- ACL2 `integerp` on complex rationals: a real integer, that is imaginary part 0 and denominator 1. -/
def integerpC (c : CRat) : Prop := c.im = 0 ∧ c.re.den = 1

/-- ACL2 `ifix` on rationals: `(if (integerp i) i 0)`. -/
def ifixR (i : Rat) : Rat := if integerp i then i else 0

/-- ACL2 `zip`: `(if (integerp x) (= x 0) t)`, as a Prop. -/
def zipR (i : Rat) : Prop := integerp i → i = 0

instance (i : Rat) : Decidable (zipR i) :=
  inferInstanceAs (Decidable (integerp i → i = 0))

/-- ACL2 `expt` with an integer exponent on complex rationals, following axioms.lisp
(`expt`, line 9073): `(cond ((zip i) 1) ((= (fix r) 0) 0) ((> i 0) (* r (expt r (+ i -1))))
(t (* (/ r) (expt r (+ i +1)))))`. -/
def exptCInt (r : CRat) (i : Int) : CRat :=
  if i = 0 then 1
  else if r = 0 then 0
  else if 0 < i then r * exptCInt r (i - 1)
  else CRat.inv r * exptCInt r (i + 1)
termination_by i.natAbs
decreasing_by all_goals omega

/-- ACL2 `expt` on complex rationals with a rational exponent: the integer case, and 1 for a
non-integer exponent, because `zip` holds for it. -/
def exptC (r : CRat) (i : Rat) : CRat := if integerp i then exptCInt r i.num else 1

end

end ACL2
