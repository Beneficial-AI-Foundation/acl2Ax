module

public import ACL2.Base
import «arithmetic-2».pass1.«top»

-- Local includes that are not yet imported: ../pass1/top. Each is imported with a plain `import`
-- once its module exists (EMBEDDING_DECISIONS.md, decision 30).

namespace ACL2.«arithmetic-2».meta.«cancel-terms-helper»

-- Local theorems of cancel-terms-helper.lisp, included as axioms (general decision 11).
-- The local include of "../pass1/top" is not imported (general decision 9).

private axiom «hack0» : ∀ x y z : Rat,
  realrationalp x → realrationalp y → realrationalp z →
  (↑z : CRat) * complex x y = complex (x * z) (y * z)

private axiom «hack1» : ∀ x y : Rat,
  realrationalp x → realrationalp y →
  (realrationalpC (complex x y) ↔ y = 0)

private axiom «step-one» : ∀ (a : Rat) (x y : CRat),
  realrationalp a → ¬ (a = 0) →
  (x < y ↔
    (if a < 0 then (↑a : CRat) * y < (↑a : CRat) * x
     else if 0 < a then (↑a : CRat) * x < (↑a : CRat) * y
     else False))

-- Exported lemmas of cancel-terms-helper.lisp, in file order.
-- helper-9 in the #| |# block at the end of the file is a comment and is not generated.

public axiom «helper-0» : ∀ a x y : CRat,
  ¬ (fixC a = 0) → ((a * x = y * a) ↔ (fixC x = fixC y))

public axiom «helper-1» : ∀ x y z a : CRat,
  ¬ (fixC a = 0) → ((x * a = y * z * a) ↔ (fixC x = y * z))

public axiom «helper-2» : ∀ w x y z a : CRat,
  ¬ (fixC a = 0) → ((w * x * a = y * z * a) ↔ (w * x = y * z))

public axiom «helper-3» : ∀ w x y z a : CRat,
  ¬ (fixC a = 0) → ((w * a + x * a = y * a + z * a) ↔ (x + w = z + y))

public axiom «helper-4» : ∀ x y z a : CRat,
  ¬ (fixC a = 0) → ((x * a + y * a = z * a) ↔ (x + y = fixC z))

public axiom «helper-5» : ∀ w x y z a : CRat,
  ¬ (fixC a = 0) → ((w * a + x * a = y * z * a) ↔ (w + x = y * z))

public axiom «helper-6» : ∀ a b : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  ((a * (↑x : CRat)) < (b * (↑x : CRat)) ↔ (if (0 : Rat) < x then a < b else b < a))

public axiom «helper-6a» : ∀ a b : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  (((↑x : CRat) * a) < ((↑x : CRat) * b) ↔ (if (0 : Rat) < x then a < b else b < a))

public axiom «helper-7» : ∀ a b c : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  ((a * (↑x : CRat) + b * (↑x : CRat)) < c * (↑x : CRat) ↔
    (if (0 : Rat) < x then a + b < c else c < a + b))

public axiom «helper-8» : ∀ a b c : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  (c * (↑x : CRat) < (a * (↑x : CRat) + b * (↑x : CRat)) ↔
    (if (0 : Rat) < x then c < a + b else a + b < c))

public axiom «helper-9» : ∀ a b c : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  ((a * (↑x : CRat)) < (b * c * (↑x : CRat)) ↔
    (if (0 : Rat) < x then a < b * c else b * c < a))

public axiom «helper-10» : ∀ a b c : CRat, ∀ x : Rat,
  realrationalp x → ¬ (x = 0) →
  ((a * b * (↑x : CRat)) < (c * (↑x : CRat)) ↔
    (if (0 : Rat) < x then a * b < c else c < a * b))

public axiom «helper-11» : ∀ x : Rat, ∀ y : CRat,
  realrationalp x →
  ((0 : CRat) < (↑x : CRat) * y ↔
    (if x < 0 then y < 0 else if 0 < x then (0 : CRat) < y else False))

public axiom «helper-12» : ∀ x : CRat, ∀ y : Rat,
  realrationalp y →
  ((0 : CRat) < x * (↑y : CRat) ↔
    (if x < 0 then y < 0 else if (0 : CRat) < x then (0 : Rat) < y else False))

public axiom «helper-13» : ∀ x : Rat, ∀ y : CRat,
  realrationalp x →
  ((↑x : CRat) * y < 0 ↔
    (if x < 0 then (0 : CRat) < y else if 0 < x then y < 0 else False))

public axiom «helper-14» : ∀ x : CRat, ∀ y : Rat,
  realrationalp y →
  (x * (↑y : CRat) < 0 ↔
    (if x < 0 then (0 : Rat) < y else if (0 : CRat) < x then y < 0 else False))

-- Block comments of the ACL2 book, recorded verbatim (decision 48). They state no axiom.
--
-- #|
-- (defthm helper-9
--   (implies (and (real/rationalp x)
-- 		(not (equal x 0)))
-- 	   (equal (< (* a b x)
-- 		     (* c d x))
-- 		  (if (< 0 x)
-- 		      (< (* a b) (* c d))
-- 		      (< (* c d) (* a b)))))
--   :hints (("Goal" :use (:instance step-one
-- 				  (x (* a b x))
-- 				  (y (* c d x))
-- 				  (a (/ x))))))
-- |#
--

end ACL2.«arithmetic-2».meta.«cancel-terms-helper»
