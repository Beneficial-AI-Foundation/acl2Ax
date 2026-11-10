/-
Shallow interpretation of the ACL2 primitives used by the arithmetic books.
The domain is `Rat`, which corresponds to the ACL2 rationals. Each ACL2
function is interpreted on `Rat`. Deviations are recorded in EMBEDDING_DECISIONS.md.
-/

module

namespace ACL2

public section

/-- `real/rationalp` on the rationals, interpreted as membership in `Rat`. -/
def realrationalp (_x : Rat) : Prop := True

/-- `acl2-numberp` on the rationals, interpreted as membership in `Rat`. -/
def acl2NumberP (_x : Rat) : Prop := True

/-- `rationalp` on the rationals, interpreted as membership in `Rat`. -/
def rationalp (_x : Rat) : Prop := True

/-- `rational-listp` on lists of rationals, interpreted as membership in `List Rat`. -/
def rationalListp (_l : List Rat) : Prop := True

/-- ACL2 `integerp` on the rationals: the denominator is 1. -/
def integerp (r : Rat) : Prop := r.den = 1

instance (r : Rat) : Decidable (integerp r) :=
  inferInstanceAs (Decidable (r.den = 1))

/-- ACL2 `zp`: `(if (integerp x) (<= x 0) t)`. -/
def zp (x : Rat) : Prop := integerp x → x ≤ 0

instance (x : Rat) : Decidable (zp x) :=
  inferInstanceAs (Decidable (integerp x → x ≤ 0))

/-- ACL2 `fix` on numbers: `(if (acl2-numberp x) x 0)`. -/
def fix (x : Rat) : Rat := x

/-- ACL2 `nfix`: `(if (and (integerp x) (>= x 0)) x 0)`. -/
def nfix (x : Rat) : Rat := if integerp x ∧ 0 ≤ x then x else 0

/-- ACL2 `abs`: `(if (minusp x) (- x) x)`, from axioms.lisp. -/
def abs (x : Rat) : Rat := if x < 0 then -x else x

/-- ACL2 `expt` on an integer exponent, following axioms.lisp:
`(cond ((zip i) 1) ((= (fix r) 0) 0) ((> i 0) (* r (expt r (+ i -1))))
       (t (* (/ r) (expt r (+ i +1)))))`. -/
def exptInt (r : Rat) (i : Int) : Rat :=
  if i = 0 then 1
  else if r = 0 then 0
  else if 0 < i then r * exptInt r (i - 1)
  else r⁻¹ * exptInt r (i + 1)
termination_by i.natAbs
decreasing_by all_goals omega

/-- ACL2 `expt` on the rationals: an integer exponent `i` gives `exptInt r i.num`,
and a non-integer exponent gives 1, because `zip` holds for it. -/
def expt (r i : Rat) : Rat := if integerp i then exptInt r i.num else 1

/-! ## Complex rationals

ACL2 numbers that are not real are complex rationals `a + b i` with `a`, `b` rational.
`CRat` is the pair of rationals with the field operations, and `<` is the lexicographic
order of `completion-of-<` in axioms.lisp (lines 25364 to 25374). -/

/-- An ACL2 complex rational: the real part `re` and the imaginary part `im`. -/
structure CRat where
  re : Rat
  im : Rat
  deriving DecidableEq

instance : Inhabited CRat := ⟨⟨0, 0⟩⟩

namespace CRat

instance : OfNat CRat n := ⟨⟨n, 0⟩⟩

instance : Coe Rat CRat := ⟨fun r => ⟨r, 0⟩⟩

instance : Add CRat := ⟨fun a b => ⟨a.re + b.re, a.im + b.im⟩⟩

instance : Neg CRat := ⟨fun a => ⟨-a.re, -a.im⟩⟩

instance : Sub CRat := ⟨fun a b => ⟨a.re - b.re, a.im - b.im⟩⟩

