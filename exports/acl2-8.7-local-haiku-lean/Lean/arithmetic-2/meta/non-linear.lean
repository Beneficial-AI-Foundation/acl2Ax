module

public import ACL2.Base
import «arithmetic-2».pass1.«top»
import «arithmetic-2».meta.«cancel-terms-helper»
import «arithmetic-2».meta.«cancel-terms-helper»


namespace ACL2.«arithmetic-2».meta.«non-linear»

-- Local theorems of non-linear.lisp, included as axioms (general decision 11).
-- The local includes of "../pass1/top" and "cancel-terms-helper" are not imported (general decision 9).
-- The theorems are stated in the order of the file. The #| |# block with the complex
-- counterexample is a comment and is not generated.

private axiom «*-preserves-<=-1» : ∀ x1 x2 y1 : Rat,
  x1 ≤ x2 → 0 ≤ x1 → 0 ≤ y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 →
  x1 * y1 ≤ x2 * y1

private axiom «*-preserves-<=-2» : ∀ x2 y1 y2 : Rat,
  y1 ≤ y2 → 0 ≤ x2 → 0 ≤ y1 →
  realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x2 * y1 ≤ x2 * y2

private axiom «*-preserves-<-1» : ∀ x1 x2 y1 : Rat,
  x1 < x2 → 0 ≤ x1 → 0 < y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 →
  x1 * y1 < x2 * y1

private axiom «*-preserves-<-2» : ∀ x2 y1 y2 : Rat,
  y1 < y2 → 0 < x2 → 0 ≤ y1 →
  realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x2 * y1 < x2 * y2

public axiom «*-preserves-<=-for-nonnegatives» : ∀ x1 x2 y1 y2 : Rat,
  x1 ≤ x2 → y1 ≤ y2 → 0 ≤ x1 → 0 ≤ y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x1 * y1 ≤ x2 * y2

public axiom «*-preserves-<-for-nonnegatives» : ∀ x1 x2 y1 y2 : Rat,
  x1 < x2 → y1 < y2 → 0 ≤ x1 → 0 ≤ y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x1 * y1 < x2 * y2

public axiom «*-preserves-<-for-nonnegatives-stronger-1» : ∀ x1 x2 y1 y2 : Rat,
  x1 ≤ x2 → y1 < y2 → 0 < x1 → 0 ≤ y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x1 * y1 < x2 * y2

public axiom «*-preserves-<-for-nonnegatives-stronger-2» : ∀ x1 x2 y1 y2 : Rat,
  x1 < x2 → y1 ≤ y2 → 0 ≤ x1 → 0 < y1 →
  realrationalp x1 → realrationalp x2 → realrationalp y1 → realrationalp y2 →
  x1 * y1 < x2 * y2

public axiom «*-weakly-monotonic» : ∀ y yp : CRat, ∀ x : Rat,
  acl2le y yp → realrationalp x → 0 ≤ x →
  acl2le ((↑x : CRat) * y) ((↑x : CRat) * yp)

public axiom «*-strongly-monotonic» : ∀ y yp : CRat, ∀ x : Rat,
  y < yp → realrationalp x → 0 < x →
  (↑x : CRat) * y < (↑x : CRat) * yp

public axiom «*-weakly-monotonic-negative-multiplier» : ∀ y yp : CRat, ∀ x : Rat,
  acl2le y yp → realrationalp x → x < 0 →
  acl2le ((↑x : CRat) * yp) ((↑x : CRat) * y)

public axiom «*-strongly-monotonic-negative-multiplier» : ∀ y yp : CRat, ∀ x : Rat,
  y < yp → realrationalp x → x < 0 →
  (↑x : CRat) * yp < (↑x : CRat) * y

public axiom «/-weakly-monotonic» : ∀ y yp : Rat,
  y ≤ yp → realrationalp y → realrationalp yp → 0 < y →
  yp⁻¹ ≤ y⁻¹

