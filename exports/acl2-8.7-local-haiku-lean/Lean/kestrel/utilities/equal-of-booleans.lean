module

public import ACL2.Base

namespace ACL2.kestrel.utilities.«equal-of-booleans»

-- equal-of-booleans.lisp. Truth values are `Prop` (decision table, shallow embedding).
-- `booleanp` is `True` on `Prop` (see the fragment for the deviation), `equal` is `=`
-- and `iff` is `↔`.

public axiom «equal-of-booleans-cheap» : ∀ x y : Prop, booleanp x → booleanp y → ((x = y) ↔ (x ↔ y))

public axiom «equal-of-booleans» : ∀ x y : Prop, booleanp x → booleanp y → ((x = y) ↔ (x ↔ y))

end ACL2.kestrel.utilities.«equal-of-booleans»