instance : Mul CRat := ⟨fun a b => ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩⟩

/-- ACL2 `(/ x)`: the inverse of a nonzero complex rational, and 0 for 0. -/
def inv (a : CRat) : CRat :=
  let n := a.re * a.re + a.im * a.im
  if n = 0 then 0 else ⟨a.re / n, -a.im / n⟩

instance : Div CRat := ⟨fun a b => a * inv b⟩

/-- ACL2 `realpart`. -/
def realpart (a : CRat) : Rat := a.re

/-- ACL2 `imagpart`. -/
def imagpart (a : CRat) : Rat := a.im

/-- ACL2 `<` on complex rationals, from `completion-of-<` in axioms.lisp. -/
def lt (x y : CRat) : Prop := x.re < y.re ∨ (x.re = y.re ∧ x.im < y.im)

instance : LT CRat := ⟨lt⟩

instance (x y : CRat) : Decidable (x < y) :=
  inferInstanceAs (Decidable (x.re < y.re ∨ (x.re = y.re ∧ x.im < y.im)))

end CRat

/-- ACL2 `acl2-numberp` on the complex rationals: always true. -/
def acl2NumberPC (_x : CRat) : Prop := True

/-- ACL2 `complex` on rationals: `(complex x y)` is `x + y i`. -/
def complex (x y : Rat) : CRat := ⟨x, y⟩

/-- ACL2 `real/rationalp` on a complex rational: its imaginary part is 0, because
`(complex x 0)` is the rational `x`. -/
def realrationalpC (c : CRat) : Prop := c.im = 0

/-- ACL2 `fix` on complex rationals: the identity. -/
def fixC (c : CRat) : CRat := c


/-- ACL2 `<=` on complex rationals: `(not (< y x))`, the definition of `<=?` in axioms.lisp, lines 11614 to 11618. -/
def acl2le (x y : CRat) : Prop := ¬ (y < x)

/-- ACL2 `numerator` on complex rationals: `completion-of-numerator` (axioms.lisp, line 25668)
gives the numerator of a rational and 0 otherwise. A complex rational is rational when its
imaginary part is 0. -/
def numeratorC (c : CRat) : Rat := if c.im = 0 then ((c.re.num : Int) : Rat) else 0

/-- ACL2 `quotep` on a complex rational, as a hypothesis carrier. The representation of
`quotep` and `syntaxp` is deferred (EMBEDDING_DECISIONS.md, decision 25). Until it is decided,
each hypothesis is the type `PUnit`, which is always inhabited, so it imposes no condition. -/
def quotepC (_c : CRat) : Type := PUnit

/-- ACL2 `syntaxp` hypothesis, as an always-inhabited type. Deferred, as `quotepC`. -/
def syntaxpW : Type := PUnit

/-- ACL2 `integerp` on complex rationals: a real integer, that is imaginary part 0 and denominator 1. -/
def integerpC (c : CRat) : Prop := c.im = 0 ∧ c.re.den = 1

instance (c : CRat) : Decidable (realrationalpC c) :=
  inferInstanceAs (Decidable (c.im = 0))

/-- ACL2 `ifix` on rationals: `(if (integerp i) i 0)`. -/
def ifixR (i : Rat) : Rat := if integerp i then i else 0

/-- ACL2 `zip`: `(if (integerp x) (= x 0) t)`, as a Prop. -/
def zipR (i : Rat) : Prop := integerp i → i = 0

instance (i : Rat) : Decidable (zipR i) :=
  inferInstanceAs (Decidable (integerp i → i = 0))

/-- ACL2 `expt` with an integer exponent on complex rationals, following axioms.lisp
(`expt`, line 9073): `(cond ((zip i) 1) ((= (fix r) 0) 0) ((> i 0) (* r (expt r (+ i -1))))
(t (* (/ r) (expt r (+ i +1)))))`. -/
def exptCInt (r : CRat) (i : Int) : CRat :=
  if i = 0 then 1
  else if r = 0 then 0
  else if 0 < i then r * exptCInt r (i - 1)
  else CRat.inv r * exptCInt r (i + 1)
