/-
Translation of the ACL2 book `std/basic/code-char-char-code-with-force.lisp`.

The two `defthm`s state `code-char` and `char-code` on the shallow domain. The hypothesis
`characterp c` is `characterp (some c)`, because `characterp` takes `Option Char`
(EMBEDDING_DECISIONS.md, decision 50). `force` is the identity, so it is inlined.
-/

module

public import ACL2.Base

namespace ACL2.std.basic.«code-char-char-code-with-force»

public axiom «code-char-char-code-is-identity-forced» : ∀ c : Char, characterp (some c) → «code-char» («char-code» c) = c

public axiom «char-code-code-char-is-identity-forced» : ∀ n : Rat, integerp n → 0 ≤ n → n < 256 → «char-code» («code-char» n) = n

end ACL2.std.basic.«code-char-char-code-with-force»
