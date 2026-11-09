import ACL2.Base

namespace ACL2

/-- Helper on `Int`: the recursion of ACL2 `factorial` for integer arguments. -/
def factorialZ (k : Int) : Rat :=
  if _h : k ≤ 0 then 1 else (k : Rat) * factorialZ (k - 1)
termination_by k.toNat
decreasing_by all_goals omega

/-- ACL2 `factorial`: `(if (zp n) 1 (* n (factorial (1- n))))`. For non-integer `n`,
`zp` holds, so the value is 1. Unfolding gives `factorialZ` on the numerator. -/
def «factorial» (n : Rat) : Rat := if integerp n then factorialZ n.num else 1

axiom «factorial-positive-integer» : ∀ n : Rat,
  integerp («factorial» n) ∧ 0 < «factorial» n

axiom «factorial-non-negative» : ∀ n : Rat, 1 ≤ «factorial» n

axiom «abs-factorial» : ∀ x : Rat, abs («factorial» x) = «factorial» x

end ACL2