termination_by i.natAbs
decreasing_by all_goals omega

instance (c : CRat) : Decidable (integerpC c) :=
  inferInstanceAs (Decidable (c.im = 0 ∧ c.re.den = 1))

instance (x y : CRat) : Decidable (acl2le x y) :=
  inferInstanceAs (Decidable (¬ (y < x)))

/-- ACL2 `ifix` on complex rationals: `(if (integerp i) i 0)`. -/
def ifixC (i : CRat) : CRat := if integerpC i then i else 0

/-- ACL2 `zip` on complex rationals: `(if (integerp x) (= x 0) t)`, as a Prop. -/
def zipC (i : CRat) : Prop := integerpC i → i = 0

instance (i : CRat) : Decidable (zipC i) :=
  inferInstanceAs (Decidable (integerpC i → i = 0))

/-- ACL2 `nfix` on complex rationals: `(if (and (integerp x) (>= x 0)) x 0)`. -/
def nfixC (x : CRat) : CRat := if integerpC x ∧ acl2le 0 x then x else 0

/-- ACL2 `expt` on complex rationals. The exponent is any ACL2 number, so it ranges over `CRat`
(decision 69): the integer case, and 1 for a non-integer exponent, because `zip` holds for it. -/
def exptC (r : CRat) (i : CRat) : CRat := if integerpC i then exptCInt r i.re.num else 1

/-- ACL2 `denominator` on complex rationals: `completion-of-denominator` (axioms.lisp, line 25561). -/
def denominatorC (c : CRat) : Rat := if c.im = 0 then ((c.re.den : Int) : Rat) else 1

/-- ACL2 `nonnegative-integer-quotient`, a system function (axioms.lisp, line 6889). Its
signature only, as for book functions (decision 41). -/
opaque «nonnegative-integer-quotient» : CRat → CRat → CRat

/-! ## Association lists

An ACL2 alist is a list of pairs, with the key as the first component and the value as the
second (EMBEDDING_DECISIONS.md, decision 49). The ACL2 predicate `alistp` (axioms.lisp, line 2515)
holds of a list whose elements are all conses, and every element of a typed list of pairs is a
pair. -/

/-- An ACL2 alist: a list of pairs `(key, value)`. -/
abbrev AList (α β : Type) := List (α × β)

/-- ACL2 `alistp` on an alist. Every element of an `AList` is a pair, so the predicate holds. -/
def alistp {α β : Type} (_l : AList α β) : Prop := True

/-- ACL2 `assoc-equal`: the first pair of the alist whose key is `key`, and `none` (`nil`)
when no key matches. Duplicate keys are allowed, and the first match is returned. -/
def assocEqual {α β : Type} [DecidableEq α] (key : α) : AList α β → Option (α × β)
  | [] => none
  | p :: rest => if p.1 = key then some p else assocEqual key rest

/-- An ACL2 symbol, represented by its `symbol-name` (axioms.lisp, line 5696). The package is
not represented. -/
structure ACLSymbol where
  name : String
  deriving DecidableEq

/-- ACL2 `member-symbol-name` (axioms.lisp, line 5717): the tail of the list from the first symbol
whose name is `str`, and `nil`, the empty list, when there is none. -/
def memberSymbolName (str : String) : List ACLSymbol → List ACLSymbol
  | [] => []
  | x :: xs => if str = x.name then x :: xs else memberSymbolName str xs

/-- ACL2 `true-listp`. Every Lean list is a true list, so the predicate is `True`. -/
def trueListp {α : Type} (_l : List α) : Prop := True

/-- ACL2 `arglistp` (basis-a.lisp, line 856): a predicate on lists of symbols. It is defined in the
ACL2 system, not in a book, and its signature is opaque (decision 50). -/
opaque arglistp : List ACLSymbol → Prop

