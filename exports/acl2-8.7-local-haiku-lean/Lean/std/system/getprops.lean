/-
Translation of the ACL2 book `std/system/getprops.lisp` (Standard System Library,
Kestrel Institute, 3-clause BSD license).

The book has one exported theorem, `alistp-of-getprops`. Its value `getprops` is an alist
(EMBEDDING_DECISIONS.md, decision 49), so the statement holds of every typed value of
`getprops`, and the axiom is stated with the signature of `getprops` from ACL2.Base.

The non-local `(include-book "xdoc/top" :dir :system)` has no module under Lean/
(Lean/xdoc is empty), so its import is pending and is not written.
-/

module

public import ACL2.Base

namespace ACL2.std.system.getprops

public section

/-- ACL2 `alistp-of-getprops`: `(alistp (getprops key world-name w))`. -/
public axiom «alistp-of-getprops» : ∀ {β : Type} (key worldName : ACLSymbol) (w : World),
    alistp (@«getprops» β key worldName w)

end

end ACL2.std.system.getprops
