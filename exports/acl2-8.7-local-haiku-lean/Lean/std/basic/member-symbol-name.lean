/-
Translation of std/basic/member-symbol-name.lisp (ACL2 8.7 books).
Shallow embedding. The symbol type `ACLSymbol` and the function `memberSymbolName` are the
ACL2.Base declarations (decision 50), so this module declares neither.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«member-symbol-name»

/-- The ACL2 theorem `member-symbol-name-when-atom` (std/basic/member-symbol-name.lisp).
The hypothesis `(atom symbols)` is `symbols = []`, and the truth value of
`(not (member-symbol-name string symbols))` is `¬ (memberSymbolName string symbols ≠ [])`. -/
public axiom «member-symbol-name-when-atom» : ∀ (string : String) (symbols : List ACLSymbol),
  symbols = [] → ¬ (memberSymbolName string symbols ≠ [])

end ACL2.std.basic.«member-symbol-name»
