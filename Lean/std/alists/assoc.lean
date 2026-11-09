/-
Translation of the ACL2 book `std/alists/assoc.lisp` (acl2-8.7 books tree).

Pending import: `include-book "xdoc/top" :dir :system` has no module yet
(Lean/xdoc is empty). It is documentation only, and no statement of this book uses it.

The alist type and `assoc-equal` are the ACL2.Base definitions `AList`, `alistp` and
`assocEqual` (EMBEDDING_DECISIONS.md, decision 49).
-/

module

public import ACL2.Base

namespace ACL2.std.alists.assoc

public section

/-- ACL2 `consp-of-assoc-equal`:
`(implies (alistp alist) (iff (consp (assoc-equal key alist)) (assoc-equal key alist)))`.
In this representation the truth of `(assoc-equal key alist)` is its being a pair, so both
sides of the `iff` are `(assocEqual key alist).isSome`. -/
public axiom «consp-of-assoc-equal» : ∀ {α β : Type} [DecidableEq α] (key : α) (alist : AList α β),
    alistp alist → ((assocEqual key alist).isSome ↔ (assocEqual key alist).isSome)

end

end ACL2.std.alists.assoc
