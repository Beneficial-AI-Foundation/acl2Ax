import ACL2.Base
import arithmetic.factorial
import arithmetic.sumlist

namespace ACL2

/-- Helper on `Int` for ACL2 `choose-mk`: the recursion for integer arguments. -/
def chooseMkZ (k n : Int) : Rat :=
  if _h : 0 < k ∧ k < n then chooseMkZ (k - 1) (n - 1) + chooseMkZ k (n - 1)
  else if 0 ≤ k ∧ k ≤ n then 1 else 0
termination_by n.toNat
decreasing_by all_goals omega

/-- ACL2 `choose`: `(if (and (integerp k) (integerp n) (<= 0 k) (<= k n))
      (/ (factorial n) (* (factorial k) (factorial (- n k)))) 0)`. -/
def «choose» (k n : Rat) : Rat :=
  if integerp k ∧ integerp n ∧ 0 ≤ k ∧ k ≤ n then
    «factorial» n / («factorial» k * «factorial» (n - k))
  else 0

/-- ACL2 `choose-mk`, the Pascal recursion. -/
def «choose-mk» (k n : Rat) : Rat :=
  if integerp k ∧ integerp n then chooseMkZ k.num n.num else 0

/-- Helper on `Int` for ACL2 `binomial-expansion`. -/
def binomialExpansionZ (x y : Rat) (k n : Int) : List Rat :=
  if _h : 0 ≤ k ∧ k ≤ n then
    («choose» k n * expt x k * expt y (n - k)) :: binomialExpansionZ x y (k + 1) n
  else []
termination_by (n - k + 1).toNat
decreasing_by all_goals omega

/-- ACL2 `binomial-expansion`. -/
def «binomial-expansion» (x y k n : Rat) : List Rat :=
  if integerp k ∧ integerp n then binomialExpansionZ x y k.num n.num else []

/-- Helper on `Int` for ACL2 `binomial-expansion-times-x`. -/
def binomialExpansionTimesXZ (x y : Rat) (k n : Int) : List Rat :=
  if _h : 0 ≤ k ∧ k ≤ n then
    («choose» k n * expt x (k + 1) * expt y (n - k)) :: binomialExpansionTimesXZ x y (k + 1) n
  else []
termination_by (n - k + 1).toNat
decreasing_by all_goals omega

/-- ACL2 `binomial-expansion-times-x`. -/
def «binomial-expansion-times-x» (x y k n : Rat) : List Rat :=
  if integerp k ∧ integerp n then binomialExpansionTimesXZ x y k.num n.num else []

/-- Helper on `Int` for ACL2 `binomial-expansion-times-y`. -/
def binomialExpansionTimesYZ (x y : Rat) (k n : Int) : List Rat :=
  if _h : 0 ≤ k ∧ k ≤ n then
    («choose» k n * expt x k * expt y (n - k + 1)) :: binomialExpansionTimesYZ x y (k + 1) n
  else []
termination_by (n - k + 1).toNat
decreasing_by all_goals omega

/-- ACL2 `binomial-expansion-times-y`. -/
def «binomial-expansion-times-y» (x y k n : Rat) : List Rat :=
  if integerp k ∧ integerp n then binomialExpansionTimesYZ x y k.num n.num else []

/-- Helper on `Int` for ACL2 `binomial-expansion-triangle`. -/
def binomialExpansionTriangleZ (x y : Rat) (k n : Int) : List Rat :=
  if _h : 0 ≤ k ∧ k ≤ n then
    («choose» k n * expt x (k + 1) * expt y (n - k)) ::
      («choose» k n * expt x k * expt y (n - k + 1)) ::
      binomialExpansionTriangleZ x y (k + 1) n
  else []
termination_by (n - k + 1).toNat
decreasing_by all_goals omega

/-- ACL2 `binomial-expansion-triangle`. -/
def «binomial-expansion-triangle» (x y k n : Rat) : List Rat :=
  if integerp k ∧ integerp n then binomialExpansionTriangleZ x y k.num n.num else []

/-- Helper on `Int` for ACL2 `binomial-expansion-pascal-triangle`. -/
def binomialExpansionPascalZ (x y : Rat) (k n : Int) : List Rat :=
  if _h : 0 ≤ k then
    if k < n then
      («choose» k n * expt x (k + 1) * expt y (n - k)) ::
        («choose» (k + 1) n * expt x (k + 1) * expt y (n - k)) ::
        binomialExpansionPascalZ x y (k + 1) n
    else if k = n then
      [«choose» k n * expt x (k + 1) * expt y (n - k)]
    else []
  else []
termination_by (n - k + 1).toNat
decreasing_by all_goals omega

/-- ACL2 `binomial-expansion-pascal-triangle`. -/
def «binomial-expansion-pascal-triangle» (x y k n : Rat) : List Rat :=
  if integerp k ∧ integerp n then binomialExpansionPascalZ x y k.num n.num else []

