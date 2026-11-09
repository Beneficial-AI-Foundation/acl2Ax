/-
Shallow interpretation of the ACL2 primitives used by the arithmetic books.
The domain is `Rat`, which corresponds to the ACL2 rationals. Each ACL2
function is interpreted on `Rat`. Deviations are recorded in EMBEDDING_DECISIONS.md.
-/

namespace ACL2

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

end ACL2
