module

public import ACL2.Base
import «arithmetic-2».pass1.«basic-arithmetic»
import «arithmetic-2».pass1.«inequalities»
import «arithmetic-2».pass1.«prefer-times»

namespace ACL2.«arithmetic-2».pass1.«numerator-and-denominator-helper»

-- numerator-and-denominator-helper.lisp. Functions of the book are opaque signatures with no
-- body (decision 41). The axioms are statements, not proofs. Variables are Rat, except where
-- the ACL2 statement has no integer hypothesis on a value that may be complex (CRat).
-- The `:hints`, `in-theory` and `disable` forms are dropped (decision 40).
-- The local defun induct-on-nonneg-int is generated as an opaque signature (decision 37, revised).

public opaque «nonneg-int-mod» : Rat → Rat → Rat

private opaque «induct-on-nonneg-int» : Rat → Prop

public opaque «nonneg-int-gcd» : Rat → Rat → Rat

public opaque «nonneg-int-gcd-multiplier1» : Rat → Rat → Rat

public opaque «nonneg-int-gcd-multiplier2» : Rat → Rat → Rat

public axiom «Nonneg-int-mod-<-divisor» : ∀ n d : Rat,
  integerp d → 0 < d → «nonneg-int-mod» n d < d

public axiom «Nonneg-int-mod-nonnegative-integer-quotient» : ∀ n d : Rat,
  «nonneg-int-mod» n d + nfix d * «nonnegative-integer-quotient» n d = nfix n

public axiom «Nonneg-int-mod-0» : ∀ d : Rat,
  «nonneg-int-mod» 0 d = 0

public axiom «Nonneg-int-mod-+-*» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 ≤ x → x < n → 0 ≤ j →
  «nonneg-int-mod» (x + j * n) n = x

public axiom «Nonneg-int-mod-+-*-nonneg-int-mod» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 ≤ j → 0 < n → 0 ≤ x →
  «nonneg-int-mod» (x + j * n) n = «nonneg-int-mod» x n

public axiom «Nonneg-int-mod-+-*-nonneg-int-mod-1» : ∀ j k n x : Rat,
  integerp j → integerp k → integerp n → integerp x →
  0 ≤ j → 0 ≤ k → 0 < n → 0 ≤ x → «nonneg-int-mod» k n = 0 →
  «nonneg-int-mod» (x + j * k) n = «nonneg-int-mod» x n

public axiom «Divisor-nonnegative-integer-quotient» : ∀ n d : Rat,
  «nonneg-int-mod» n d = 0 → nfix d * «nonnegative-integer-quotient» n d = nfix n

public axiom «Left-nonneg-int-mod-*» : ∀ j n : Rat,
  integerp j → integerp n → 0 ≤ n → «nonneg-int-mod» (j * n) n = 0

public axiom «Right-nonneg-int-mod-*» : ∀ j n : Rat,
  integerp j → integerp n → 0 ≤ n → «nonneg-int-mod» (n * j) n = 0

public axiom «Nonneg-int-mod-*-0» : ∀ j y n : Rat,
  integerp j → integerp y → 0 ≤ j → «nonneg-int-mod» j n = 0 →
  «nonneg-int-mod» (j * y) n = 0

public axiom «Nonneg-Int-mod-+-0» : ∀ x y n : Rat,
  integerp x → 0 ≤ x → 0 ≤ y → «nonneg-int-mod» x n = 0 → «nonneg-int-mod» y n = 0 →
  «nonneg-int-mod» (x + y) n = 0

public axiom «Nonneg-Int-mod-minus-0» : ∀ x y n : Rat,
  integerp x → integerp y → 0 ≤ y → «nonneg-int-mod» x n = 0 → «nonneg-int-mod» y n = 0 →
  «nonneg-int-mod» (x - y) n = 0

