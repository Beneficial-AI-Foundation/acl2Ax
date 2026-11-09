/-
Deep embedding of ACL2 objects, the base of the project.
An ACL2 object is a value of `V`. Truth follows ACL2: every value except `NIL` is true.
Each ACL2 primitive is a Lean function on `V`. A theorem is an `axiom` of the form
`truthy (formula)`, where `formula` is built from these functions.
Primitives are added here as the books need them. Each addition is recorded in
EMBEDDING_DECISIONS.md under the interpretation table.
-/

module

namespace ACL2

public section

/-- An ACL2 object: a rational number, a symbol, a string or a cons cell. -/
inductive V where
  | num : Rat → V
  | sym : String → V
  | str : String → V
  | cons : V → V → V
  deriving DecidableEq

/-- ACL2 `nil`. -/
def NIL : V := .sym "NIL"

/-- ACL2 `t`. -/
def T : V := .sym "T"

/-- ACL2 truth: every object except `nil` is true. -/
def truthy (v : V) : Prop := v ≠ NIL

/-- A Lean proposition as an ACL2 truth value. -/
def ofProp (p : Prop) [Decidable p] : V := if p then T else NIL

/-- ACL2 `car`. -/
def car : V → V
  | .cons a _ => a
  | _ => NIL

/-- ACL2 `cdr`. -/
def cdr : V → V
  | .cons _ d => d
  | _ => NIL

/-- ACL2 `consp`. -/
def consp : V → V
  | .cons _ _ => T
  | _ => NIL

/-- ACL2 `acl2-numberp`. -/
def acl2NumberP : V → V
  | .num _ => T
  | _ => NIL

end

end ACL2
