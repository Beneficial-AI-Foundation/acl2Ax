/-
Translation of the ACL2 book `std/system/arglistp.lisp` (acl2-8.7 books tree).

Pending import: `include-book "xdoc/top" :dir :system` has no module yet
(Lean/xdoc is empty). It is documentation only, and the statement of this book does not use it.

`arglistp` and `trueListp` are the ACL2.Base declarations (decision 50).
-/

module

public import ACL2.Base

namespace ACL2.«std».«system».«arglistp»

public section

/-- ACL2 `defthm` `true-listp-when-arglistp` (rule-classes :compound-recognizer). -/
public axiom «true-listp-when-arglistp» : ∀ (x : List ACLSymbol), arglistp x → trueListp x

end

end ACL2.«std».«system».«arglistp»
