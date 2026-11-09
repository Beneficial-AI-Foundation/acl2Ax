/-
Shallow embedding of the ACL2 book `misc/character-encoding-test.lisp`.
The book has one `defun`, `test-2`, declared in `Lean/ACL2/Base.lean` as an opaque
`String` constant, and one `defthm`, `len-test-2`.
-/

module

public import ACL2.Base

namespace ACL2.«misc».«character-encoding-test»

/-- ACL2 `defthm` `len-test-2` (misc/character-encoding-test.lisp, line 37): the length of
`(test-2)` is 2. -/
public axiom «len-test-2» : length «test-2» = 2

end ACL2.«misc».«character-encoding-test»
