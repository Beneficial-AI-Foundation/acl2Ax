/-
Copyright (C) 2020 Kestrel Institute (http://www.kestrel.edu)
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/LICENSE.
Translated from the ACL2 book std/strings/digit-to-char.lisp.
-/

/-
Translation of the ACL2 book `std/strings/digit-to-char.lisp` (acl2-8.7 books tree).

The two theorems are about the ACL2 system functions `digit-to-char` (axioms.lisp, line 7364)
and `integer-range-p` (axioms.lisp, line 16670). Their interpretations are the ACL2.Base
definitions `«digit-to-char»` and `«integer-range-p»` (EMBEDDING_DECISIONS.md, decision 53), and
`digitToCharC` for `zero-digit-to-char`, whose variable ranges over `CRat` (decision 71).
The book has no `include-book`.
-/

module

public import ACL2.Base

namespace ACL2.std.strings.«digit-to-char»

public section

/-- ACL2 `digit-to-char-injective`:
`(implies (and (integer-range-p 0 16 x) (integer-range-p 0 16 y))
(equal (equal (digit-to-char x) (digit-to-char y)) (equal x y)))`. -/
public axiom «digit-to-char-injective» : ∀ x y : Rat, «integer-range-p» 0 16 x → «integer-range-p» 0 16 y → («digit-to-char» x = «digit-to-char» y ↔ x = y)

/-- ACL2 `zero-digit-to-char` (defthmd):
`(equal (equal (digit-to-char x) #\0) (or (not (integerp x)) (<= x 0) (< 15 x)))`.
No hypothesis makes `x` rational, so `x` ranges over `CRat`, with `<=` read as `acl2le` and `<` as
the order of `completion-of-<` (decision 71). -/
public axiom «zero-digit-to-char» : ∀ x : CRat, (digitToCharC x = '0' ↔ ((¬ integerpC x) ∨ acl2le x 0 ∨ 15 < x))

end

end ACL2.std.strings.«digit-to-char»