public axiom «Linear-combination-nonneg-int-mod» : ∀ a b x y n : Rat,
  integerp a → integerp b → integerp x → integerp y → 0 ≤ a → 0 ≤ b →
  «nonneg-int-mod» a n = 0 → «nonneg-int-mod» b n = 0 →
  «nonneg-int-mod» (a * x + b * y) n = 0

public axiom «Divisor-<=» : ∀ n d : Rat,
  integerp n → 0 < n → «nonneg-int-mod» n d = 0 → d ≤ n

public axiom «Nonneg-int-mod-1» : ∀ n : Rat,
  «nonneg-int-mod» n 1 = 0

public axiom «Nonneg-int-gcd->-0» : ∀ n d : Rat,
  ((integerp d ∧ 0 < d) ∨ (integerp n ∧ 0 < n)) → 0 < «nonneg-int-gcd» n d

public axiom «Nonneg-int-gcd-is-COMMON-divisor» : ∀ x y : Rat,
  «nonneg-int-mod» x («nonneg-int-gcd» x y) = 0 ∧ «nonneg-int-mod» y («nonneg-int-gcd» x y) = 0

public axiom «Linear-combination-for-nonneg-int-gcd» : ∀ x y : Rat,
  «nonneg-int-gcd» x y =
    nfix x * «nonneg-int-gcd-multiplier1» x y + nfix y * «nonneg-int-gcd-multiplier2» x y

public axiom «Nonneg-int-gcd-is-LARGEST-common-divisor-mod» : ∀ x y d : Rat,
  «nonneg-int-mod» x d = 0 → «nonneg-int-mod» y d = 0 →
  «nonneg-int-mod» («nonneg-int-gcd» x y) d = 0

public axiom «Nonneg-int-gcd-is-LARGEST-common-divisor-<=» : ∀ x y d : Rat,
  ((integerp x ∧ 0 < x) ∨ (integerp y ∧ 0 < y)) →
  «nonneg-int-mod» x d = 0 → «nonneg-int-mod» y d = 0 →
  d ≤ «nonneg-int-gcd» x y

public axiom «Nonnegative-integer-quotient-gcd» : ∀ x y : Rat,
  integerp x → integerp y → 0 ≤ x → 0 ≤ y →
  («nonneg-int-gcd» x y * «nonnegative-integer-quotient» x («nonneg-int-gcd» x y) = x) ∧
  («nonneg-int-gcd» x y * «nonnegative-integer-quotient» y («nonneg-int-gcd» x y) = y)

public axiom «Linear-combination-gcd=1» : ∀ x y z : Rat,
  integerp x → «nonneg-int-gcd» y z = 1 →
  x * y * «nonneg-int-gcd-multiplier1» y z + x * z * «nonneg-int-gcd-multiplier2» y z = x

public axiom «Divisor-of-product-divides-factor» : ∀ x y z : Rat,
  «nonneg-int-mod» (x * y) z = 0 → «nonneg-int-gcd» y z = 1 →
  integerp x → integerp y → 0 ≤ x → 0 ≤ y →
  «nonneg-int-mod» x z = 0

public axiom «Nonneg-int-mod-abs-+-*» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 ≤ n →
  «nonneg-int-mod» (abs (x + j * n)) («nonneg-int-gcd» (abs x) n) = 0

public axiom «Nonneg-int-gcd-abs->=» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 < n →
  «nonneg-int-gcd» (abs x) n ≤ «nonneg-int-gcd» (abs (x + j * n)) n

public axiom «Nonneg-int-mod-abs» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 < n →
  «nonneg-int-mod» (abs x) («nonneg-int-gcd» (abs (x + j * n)) n) = 0

public axiom «Nonneg-int-gcd-abs-<=» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 < n →
  «nonneg-int-gcd» (abs (x + j * n)) n ≤ «nonneg-int-gcd» (abs x) n

public axiom «Nonneg-int-gcd-abs» : ∀ j n x : Rat,
  integerp j → integerp n → integerp x → 0 < n →
  «nonneg-int-gcd» (abs (x + j * n)) n = «nonneg-int-gcd» (abs x) n