public axiom «/-strongly-monotonic» : ∀ y yp : Rat,
  y < yp → realrationalp y → realrationalp yp → 0 < y →
  yp⁻¹ < y⁻¹

public axiom «x*y>1-positive» : ∀ x y : Rat,
  1 < x → 1 < y → realrationalp x → realrationalp y →
  1 < x * y

public axiom «x*y>1-positive-stronger» : ∀ x y : Rat,
  ((1 < x ∧ 1 ≤ y) ∨ (1 ≤ x ∧ 1 < y)) → realrationalp x → realrationalp y →
  1 < x * y

public axiom «x*y>=1-positive» : ∀ x y : Rat,
  1 ≤ x → 1 ≤ y → realrationalp x → realrationalp y →
  1 ≤ x * y

public axiom «x*y>1-negative» : ∀ x y : Rat,
  x < -1 → y < -1 → realrationalp x → realrationalp y →
  1 < x * y

public axiom «x*y>=1-negative» : ∀ x y : Rat,
  x ≤ -1 → y ≤ -1 → realrationalp x → realrationalp y →
  1 ≤ x * y

public axiom «ratio-theory-of-1-a» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 ≤ x → 0 < y → x ≤ y →
  (0 ≤ x / y ∧ x / y ≤ 1)

public axiom «ratio-theory-of-1-b» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 ≤ x → x < y →
  (0 ≤ x / y ∧ x / y < 1)

public axiom «ratio-theory-of-1-c» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 < x → 0 < y → y ≤ x →
  (0 < x / y ∧ 1 ≤ x / y)

public axiom «ratio-theory-of-1-d» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 < y → y < x →
  (0 < x / y ∧ 1 < x / y)

public axiom «ratio-theory-of-1-e» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 ≤ x → y < 0 → x ≤ -y →
  (x / y ≤ 0 ∧ -1 ≤ x / y)

public axiom «ratio-theory-of-1-f» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 ≤ x → x < -y →
  (x / y ≤ 0 ∧ -1 < x / y)

public axiom «ratio-theory-of-1-g» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 < x → y < 0 → -y ≤ x →
  x / y ≤ -1

public axiom «ratio-theory-of-1-h» : ∀ x y : Rat,
  realrationalp x → realrationalp y → y < 0 → -y < x →
  x / y < -1

public axiom «ratio-theory-of-1-i» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x ≤ 0 → 0 < y → -x ≤ y →
  (x / y ≤ 0 ∧ -1 ≤ x / y)

public axiom «ratio-theory-of-1-j» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x ≤ 0 → -x < y →
  (x / y ≤ 0 ∧ -1 < x / y)

public axiom «ratio-theory-of-1-k» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x < 0 → 0 < y → y ≤ -x →
  x / y ≤ -1

public axiom «ratio-theory-of-1-l» : ∀ x y : Rat,
  realrationalp x → realrationalp y → 0 < y → y < -x →
  x / y < -1

public axiom «ratio-theory-of-1-m» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x < 0 → y < 0 → x ≤ y →
  1 ≤ x / y

public axiom «ratio-theory-of-1-n» : ∀ x y : Rat,
  realrationalp x → realrationalp y → y < 0 → x < y →
  1 < x / y

public axiom «ratio-theory-of-1-o» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x ≤ 0 → y < 0 → y ≤ x →
  (0 ≤ x / y ∧ x / y ≤ 1)

public axiom «ratio-theory-of-1-p» : ∀ x y : Rat,
  realrationalp x → realrationalp y → x ≤ 0 → y < x →
  (0 ≤ x / y ∧ x / y < 1)

-- Block comments of the ACL2 book, recorded verbatim (decision 48). They state no axiom.
--
-- #| Here is the complex counterexample to which we alluded above.
-- 
-- (let ((y  #c(1 -1))
--       (y+ #c(1 1))
--       (x  #c(1 1)))
--     (implies (and (<= y y+)
--                   (<= 0 x))
--              (<= (* x y) (* x y+))))
-- |#
--

end ACL2.«arithmetic-2».meta.«non-linear»
