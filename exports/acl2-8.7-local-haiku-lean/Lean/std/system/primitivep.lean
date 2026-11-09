/-
Translation of the ACL2 book `std/system/primitivep.lisp` (acl2-8.7 books tree).

Pending imports: `include-book "std/util/define" :dir :system` and
`include-book "xdoc/constructors" :dir :system` have no module yet
(Lean/std/util has no `define` module, Lean/xdoc is empty). The `define` macro is
not translated, and the statement of this book does not use the macro, only its
generated function `primitivep`.

`symbolp` is a primitive that ACL2.Base lacks. It is declared here, in the book
namespace, and its interpretation is recorded in the fragment (decision 50 style).
-/

module

public import ACL2.Base

namespace ACL2.«std».«system».«primitivep»

public section

/-- ACL2 `defthm` `primitivep-forward-to-symbolp` (std/system/primitivep.lisp, line 28),
`:rule-classes :forward-chaining`. -/
public axiom «primitivep-forward-to-symbolp» : ∀ (fn : ACLSymbol), primitivep fn → symbolp fn

end

end ACL2.«std».«system».«primitivep»
