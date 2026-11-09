/-
Translation of std/basic/symbol-name-lst.lisp (ACL2 8.7 books).
Shallow embedding. The symbol type `ACLSymbol`, the functions `symbolNameLst` and `len`, and
`stringListp` are the ACL2.Base declarations, so this module declares none of them.
-/

module

public import ACL2.Base

-- Non-local include not yet imported: xdoc/constructors (no module under Lean/xdoc yet).
-- It is added with `public import` once its module exists.

namespace ACL2.std.basic.«symbol-name-lst»

/-- The ACL2 theorem `string-listp-of-symbol-name-lst` (std/basic/symbol-name-lst.lisp, line 22):
`(string-listp (symbol-name-lst syms))`. -/
public axiom «string-listp-of-symbol-name-lst» : ∀ (syms : List ACLSymbol), stringListp (symbolNameLst syms)

/-- The ACL2 theorem `len-of-symbol-name-lst` (std/basic/symbol-name-lst.lisp, line 25):
`(equal (len (symbol-name-lst syms)) (len syms))`. -/
public axiom «len-of-symbol-name-lst» : ∀ (syms : List ACLSymbol), len (symbolNameLst syms) = len syms

end ACL2.std.basic.«symbol-name-lst»
