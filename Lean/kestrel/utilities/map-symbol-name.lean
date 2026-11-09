/-
Translation of the ACL2 book `kestrel/utilities/map-symbol-name.lisp`
(Kestrel Institute, 3-clause BSD license).

The book defines `map-symbol-name` (a `defund`, opaque signature, decision 41) and has two
exported theorems, `string-listp-of-map-symbol-name` and `map-symbol-name-of-cons`. The
predicate `stringListp` is declared here, pending merge into Lean/ACL2/Base.lean (see the fragment).
-/

module

public import ACL2.Base

namespace ACL2.«kestrel».«utilities».«map-symbol-name»

/-- ACL2 `map-symbol-name`: the list of `symbol-name`s of a list of symbols. The body is not
represented, so the function is an opaque signature (decision 41). -/
public opaque «map-symbol-name» : List ACLSymbol → List String

public axiom «string-listp-of-map-symbol-name» : ∀ (syms : List ACLSymbol), stringListp («map-symbol-name» syms)

public axiom «map-symbol-name-of-cons» : ∀ (sym : ACLSymbol) (syms : List ACLSymbol), «map-symbol-name» (sym :: syms) = sym.name :: «map-symbol-name» syms

end ACL2.«kestrel».«utilities».«map-symbol-name»
