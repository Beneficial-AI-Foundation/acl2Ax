/-
Copyright (C) 2022 Kestrel Institute
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/books/3BSD-mod.txt.
Translated from the ACL2 book kestrel/utilities/member-symbol-name.lisp.
-/

/-
Translation of the ACL2 book `kestrel/utilities/member-symbol-name.lisp`
(Kestrel Institute, 3-clause BSD license).

The book has one exported theorem, `not-member-symbol-name-when-not-consp`. Its
statement uses the system function `member-symbol-name`, whose Lean primitive and the
symbol type `ACLSymbol` are declared in the fragment for Lean/ACL2/Base.lean, pending merge.
-/

module

public import ACL2.Base

namespace ACL2.«kestrel».«utilities».«member-symbol-name»

public axiom «not-member-symbol-name-when-not-consp» : ∀ (str : String) (l : List ACLSymbol), l = [] → memberSymbolName str l = []

end ACL2.«kestrel».«utilities».«member-symbol-name»
