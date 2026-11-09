/-
Shallow embedding of the ACL2 book `arithmetic/sumlist.lisp`.
The book has no include-book forms, so it has no imports beyond `ACL2.Base`.
The defun `sumlist` is declared in `ACL2.Base` (the signature only), and the
`realp-sumlist` theorem sits under `#+:non-standard-analysis`, so it is excluded
in standard ACL2 (EMBEDDING_DECISIONS.md, decision 12).
-/

module

public import ACL2.Base

namespace ACL2.«arithmetic».«sumlist»

/-- ACL2 `rationalp-sumlist` (sumlist.lisp, line 25): if `x` is a rational list, then the sum is rational. -/
public axiom «rationalp-sumlist» : ∀ x : List Rat, rationalListp x → rationalp («sumlist» x)

/-- ACL2 `sumlist-append` (sumlist.lisp, line 37): the sum of an append is the sum of the sums. -/
public axiom «sumlist-append» : ∀ x y : List Rat, «sumlist» (x ++ y) = «sumlist» x + «sumlist» y

end ACL2.«arithmetic».«sumlist»
