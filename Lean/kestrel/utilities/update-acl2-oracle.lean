/-
Translation of the ACL2 book `kestrel/utilities/update-acl2-oracle.lisp` (Kestrel Institute,
3-clause BSD license). Shallow embedding.

The book has three exported theorems. Their statements use the system functions
`open-input-channels`, `w`, `state-p1` and `update-acl2-oracle` (axioms.lisp, lines 14205,
18875, 15604 and 14241). Their Lean primitives, and the opaque type `State`, are declared in the
fragment for Lean/ACL2/Base.lean, pending merge (decision 53 in EMBEDDING_DECISIONS.md).
-/

module

public import ACL2.Base

namespace ACL2.kestrel.utilities.«update-acl2-oracle»

/-- The ACL2 theorem `open-input-channels-of-update-acl2-oracle` (kestrel/utilities/update-acl2-oracle.lisp, line 15).
The oracle argument `x` ranges over lists, as the theorem `state-p1-of-update-acl2-oracle` requires (decision 53). -/
public axiom «open-input-channels-of-update-acl2-oracle» : ∀ {α : Type} (x : List α) (st : State), «open-input-channels» («update-acl2-oracle» x st) = «open-input-channels» st

/-- The ACL2 theorem `w-of-update-acl2-oracle` (kestrel/utilities/update-acl2-oracle.lisp, line 20). -/
public axiom «w-of-update-acl2-oracle» : ∀ {α : Type} (x : List α) (st : State), «w» («update-acl2-oracle» x st) = «w» st

/-- The ACL2 theorem `state-p1-of-update-acl2-oracle` (kestrel/utilities/update-acl2-oracle.lisp, line 25).
The ACL2 `equal` of two truth values is the biconditional. -/
public axiom «state-p1-of-update-acl2-oracle» : ∀ {α : Type} (x : List α) (st : State), «state-p1» st → («state-p1» («update-acl2-oracle» x st) ↔ trueListp x)

end ACL2.kestrel.utilities.«update-acl2-oracle»