/-- ACL2 `stringp`. The string variables range over `String`, so every value is a string
(decision 50). -/
abbrev stringp (_s : String) : Prop := True

instance (s : String) : Decidable (stringp s) := isTrue trivial

/-- ACL2 `length` on a string: the number of characters, as a rational. -/
def length (s : String) : Rat := (s.length : Rat)

/-- ACL2 `char`: the character at index `(nfix n)`, or `none` (`nil`) when the index is out of
range (decision 50). -/
def «char» (s : String) (n : Rat) : Option Char := s.toList[(nfix n).num.toNat]?

/-- ACL2 `characterp` on a value that may be `nil`, represented as `Option Char`: true exactly for
a character, that is `some`. -/
def characterp (x : Option Char) : Prop := x.isSome = true

instance (x : Option Char) : Decidable (characterp x) :=
  inferInstanceAs (Decidable (x.isSome = true))

/-- ACL2 `code-char` on the rationals: the character with code `n`. Total in this embedding, so
for a code outside the range of ACL2 characters it differs from ACL2 (decision 50). -/
def «code-char» (n : Rat) : Char := Char.ofNat n.num.toNat

/-- ACL2 `char-code` on characters: the integer code of `c`. -/
def «char-code» (c : Char) : Rat := ((c.toNat : Int) : Rat)

/-- The ACL2 world, as an opaque type. -/
opaque World : Type

/-- The ACL2 system function `getprops`, an opaque signature (decision 41). Its result is an
alist from symbols to values. -/
opaque «getprops» : {β : Type} → ACLSymbol → ACLSymbol → World → AList ACLSymbol β

/-! ## Primitives moved from the batch modules (decision 52)

Each declaration below was declared in a module of the batch, and moves here so that all modules
share one definition. -/

/-- ACL2 `natp` on the rationals: `(and (integerp x) (>= x 0))`. -/
def natp (x : Rat) : Prop := integerp x ∧ 0 ≤ x

/-- ACL2 `realfix` on the rationals: `(if (real/rationalp x) x 0)`. Every rational is a real rational,
so the value is `x`. -/
def realfix (x : Rat) : Rat := x

/-- ACL2 `rfix`: `(if (rationalp x) x 0)`. On `Rat`, `rationalp` is `True`, so `rfix` is the identity. -/
def rfix (x : Rat) : Rat := x

/-- ACL2 `string-listp` on lists of strings: every Lean `String` is a string, so the predicate is `True`. -/
def stringListp (_l : List String) : Prop := True

/-- ACL2 `add-to-set-equal` (axioms.lisp, line 6595): `(cond ((member-equal x l) l) (t (cons x l)))`. -/
def addToSetEqual {α : Type} [DecidableEq α] (x : α) (l : List α) : List α :=
  if x ∈ l then l else x :: l

/-- ACL2 `consp`, on the symbols only: a symbol is not a cons, so the predicate is false. -/
def consp (_ : ACLSymbol) : Prop := False

/-- ACL2 `function-symbolp` (axioms.lisp, line 11500). Opaque signature (decision 41). -/
opaque «function-symbolp» : ACLSymbol → World → Prop

/-- ACL2 `arity` (basis-b.lisp, line 2255), an integer or `nil`. Opaque signature (decision 41). -/
opaque arity : ACLSymbol → World → Option Rat

/-- ACL2 `symbolp` on the `ACLSymbol` values, which are all symbols, so the predicate is `True`
(deviation D3, decision 52). -/
abbrev symbolp (_s : ACLSymbol) : Prop := True

/-- ACL2 `primitivep` (std/system/primitivep.lisp, line 18), a `define` whose body uses the system
constant `*primitive-formals-and-guards*`. Opaque signature (decision 41). -/
opaque «primitivep» : ACLSymbol → Prop


