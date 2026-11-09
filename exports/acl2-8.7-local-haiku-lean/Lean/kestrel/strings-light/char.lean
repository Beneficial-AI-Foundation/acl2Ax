/-
Shallow translation of `kestrel/strings-light/char.lisp` (ACL2 books, Kestrel Institute).
The book has one exported `defthm`, `characterp-of-char`. Its `local` include of
`kestrel/lists-light/nth` has no module yet, so it is recorded here as pending.
Pending import: `import kestrel.lists-light.nth`.
-/

module

public import ACL2.Base

namespace ACL2.kestrel.«strings-light».«char»

/-- ACL2 `characterp-of-char`, with the `:hints` and `:rule-classes` removed. -/
public axiom «characterp-of-char» : ∀ (s : String) (n : Rat),
      (characterp («char» s n) ↔ (stringp s ∧ nfix n < length s))

end ACL2.kestrel.«strings-light».«char»
