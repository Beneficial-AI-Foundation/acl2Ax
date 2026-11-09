module

public import ACL2.Base
public import «arithmetic-2».pass1.«basic-arithmetic»
public import «arithmetic-2».pass1.«inequalities»
public import «arithmetic-2».pass1.«expt»
public import «arithmetic-2».pass1.«prefer-times»
public import «arithmetic-2».pass1.«mini-theories»
public import «arithmetic-2».pass1.«numerator-and-denominator»

namespace ACL2.«arithmetic-2».pass1.«top»

-- top.lisp. Its non-local includes are public imports, so its importers see them (decision 30).
-- Every defthm of the file is inside a #| |# block comment, so the book has no theorem
-- outside a comment, and this module has no axiom (decision 46).

-- Block comments of the ACL2 book, recorded verbatim (decision 48). They state no axiom.
--
-- #| ???
-- (defthm three
--   (implies (rationalp x)
-- 	   (rationalp (expt x y)))
--   :rule-classes :type-prescription)
-- 
-- #+:non-standard-analysis
-- (defthm three-realp
--   (implies (realp x)
-- 	   (realp (expt x y)))
--   :rule-classes :type-prescription)
-- 
-- (defthm four
--   (equal (* x (expt x -1))
-- 	 (if (equal (fix x) 0)
-- 	     0
-- 	     1)))
-- 
-- (defthm five
--   (equal (* y x (expt y -1))
-- 	 (if (equal (fix y) 0)
-- 	     0
-- 	     (fix x))))
-- 
-- (defthm six
--   (equal (/ x)
-- 	 (expt x -1))
--   :hints (("Goal" :expand (expt x -1))))
-- |#
--
-- #| !!!
-- (defthm seven
--   (implies (not (acl2-numberp x))
-- 	   (equal (expt x y)
-- 		  (if (equal (ifix y) 0)
-- 		      1
-- 		      0))))
-- |#
--
-- #| ???
-- (in-theory (disable expt))
-- |#
--

end ACL2.«arithmetic-2».pass1.«top»