public axiom «Commutativity-of-nonneg-int-gcd» : ∀ x y : Rat,
  integerp x → integerp y → 0 ≤ x → 0 ≤ y →
  «nonneg-int-gcd» x y = «nonneg-int-gcd» y x

public axiom «Cross-product-factor» : ∀ a b c d : Rat,
  «nonneg-int-gcd» a b = 1 → a * d = b * c →
  integerp a → integerp b → integerp c → integerp d →
  0 ≤ a → 0 ≤ b → 0 ≤ c → 0 ≤ d →
  («nonneg-int-mod» c a = 0 ∧ «nonneg-int-mod» d b = 0)

public axiom «Nonneg-int-gcd-1-right» : ∀ x : Rat,
  «nonneg-int-gcd» x 1 = 1

public axiom «Nonneg-int-gcd-1-left» : ∀ x : Rat,
  integerp x → 0 ≤ x → «nonneg-int-gcd» 1 x = 1

public axiom «Nonneg-int-gcd-numerator-denominator» : ∀ x : CRat,
  «nonneg-int-gcd» (abs (numeratorC x)) (denominatorC x) = 1

public axiom «Lowest-terms-nonneg-int-mod» : ∀ n1 n2 d1 d2 : Rat,
  integerp n1 → integerp n2 → integerp d1 → integerp d2 → 0 < d1 → 0 < d2 →
  «nonneg-int-gcd» (abs n1) d1 = 1 → d1⁻¹ * n1 = d2⁻¹ * n2 →
  («nonneg-int-mod» d2 d1 = 0 ∧ «nonneg-int-mod» (abs n2) (abs n1) = 0)

public axiom «Lowest-terms-<=» : ∀ n1 n2 d1 d2 : Rat,
  integerp n1 → integerp n2 → integerp d1 → integerp d2 → 0 < d1 → 0 < d2 →
  «nonneg-int-gcd» (abs n1) d1 = 1 → d1⁻¹ * n1 = d2⁻¹ * n2 →
  (d1 ≤ d2 ∧ abs n1 ≤ abs n2)

public axiom «LEAST-numerator-denominator-nonneg-int-mod» : ∀ n d : Rat,
  integerp n → integerp d → 0 < d →
  («nonneg-int-mod» d (denominatorC (↑(d⁻¹ * n))) = 0 ∧
   «nonneg-int-mod» (abs n) (abs (numeratorC (↑(d⁻¹ * n)))) = 0)

public axiom «LEAST-numerator-denominator-<=» : ∀ n d : Rat,
  integerp n → integerp d → 0 < d →
  (denominatorC (↑(d⁻¹ * n)) ≤ d ∧ abs (numeratorC (↑(d⁻¹ * n))) ≤ abs n)

public axiom «Unique-rationalp» : ∀ n d : Rat,
  integerp n → integerp d → 0 < d → «nonneg-int-gcd» (abs n) d = 1 →
  (denominatorC (↑(d⁻¹ * n)) = d ∧ numeratorC (↑(d⁻¹ * n)) = n)

-- Block comments of the ACL2 book, recorded verbatim (decision 48). They state no axiom.
--
-- #| Summer 1997
--      Last modified 30 June 1998
-- 
--       Depends on the Arithmetic Equalities book
--              and the Arithmetic Inequalities book.
-- 
--    Disabled theorems:
--      Divisor-<=
--      Linear-combination-for-nonneg-int-gcd
-- 
-- This book is used to prove all the axioms in the
--      Arithmetic Rationals-with-axioms book
--      [All the axioms in that book are
--       now theorems in the book
--       Rationals-with-axioms-proved]
-- 
--    To certify in Arithmetic Book directory:
-- 
--       (certify-book "mod-gcd")
-- 
-- |#
--

end ACL2.«arithmetic-2».pass1.«numerator-and-denominator-helper»
