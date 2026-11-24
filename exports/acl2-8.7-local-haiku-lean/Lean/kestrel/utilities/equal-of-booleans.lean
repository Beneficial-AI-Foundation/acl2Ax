/-
Copyright (C) 2008-2011 Eric Smith and Stanford University
Copyright (C) 2013-2019 Kestrel Institute
Copyright (c) 2026, Beneficial AI Foundation
License: 3-clause BSD, see LICENSES/acl2/books/3BSD-mod.txt.
Translated from the ACL2 book kestrel/utilities/equal-of-booleans.lisp.
-/

module

public import ACL2.Base

namespace ACL2.kestrel.utilities.«equal-of-booleans»

-- equal-of-booleans.lisp. Truth values are `Prop` (decision table, shallow embedding).
-- `booleanp` is `True` on `Prop` (see the fragment for the deviation), `equal` is `=`
-- and `iff` is `↔`.

public axiom «equal-of-booleans-cheap» : ∀ x y : Prop, booleanp x → booleanp y → ((x = y) ↔ (x ↔ y))

public axiom «equal-of-booleans» : ∀ x y : Prop, booleanp x → booleanp y → ((x = y) ↔ (x ↔ y))

end ACL2.kestrel.utilities.«equal-of-booleans»