/-- Helper on `Int` for ACL2 `n-expt`. -/
def nExptZ (x : Rat) (n : Int) : Rat :=
  if _h : 0 < n then x * nExptZ x (n - 1) else 1
termination_by n.toNat
decreasing_by all_goals omega

/-- ACL2 `n-expt`: `(if (and (integerp n) (< 0 n)) (* x (n-expt x (1- n))) 1)`. -/
def «n-expt» (x n : Rat) : Rat := if integerp n then nExptZ x n.num else 1

-- Theorems and lemmas of binomial.lisp, in file order. Local events are included.

axiom «factorial-n/n-1» : ∀ n : Rat,
  integerp n → 1 ≤ n → «factorial» n * («factorial» (-1 + n))⁻¹ = n

axiom «factorial-n/n-1/x» : ∀ n x : Rat,
  integerp n → 1 ≤ n → «factorial» n * («factorial» (-1 + n))⁻¹ * x = n * x

axiom «choose-reduction» : ∀ k n : Rat,
  integerp k → integerp n → 0 < k → k < n →
  «choose» k n = «choose» (k - 1) (n - 1) + «choose» k (n - 1)

axiom «choose-mk-choose» : ∀ k n : Rat, «choose-mk» k n = «choose» k n

axiom «choose-is-non-negative-integer» : ∀ k n : Rat,
  integerp («choose» k n) ∧ 0 ≤ «choose» k n

axiom «binomial-expansion-times-x-correct» : ∀ x y k n : Rat,
  x * sumlist («binomial-expansion» x y k n) = sumlist («binomial-expansion-times-x» x y k n)

axiom «binomial-expansion-times-y-correct» : ∀ x y k n : Rat,
  y * sumlist («binomial-expansion» x y k n) = sumlist («binomial-expansion-times-y» x y k n)

axiom «binomial-expansion-times-x-plus-times-y» : ∀ x y k n : Rat,
  sumlist («binomial-expansion-times-x» x y k n) + sumlist («binomial-expansion-times-y» x y k n)
    = sumlist («binomial-expansion-triangle» x y k n)

axiom «silly-inequality» : ∀ k n : Rat,
  integerp k → integerp n → k < n → 1 + k ≤ n

axiom «choose-k-k» : ∀ k : Rat,
  «choose» k k = if integerp k ∧ 0 ≤ k then 1 else 0

axiom «expt-x-0» : ∀ x : Rat, expt x 0 = 1

axiom «binomial-expansion-triangle-x-y-k-1+k» : ∀ x y k : Rat,
  «binomial-expansion-triangle» x y (1 + k) k = []

axiom «binomial-expansion-triangle-x-y-k-k-lemma» : ∀ x y k : Rat,
  «binomial-expansion-triangle» x y k k = if integerp k ∧ 0 ≤ k then [expt x (1 + k), expt x k * y] else []

axiom «binomial-expansion-pascal-triangle-correct» : ∀ x y k n : Rat,
  integerp k → integerp n → 0 ≤ k → k ≤ n →
  sumlist («binomial-expansion-triangle» x y k n)
    = «choose» k n * expt x k * expt y (1 + (n - k)) + sumlist («binomial-expansion-pascal-triangle» x y k n)

axiom «binomial-expansion-zero» : ∀ x y k n : Rat,
  n < k → «binomial-expansion» x y k n = []

axiom «pascal-triangle-binomial» : ∀ x y k n : Rat,
  integerp k → integerp n → 0 ≤ k →
  sumlist («binomial-expansion-pascal-triangle» x y k n) = sumlist («binomial-expansion» x y (1 + k) (1 + n))

axiom «choose-0-n» : ∀ n : Rat,
  «choose» 0 n = if integerp n ∧ 0 ≤ n then 1 else 0

axiom «binomial-theorem-induction-lemma» : ∀ x y n : Rat,
  integerp n → 0 < n →
  x * sumlist («binomial-expansion» x y 0 (n - 1)) + y * sumlist («binomial-expansion» x y 0 (n - 1))
    = sumlist («binomial-expansion» x y 0 n)

axiom «distributivity-2» : ∀ x y z : Rat, (x + y) * z = x * z + y * z

axiom «binomial-theorem-fake» : ∀ x y n : Rat,
  integerp n → 0 ≤ n → «n-expt» (x + y) n = sumlist («binomial-expansion» x y 0 n)

axiom «n-expt-expt» : ∀ x n : Rat,
  integerp n → 0 ≤ n → expt x n = «n-expt» x n

axiom «binomial-theorem» : ∀ x y n : Rat,
  integerp n → 0 ≤ n → expt (x + y) n = sumlist («binomial-expansion» x y 0 n)

axiom «binomial-sum-commutes» : ∀ x y n : Rat,
  integerp n → 0 ≤ n →
  sumlist («binomial-expansion» x y 0 n) = sumlist («binomial-expansion» y x 0 n)

end ACL2