/-! ## Declarations merged from the pending batch modules (decision 53) -/

/-- ACL2 `booleanp` on truth values, which are `Prop` in the shallow embedding. Every `Prop` is a
truth value of the embedding, so the predicate is `True` (deviation D4, decision 53). -/
def booleanp (_x : Prop) : Prop := True

/-- ACL2 `symbol-name-lst`, a system function (boot-strap-pass-2-a.lisp, line 96). Opaque signature
(decision 41). -/
opaque symbolNameLst : List ACLSymbol → List String

/-- ACL2 `len` (axioms.lisp, line 2321): the number of elements of a list, as a rational. -/
def len {α : Type} (l : List α) : Rat := (l.length : Rat)

/-- ACL2 `union-equal` (axioms.lisp, line 7476). -/
def unionEqual {α : Type} [DecidableEq α] : List α → List α → List α
  | [], l2 => l2
  | x :: xs, l2 => if x ∈ l2 then unionEqual xs l2 else x :: unionEqual xs l2

/-- ACL2 `integer-range-p` (axioms.lisp, line 16670): `(and (integerp x) (<= lower x) (< x upper))`. -/
def «integer-range-p» (lower upper x : Rat) : Prop := integerp x ∧ lower ≤ x ∧ x < upper

/-- ACL2 `digit-to-char` (axioms.lisp, line 7364): the character for an integer `n` from 1 to 15, and
`#\0` otherwise, including `n = 0` and non-integers. -/
def «digit-to-char» (n : Rat) : Char :=
  if integerp n then
    match n.num with
    | 1 => '1' | 2 => '2' | 3 => '3' | 4 => '4' | 5 => '5' | 6 => '6' | 7 => '7' | 8 => '8'
    | 9 => '9' | 10 => 'A' | 11 => 'B' | 12 => 'C' | 13 => 'D' | 14 => 'E' | 15 => 'F'
    | _ => '0'
  else '0'

/-- ACL2 `sumlist` (arithmetic/sumlist.lisp, line 15). Opaque signature, because it is a defun of a
book (decision 41). -/
opaque «sumlist» : List Rat → Rat

/-- ACL2 `test-2` (misc/character-encoding-test.lisp, line 35), `(defun test-2 () "ó")`. Opaque
signature (decision 41). The value depends on the file encoding, which this embedding does not
represent (decision 53). -/
opaque «test-2» : String

/-- Nonemptiness of the ACL2 world. Lean's `opaque` needs an inhabitant of the codomain, and this
`Prop` axiom supplies it. It asserts only that the type is nonempty, which is consistent. -/
axiom worldNonempty : Nonempty World
instance : Nonempty World := worldNonempty

/-- The ACL2 state object, as an opaque type (decision 53). -/
opaque State : Type
axiom stateNonempty : Nonempty State
instance : Nonempty State := stateNonempty

/-- The value of `open-input-channels`, as an opaque type (decision 53). -/
opaque InputChannels : Type
axiom inputChannelsNonempty : Nonempty InputChannels
instance : Nonempty InputChannels := inputChannelsNonempty

/-- ACL2 `open-input-channels` (axioms.lisp, line 14205). Opaque signature (decision 41). -/
noncomputable opaque «open-input-channels» : State → InputChannels

/-- ACL2 `w` (axioms.lisp, line 18875), the world of a state. Opaque signature (decision 41). -/
noncomputable opaque «w» : State → World

/-- ACL2 `state-p1` (axioms.lisp, line 15604). Opaque signature (decision 41). -/
opaque «state-p1» : State → Prop

/-- ACL2 `update-acl2-oracle` (axioms.lisp, line 14241): the state whose oracle is `x`. Opaque
signature (decision 41). The oracle ranges over `List α` (deviation, decision 53). -/
noncomputable opaque «update-acl2-oracle» : {α : Type} → List α → State → State

end

end ACL2
