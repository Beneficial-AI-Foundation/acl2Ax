module

public import ACL2.Base
public import «arithmetic-3».pass1.«basic-arithmetic»
public import «arithmetic-3».pass1.«inequalities»
public import «arithmetic-3».pass1.«expt»
public import «arithmetic-3».pass1.«prefer-times»
public import «arithmetic-3».pass1.«mini-theories»
public import «arithmetic-3».pass1.«numerator-and-denominator»
public import «arithmetic-3».pass1.«non-linear»

namespace ACL2.«arithmetic-3».pass1.«top»

-- top.lisp. Its non-local includes are public imports, so its importers see them (decision 30).
-- The book has no defun and no theorem, so this module has no axiom (decision 65).

end ACL2.«arithmetic-3».pass1.«top»
