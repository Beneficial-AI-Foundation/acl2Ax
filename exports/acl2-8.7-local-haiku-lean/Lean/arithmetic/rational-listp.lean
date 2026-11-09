/-
Shallow embedding of the ACL2 book `arithmetic/rational-listp.lisp`.
The book has two `defthm` events, both exported, and no `local` event.
The module holds one `public axiom` per event (EMBEDDING_DECISIONS.md, decisions 5, 53 and 54).
-/

module

public import ACL2.Base

namespace ACL2.«arithmetic».«rational-listp»

/-- `append-preserves-rational-listp`: `(implies (true-listp x) (equal (rational-listp (append x y)) (and (rational-listp x) (rational-listp y))))`. -/
public axiom «append-preserves-rational-listp» : ∀ (x y : List Rat), trueListp x → (rationalListp (x ++ y) ↔ (rationalListp x ∧ rationalListp y))

/-- `rationalp-car-rational-listp`: `(implies (and (rational-listp x) x) (rationalp (car x)))`. The `car` of a nonempty list is its head, and `x.headD 0` stands for it (EMBEDDING_DECISIONS.md, decision 54). -/
public axiom «rationalp-car-rational-listp» : ∀ (x : List Rat), (rationalListp x ∧ x ≠ []) → rationalp (x.headD 0)

end ACL2.«arithmetic».«rational-listp»
