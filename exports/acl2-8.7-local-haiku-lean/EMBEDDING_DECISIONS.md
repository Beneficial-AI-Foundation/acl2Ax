# EMBEDDING_DECISIONS

This file records every deviation from the ACL2 source in the Lean axioms.

## General decisions

1. The embedding is shallow. Each ACL2 theorem or lemma becomes a Lean proposition over Lean types, not over a deep syntax of ACL2 terms.
2. Every ACL2 number is a `Rat`. Integer arguments are tested with `integerp`, which is `den = 1`.
3. ACL2 truth values become Lean `Prop`. The connectives `implies`, `and`, `or`, `not` and `equal` become the corresponding Lean connectives.
4. ACL2 primitives and definitions used in the books are interpreted by Lean functions, listed in the interpretation table. A definition of a book is a Lean `def` with the ACL2 name in guillemets.
5. Quantified variables range over `Rat` or `List Rat`, not over all ACL2 objects. A theorem with no hypothesis therefore holds in Lean only for rational arguments.
6. Support definitions live in `Lean/ACL2/Base.lean`, outside the mirror of the books directory tree.
7. Hyphens in ACL2 names are kept with Lean guillemets, for example `«abs-*»`.
8. Each ACL2 theorem is an `axiom`. The `:rule-classes`, hints and proofs are not represented.
9. A module does not import the modules of a `local` `include-book`. Non-local includes are imported when their module exists.
10. A recursive ACL2 definition is a Lean `def` on `Rat`, with `termination_by` on a natural measure. An integer argument is a `Rat` that satisfies `integerp`, and the measure is taken from its numerator, so no `Int` helper is used.
11. Local theorems and lemmas are axioms too.
14. ACL2 complex rationals are the Lean type `CRat`, pairs of `Rat` with the field operations. A real `Rat` embeds in `CRat` with imaginary part 0. Theorems over the reals keep `Rat`, and theorems over numbers that may be complex use `CRat`.
15. The order `<` on `CRat` is the lexicographic order of `completion-of-<` (axioms.lisp, lines 25364 to 25374): `x < y` holds when `realpart x < realpart y`, or when the real parts are equal and `imagpart x < imagpart y`. On real arguments it coincides with the order on `Rat`.
16. No Mathlib dependency is used. The `CRat` type is defined in core Lean, so the shallow embedding needs no `require`.
17. Unconstrained ACL2 variables of the cancel-terms-helper book range over `CRat`. A variable under `real/rationalp` ranges over `Rat`, and is coerced to `CRat` with `↑` when used with complex values.
18. `real/rationalp` of a complex rational is true exactly when its imaginary part is 0, because `(complex x 0)` is the rational `x`.
19. A `cond` with no true clause returns `False`, as ACL2 returns `nil`.
20. `helper-9` in the `#| |#` block at the end of cancel-terms-helper.lisp is a comment, and no axiom is written for it.
21. ACL2 `<=` on complex rationals is `(not (< y x))`, the definition of `<=?` in axioms.lisp (lines 11614 to 11618). It is the Lean predicate `acl2le`. On real arguments it coincides with `≤` on `Rat`.
22. A variable name that contains `+`, such as `y+`, is not a Lean identifier. It is renamed `yp` in the module. The renaming does not change the statement.
23. Theorems of non-linear.lisp that state the property for real variables use `Rat`, and those that state it for numbers that may be complex use `CRat`.
24. `encapsulate` is transparent. The theorems inside it are axioms of the module, and the local ones are included (decision 11). The statements of basic-arithmetic-helper.lisp range over `CRat`, because ACL2 numbers there include complex values, and `(/ x)` is `CRat.inv x`.
25. `quotep` and `syntaxp` hypotheses are represented as always-inhabited types, `quotepC x : Type := PUnit` and `syntaxpW : Type := PUnit`. A hypothesis of this type imposes no condition, so an axiom with such a hypothesis is stated without a condition. The representation of `quotep` and `syntaxp` is DEFERRED: the user will decide how to represent them properly, for example in the deep embedding. Until then this is a deviation, because the ACL2 statements are conditional on properties of all objects.
26. `numerator` on a complex rational is `numeratorC`. It is the numerator of the real part when the imaginary part is 0, and 0 otherwise, as `completion-of-numerator` (axioms.lisp, line 25668) states.
27. `syntaxp` hypotheses are kept as `syntaxpW` (decision 25). `(syntaxp form)` expands to `(and form t)` (axioms.lisp, line 4558). The representation is deferred with decision 25.
28. The macro `fc` in expt.lisp (line 15) is the identity, `(defmacro fc (x) x)`. Each `(fc e)` is written as `e`.
29. `expt` on complex rationals is `exptC r i`, with a rational exponent. It follows `expt` in axioms.lisp (line 9073): `exptCInt` for an integer exponent, and 1 for a non-integer exponent. The helpers `zipR`, `ifixR` and `integerpC` follow `zip`, `ifix` and `integerp` on complex values. `expt` on rationals keeps its earlier definition in `Base.lean`.
30. Visibility follows ACL2. Each module uses the Lean module system. A non-local `include-book` is a `public import`, so its exported names reach the importers, as in ACL2. A `local` `include-book` is a plain `import`, which the module can use in its own declarations but does not re-export. An exported axiom is `public axiom`. A local axiom is `private axiom`, which is usable in the module and invisible to importers. `ACL2.Base` is a `public import`, and its declarations are public. Local includes are imported only when their module exists. Until then the module records them as pending in a comment. Tests with a scratch project confirmed each of these visibility rules.
31. The modules cancel-terms-helper, non-linear, basic-arithmetic-helper, basic-arithmetic and expt were generated before decision 30. Their local includes are pending (the comment at the top of each module lists them). Their local imports must be added once those modules exist. The order file ORDER.txt now includes local edges, so these books come after their local dependencies.
32. Each book's declarations live in the namespace `ACL2.<book path>`, for example `ACL2.«arithmetic-2».pass1.«basic-arithmetic»`. A local include can bring in public names that share an ACL2 name with the book's own axioms (for example `equal-/` in basic-arithmetic-helper and basic-arithmetic). The book namespace keeps the two apart, as the book namespaces of ACL2 do. The shared `Base.lean` stays in namespace `ACL2`.
33. The local includes that exist are now imported: basic-arithmetic imports basic-arithmetic-helper, non-linear imports cancel-terms-helper, and expt imports basic-arithmetic. Pending local includes remain: ../pass1/top for cancel-terms-helper and non-linear, and inequalities, prefer-times and expt-helper for expt. Decision 31 still lists the modules generated before decision 30.
34. inequalities.lisp is generated after basic-arithmetic, which it includes locally. Its local include is imported. Its `iff-equal` is a local theorem and is `private`. The `fc` macro is inlined (decision 28). All variables are real, so they range over `Rat`.
35. Every module depends only on modules that exist. `scripts/check_deps.py` checks this: each include of the book must be an imported module, and each module must exist. A module with a missing dependency is moved to `staged/`, outside `Lean/`, and its manifest status says what it waits for. Staged modules are regenerated once their dependencies exist. Currently staged: cancel-terms-helper and non-linear (waiting for arithmetic-2/pass1/top), and expt (waiting for expt-helper and prefer-times). The import of inequalities was added to expt.
36. prefer-times.lisp is generated after basic-arithmetic and inequalities, which it includes locally, and both are imported. The equalities over all numbers use `CRat` and `CRat.inv`, and the `<` normalizations over reals use `Rat` and `⁻¹`. Its local theorems iff-equal, times-one and times-minus-one are `private`.
37. The local defun `Math-induction-start-at-k` (expt-helper.lisp, line 22) is an induction scheme used only in hints. It is not a theorem, and no statement uses it, so it is not generated. The local theorem `justify-induction` is `private`.
38. expt.lisp is restored from `staged/` once its local dependencies exist: expt-helper and prefer-times are generated. Its imports are basic-arithmetic, inequalities, prefer-times and expt-helper, all plain imports.
39. mini-theories.lisp: its rule-set forms are not generated (decision 40). Its local lemma `Uniqueness-of-*-inverses-lemma-2` is `private`. Its local includes basic-arithmetic, inequalities, prefer-times and expt are imported.
41. A function defined by a book (`defun`) is an opaque constant with its type signature and no body, for example `opaque nonneg-int-gcd : Rat → Rat → Rat`. The axioms about it are stated, not proved. Its name and namespace follow the same rules as the axioms (decisions 30 and 32), and its uses in statements refer to the constant. Functions of `Lean/ACL2/Base.lean` keep their interpretations, because they give the ACL2 primitives their meaning. Decision 37 is revised: the local defun `Math-induction-start-at-k` is generated as an opaque signature, with result type `Prop`.
42. `denominator` on a complex rational is `denominatorC`: the denominator of the real part when the imaginary part is 0, and 1 otherwise (`completion-of-denominator`, axioms.lisp, line 25561). The system function `nonnegative-integer-quotient` (axioms.lisp, line 6889) is an opaque signature in `Base.lean`, as decision 41 gives for book functions.
43. numerator-and-denominator-helper.lisp: its functions `nonneg-int-mod`, `nonneg-int-gcd`, `nonneg-int-gcd-multiplier1`, `nonneg-int-gcd-multiplier2` and the local `induct-on-nonneg-int` are opaque signatures (decisions 37 and 41). It has no local includes that need a Lean import beyond basic-arithmetic, inequalities and prefer-times, which are imported as plain imports. Its statements over the integers use `Rat`, and `Nonneg-int-gcd-numerator-denominator` ranges over `CRat`, because its ACL2 statement has no integer hypothesis.
44. numerator-and-denominator.lisp: its variables range over `CRat`, with `rationalp` as `realrationalpC`, `integerp` as `integerpC`, `numerator` as `numeratorC` and `denominator` as `denominatorC` (decisions 26 and 42). The local lemmas numerator-integerp-lemma-1 and numerator-integerp-lemma are `private`. Its local includes are imported as plain imports. Base.lean gains one decidability instance, for `realrationalpC`, which the `if` in `*-r-denominator-r` needs. `integerpC` needs no instance, because it occurs only in a disjunction.
45. Decidability of the complex predicates in `if` expressions. The chosen representation is a computable instance, `Decidable (realrationalpC c)`, defined as `c.im = 0` (Base.lean). The alternative is to axiomatize decidability, either as `axiom` of type `∀ c : CRat, Decidable (realrationalpC c)` or through `Classical.propDecidable`. The two alternatives are logically equivalent to the chosen one, and they do not change any statement. They are not chosen, because they make the `if` depend on a non-computable choice, which ACL2's `real/rationalp` test does not have. The alternative is recorded for the user's decision.
46. pass1/top.lisp has no theorem outside a `#| |#` block comment. Its module imports its non-local includes as `public import`, and it has no axioms. Its statements are not generated, because the book has none.
47. cancel-terms-helper and non-linear are restored from `staged/`, now that `pass1/top` exists. Their local imports are plain imports: `pass1/top` for both, and `cancel-terms-helper` for non-linear.
48. Block comments of the ACL2 book (`#| |#`) are recorded verbatim as Lean `--` comments at the end of the module, before the namespace closes. They state no axiom. This keeps the removed material, such as the commented-out theorems of pass1/top, visible next to the module.
49. Alists. An ACL2 alist is a list of pairs, the key as the first component and the value as the second. The Lean type is `AList α β := List (α × β)` (ACL2.Base). The predicate `alistp` (axioms.lisp, line 2515) holds of every element of this type, because each element is a pair, so `alistp` is `True` on `AList`. `assoc-equal` is `assocEqual`, which returns the first pair with the given key, or `none` for `nil`. Keys and values are type parameters, not `Rat`, because ACL2 objects are untyped (a deviation from the shallow `Rat` domain, recorded here). The alist is not a `Finmap`, because `alistp` does not require unique keys. The finite-map view is the first-match lookup, and no axiom uses a `Finmap`.
50. Shared primitives of ACL2.Base, merged from the pilot fragments. There is one symbol type, `ACLSymbol`, a structure with the `symbol-name` as field `name` (axioms.lisp, lines 5615 to 5697). `memberSymbolName` is `member-symbol-name` (axioms.lisp, line 5717). `trueListp` is `True`, because every Lean list is a true list. `arglistp` is an opaque signature, because it is defined in the ACL2 system (basis-a.lisp, line 856) and not in a book. `stringp` is `True` on `String`, and `length` on a string is its character count. `char` returns `Option Char` (deviation D1: `nil` for an index out of range, so the value may be `nil`). `characterp` takes `Option Char`, true for `some` (deviation D1). `code-char` is total, `Char.ofNat`, so for a code outside the range of ACL2 characters it differs from ACL2 (deviation D2, not resolved by the user). `char-code` is the code of the character as a rational.
51. Why `characterp` takes `Option Char`. ACL2 `characterp` is a predicate on every object, and `char` returns `nil` for an index out of range. The statement `characterp-of-char`, `(characterp (char s n))` equivalent to `(stringp s ∧ nfix n < length s)`, requires `characterp` to be false on that `nil`. A `characterp` on `Char` alone has no value for `char` to return, so `Option Char` is the carrier, with `none` for `nil`. This is the consequence of deviation D1 in decision 50, and it is open for the user's decision together with D1.
52. Batch primitives merged into ACL2.Base. `natp`, `realfix`, `rfix`, `stringListp`, `addToSetEqual`, `consp`, `function-symbolp` and `arity` (opaque, basis-b.lisp line 2255), `symbolp` (abbrev, `True`, deviation D3) and `primitivep` (opaque) are declared once in Base.lean. The module files of the batch keep only their own axioms. `arity-iff` ranges over symbols, so the cons case is excluded (deviation). `rfix` and `realfix` axioms sit in their book namespaces, as decision 32 requires. The `arithmetic/real-listp` book has no axioms, because both theorems sit under `#+:non-standard-analysis` (decision 12).
53. Deviations from the untyped ACL2 domain in the batch modules. Each of the following is a recorded deviation, and each is a faithful statement over the stated type. (a) List and alist variables range over `List α` with `α` a type parameter, and `rationalListp` is `True`, so statements over `List Rat` have no content in Lean (`arithmetic/rational-listp`, `arithmetic/sumlist`). (b) `booleanp` is `True` on `Prop`, which is a larger carrier than the ACL2 truth values (D4, `equal-of-booleans`). (c) `update-acl2-oracle` takes an oracle over `List α`, and `State`, `InputChannels`, `w` and `open-input-channels` are opaque types with a `Nonempty` placeholder, because Lean's `opaque` needs an inhabitant. The placeholders are `Prop` axioms that assert nonemptiness only. (d) `test-2` is an opaque `String`, because its value depends on the file encoding, which this embedding does not represent. (e) Variables of `digit-to-char` and `zero-digit-to-char` range over `Rat`, not over every ACL2 object. (f) `unionEqual`, `symbolNameLst` and `len` are declared in `Base.lean` as the ACL2 functions on lists.
54. `car` on a nonempty list is `x.headD 0`. ACL2 `car` of `nil` is `nil`, and the hypothesis `x` (non-nil) excludes that case, so the statement is unaffected. A `car` declaration in `Base.lean` would replace the inline `headD`, and it is proposed, not added.
40. Rule-set bookkeeping forms are not generated. These are `in-theory`, `deftheory`, `theory-invariant`, and the `enable` and `disable` forms they contain. They select which rewrite rules the ACL2 prover uses, and they state no theorem about values. Each theorem they refer to is still generated as its own axiom.
12. A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.
55. arithmetic-3/bind-free/banner.lisp holds one `make-event` form, which prints an observation. It has no `include-book`, no `defun` and no theorem. Its module imports `ACL2.Base` only, and it has no axiom.
56. arithmetic-3/pass1/basic-arithmetic-helper.lisp. The book has no include-book form, so the module imports only ACL2.Base. The statements range over CRat, because the ACL2 numbers of the book include complex values, as in the arithmetic-2 template. The book has six local theorems, inside encapsulate forms, and they are private axioms. It has seven exported theorems, and they are public axioms. No form is under non-standard-analysis, and the book has no defun, defmacro or block comment. The book is a revision of arithmetic-2. Its only textual change is the hypothesis (syntaxp (not (quotep y))) of functional-commutativity-of-minus-*-right, which is the type syntaxpW (decisions 25 and 27). All other statements keep the template phrasing.
57. arithmetic-3/pass1/basic-arithmetic.lisp. The book basic-arithmetic.lisp of arithmetic-3 is a revision of the arithmetic-2 book with the same name. Its statements range over CRat, as in the arithmetic-2 template. Its only include is local, so the module imports basic-arithmetic-helper as a plain import and has no public import. No axiom sits inside a local event, so every axiom is a public axiom. The defun nonlinearp-default-hint-pass1 is a public opaque constant (decision 41). Its arguments are untyped, so the signature uses type parameters, and its result is an option of a list, because the defun returns nil or a computed hint. Two theorems, functional-commutativity-of-minus-*-right and functional-commutativity-of-minus-*-left, carry a syntaxp hypothesis in arithmetic-3 and none in arithmetic-2. Each takes the hypothesis as syntaxpW (decision 25). The :rule-classes and :hints forms are not generated. The book has 32 defthm forms and 1 defun. No form is excluded by non-standard-analysis.
58. arithmetic-3/pass1/inequalities.lisp. This book is a revision of the arithmetic-2 book inequalities. Each hypothesis `real/rationalp` of the arithmetic-2 text is `rationalp` in this text, and the module writes it as `rationalp x`. On `Rat`, `rationalp` is True in Base.lean, so these hypotheses impose no condition, and the variables range over the rationals as decision 23 states for real variables. The local theorem `iff-equal` is private. The local include of basic-arithmetic is a plain import. The local `in-arithmetic-theory` form at line 95 is a rule-set form, so it is not generated (decision 40). The macro `fc` at line 21 is the identity, so it is inlined (decision 28). The `set-default-hints` form at line 13 is not generated. The book has no defun, no block comment, no non-standard-analysis form and no non-local include, so it has no opaque constant and no excluded form. The nineteen defthm forms give nineteen axioms, one private and eighteen public.
59. arithmetic-3/pass1/prefer-times.lisp. The book has eleven `defthm` forms outside comments. Three are local (`iff-equal`, `times-one`, `times-minus-one`), so they are `private axiom`. Eight are public. The local includes basic-arithmetic and inequalities are plain imports, and the book has no non-local include. The equalities `equal-*-/-1` and `equal-*-/-2` range over `CRat`, with `fixC`, `acl2NumberPC` and `CRat.inv`. The six `normalize-<-/-to-*` axioms range over `Rat`, with `rationalp` hypotheses as the arithmetic-3 text states. The arithmetic-2 template has `realrationalp` there, and the arithmetic-3 text has `rationalp`, so the axioms follow the arithmetic-3 text. `set-default-hints`, the local `in-arithmetic-theory`, `deftheory` and `in-theory` are not generated. No `defun` and no block comment occur in the book, and no form is excluded as non-standard analysis.
60. arithmetic-3/pass1/expt-helper.lisp. The book is a revision of arithmetic-2/pass1/expt-helper, and its statements are taken from the arithmetic-3 text. The variables x and r range over CRat when unconstrained, as in expt-crock and the four exponent theorems. The variables i, j and r range over Rat when the statement constrains them to the integers or the reals, through integerp, rationalp and the order. The local includes basic-arithmetic, inequalities and prefer-times are plain imports, and the book has no non-local include. The local theorem justify-induction is private. The local defun Math-induction-start-at-k is an opaque signature with result type Prop, as decision 41 revises decision 37, and it is private because it is local. The macro fc is the identity and is inlined. The hypothesis rationalp r replaces real/rationalp r of the arithmetic-2 text in justify-induction and expt-is-increasing-for-base>1, and the Lean phrasing follows the arithmetic-3 text. The rule-classes and hints are not generated. No form is excluded.
61. arithmetic-3/pass1/expt.lisp. The book `arithmetic-3/pass1/expt` has four local includes, `basic-arithmetic`, `inequalities`, `prefer-times` and `expt-helper`, and no non-local include. Each is a plain `import`. The module has 26 axioms, 23 public and 3 private. The private axioms are `expt-minus`, `expt-minus-redux` and `stupid-hack`, which are local theorems. The macro `fc` is the identity and is inlined. The book has no `defun`, so no opaque constant is written. It has no `#+:non-standard-analysis` form and no `#| |#` block comment, so no form is excluded. The variables follow the arithmetic-2 template. A variable that may be complex ranges over `CRat`, and a variable that the statement constrains to the rationals ranges over `Rat`. The arithmetic-3 text replaces `real/rationalp` with `rationalp` in the hypotheses of several theorems. Those statements use `rationalp` on `Rat`, which `Base.lean` defines as `True`.
62. arithmetic-3/pass1/mini-theories.lisp. The book mini-theories of arithmetic-3/pass1 is a revision of arithmetic-2/pass1/mini-theories. Its ACL2 text differs from the arithmetic-2 text only in the license header line and a blank line, so the module reuses the arithmetic-2 module without change. The variables of the statements range over `CRat` where ACL2 allows complex values, and over `Rat` for the integer exponents `i` and `j`. The book has four local includes, basic-arithmetic, inequalities, prefer-times and expt, which are plain imports. The local defthm `Uniqueness-of-*-inverses-lemma-2` is a private axiom. The forms `in-theory`, `theory-invariant` and the `:hints` of `Uniqueness-of-*-inverses` are not generated (decision 40). The book has no defun, no defmacro and no excluded form.
63. Sums and products of three or more arguments. The ACL2 macros `+` (axioms.lisp, line 2308) and `*` (axioms.lisp, line 3918) expand through `xxxjoin` (axioms.lisp, line 2289) to the right-nested binary form, so `(* x y z)` is `(* x (* y z))`. The Lean operators `+` and `*` associate to the left, so each such term is written with explicit parentheses, `x * (y * z)`. The earlier axioms that wrote `x * y * z` are corrected: helper-1, helper-2, helper-5, helper-9 and helper-10 of arithmetic-2/meta/cancel-terms-helper, minus-cancellation-on-right, minus-cancellation-on-left, /-cancellation-on-right and /-cancellation-on-left of the basic-arithmetic books of arithmetic-2 and arithmetic-3, stupid-hack of the two expt books, and Linear-combination-gcd=1 of arithmetic-2/pass1/numerator-and-denominator-helper. The implication of equal-+-x-y-0 in arithmetic-2/pass1/basic-arithmetic now has its biconditional in parentheses, because `→` binds tighter than `↔` in Lean.
64. arithmetic-3/pass1/non-linear.lisp. The book `arithmetic-3/pass1/non-linear` has two local includes, `basic-arithmetic` and `expt`, and no non-local include. The module imports both as plain imports, and they are not re-exported. The book has 30 `defthm` forms, all outside `local`, so all 30 are `public axiom`, and no `private axiom` is generated. No form is under `#+:non-standard-analysis`, so no form is excluded. The book has no `defun`, no `defmacro` and no `#| |#` block comment. The `local (in-theory ...)` form, the `in-theory` forms and `in-arithmetic-theory` are rule-set bookkeeping and are not generated (general decision 40). Variables that the statement leaves unconstrained range over `CRat`, and variables under `rationalp` range over `Rat` (general decisions 14, 17 and 23). Exponents are `Rat`, as in `expt.lean` and general decision 29. The `syntaxp` hypotheses are `syntaxpW` (general decision 25). The phrasing of the `expt` statements follows `arithmetic-2/pass1/expt.lean`. The arithmetic-2 template `arithmetic-2/meta/non-linear.lean` covers the `real/rationalp` monotonicity statements, which this book does not contain.
65. arithmetic-3/pass1/top.lisp holds seven non-local `include-book` forms. It has no `defun`, no theorem and no block comment. Its module imports the seven modules as `public import`, and it has no axiom.
66. arithmetic-3/pass1/num-and-denom-helper.lisp. The book num-and-denom-helper.lisp is the revision of arithmetic-2/pass1/numerator-and-denominator-helper.lisp, and its module reuses that template. Apart from comments, the two source texts differ only by the local include of non-linear and by the non-local theorem hack (line 99). Each other statement keeps the template phrasing. Variables constrained to integers or to reals are Rat. The unconstrained variable of hack and the variable of Nonneg-int-gcd-numerator-denominator range over CRat (decision 14), because these statements have no integer or real hypothesis. The local includes basic-arithmetic, inequalities, prefer-times and non-linear are plain imports from arithmetic-3/pass1. The module has no public import beyond ACL2.Base, because the book has no non-local include. The local defun induct-on-nonneg-int is a private opaque with result type Prop (decisions 37 and 41). The defuns nonneg-int-mod, nonneg-int-gcd, nonneg-int-gcd-multiplier1 and nonneg-int-gcd-multiplier2 are public opaque signatures (decision 41). The book has no local theorem, so the module has no private axiom. The module has 39 public axioms, one for each defthm of the book. No form is excluded, because the book has no reader conditional. The hints, rule-classes and in-theory, disable and enable forms are not generated (decision 40). The block comment of the book is copied at the end of the module (decision 48).
67. arithmetic-3/pass1/numerator-and-denominator.lisp. The book arithmetic-3/pass1/numerator-and-denominator.lisp has eight theorems. Six are exported, and they are `public axiom`. Two are local to an encapsulate, `numerator-integerp-lemma-1` and `numerator-integerp-lemma`. They are `private axiom`. The statements are those of the arithmetic-2 template, because the arithmetic-3 text repeats them. Only the hints differ, and hints are not generated. The variables of the complex-valued statements range over `CRat`, as decision 44 states. The variables of `numerator-when-integerp` and `integerp==>denominator=1` range over `Rat`, as in the template. The hypothesis `integerp` restricts them to integers, and the coercion `↑` embeds them in `CRat`. The book has no non-local include, so no `public import` is written. Its five local includes are plain imports. They are basic-arithmetic, inequalities, prefer-times, non-linear and num-and-denom-helper. The include `num-and-denom-helper` is the name in the ACL2 text. The template imported `numerator-and-denominator-helper` instead. The book has no `defun`, no `defmacro`, no block comment and no form under `non-standard-analysis`. So no opaque constant is written, and no form is excluded. `numerator` is `numeratorC` (decision 26). `denominator` is `denominatorC` (decision 42). `rationalp` is `realrationalpC`, and `integerp` on `CRat` is `integerpC`. The decidability instance for `realrationalpC` is in `Base.lean` (decision 45).
68. Unconstrained variables of order statements range over `CRat`. A variable ranges over `Rat` only when a `rationalp`, `real/rationalp` or `integerp` hypothesis of the ACL2 statement constrains it (decisions 14 and 17). The following axioms had `Rat` variables with no such hypothesis, and they now range over `CRat`, with the statement unchanged: rewrite-linear-equalities-to-iff of the two mini-theories books, the local iff-equal of the inequalities and prefer-times books, and <-0-minus, <-minus-zero, <-minus-minus, <-0-+-negative-1, <-0-+-negative-2, <-+-negative-0-1 and <-+-negative-0-2 of the inequalities books, in arithmetic-2 and arithmetic-3. This revises the sentence of decision 34 that says all variables of inequalities.lisp are real. Two groups of `Rat` variables without such a hypothesis remain, and they are open for the user's decision. The exponent of `expt` is a `Rat` in every statement, because `exptC` takes a rational exponent (decision 29). The arguments of `nonneg-int-mod`, `nonneg-int-gcd`, `nonneg-int-gcd-multiplier1` and `nonneg-int-gcd-multiplier2` are `Rat`, because their opaque signatures are over `Rat` (decision 43).
69. The exponent of `expt` ranges over `CRat`. The ACL2 definition of `expt` (axioms.lisp, line 9073) takes any object as exponent, and `zip` makes a non-integer exponent give 1. `exptC r i` now takes `i : CRat`, with `integerpC i` as the test, and it revises decision 29. The helpers `ifixC`, `zipC` and `nfixC` follow `ifix`, `zip` and `nfix` on complex values, and `Base.lean` gains decidability instances for `integerpC` and `acl2le`. An exponent variable with no `integerp` hypothesis in the ACL2 statement is a `CRat` variable. An exponent variable under an `integerp` hypothesis stays a `Rat` variable, and Lean coerces it to `CRat` at the application (decision 17). The retyped axioms are in the expt books of arithmetic-2 and arithmetic-3 and in arithmetic-3/pass1/non-linear. The hypothesis `(<= 0 i)` of expt-type-prescription-integerp is `acl2le 0 i`.
70. The functions `nonneg-int-mod`, `nonneg-int-gcd`, `nonneg-int-gcd-multiplier1` and `nonneg-int-gcd-multiplier2`, and the system function `nonnegative-integer-quotient`, are opaque constants of type `CRat → CRat → CRat`. This revises decisions 42 and 43. A variable with no `integerp` hypothesis in the ACL2 statement is a `CRat` variable, its `integerp` test inside a disjunction is `integerpC`, its `nfix` is `nfixC`, and `<=` on it is `acl2le`. A variable under an `integerp` hypothesis stays a `Rat` variable, coerced to `CRat` at the application (decision 17). The local induction schemes `induct-on-nonneg-int` and `Math-induction-start-at-k` take `CRat` arguments. `Base.lean` gains an `Inhabited CRat` instance, which Lean's `opaque` needs for these signatures. Decision 68 no longer lists open groups.

## Excluded books: metaprogramming

Interpretation rows: `std/system/dumb-negate-lit` and `std/system/implicate` are excluded as metaprogramming, with status `excluded: metaprogramming` in `manifest.json`. Both books state properties of ACL2 terms as data (`pseudo-termp`, `dumb-negate-lit`, `implicate`). No module is written.

`arithmetic-3/bind-free/building-blocks`, `arithmetic-3/bind-free/default-hint` and `arithmetic-3/bind-free/remove-weak-inequalities` are excluded as metaprogramming, with status `excluded: metaprogramming` in `manifest.json`. The functions of building-blocks take ACL2 terms as data, or the metafunction context `mfc` with `state`. The function `nonlinearp-default-hint` of default-hint is a computed hint over the prover history `hist` and the prover variable `pspv`. The functions of remove-weak-inequalities take ACL2 terms, the goal clause and `mfc` as data. Each of the three modules is a stub that declares no axiom. The two theorems of remove-weak-inequalities, `remove-weak-inequalities-one` and `remove-weak-inequalities-two`, state `(<= x y)` implies `(<= x y)` and `(< x y)` implies `(< x y)` under two `syntaxp` hypotheses that call these functions. The exclusion of these two theorems follows the Scope rule of SKILL.md, and it is open for the user's decision, because decisions 25 and 27 give a representation of `syntaxp` hypotheses.

## Interpretation table

| ACL2 | Lean (`ACL2` namespace) |
| `CRat` (ACL2 complex rational) | structure `CRat` with `re`, `im : Rat`, field operations, `Coe` from `Rat` |
| `realpart`, `imagpart` | `CRat.realpart`, `CRat.imagpart` |
| `<` on complex arguments | `CRat.lt`: lexicographic on `(realpart, imagpart)`, from `completion-of-<` (axioms.lisp 25364 to 25374) |
| `acl2-numberp` on `CRat` | `acl2NumberPC`, constant `True` |
| `/` on `CRat` | `CRat.inv` and `Div`, `0` for a zero argument, as `(/ 0)` in ACL2 |
| `complex` | `complex x y`, the value `⟨x, y⟩` of `CRat` |
| `real/rationalp` on `CRat` | `realrationalpC c`, `c.im = 0` |
| `fix` on `CRat` | `fixC`, identity |
| `cond` without a true clause | `False` |
| `<=` on `CRat` | `acl2le x y`, `¬ (y < x)` |
| `quotep` on `CRat` | `quotepC`, always-inhabited `Type` (decision 25, deferred) |
| `syntaxp` | `syntaxpW`, always-inhabited `Type` (decision 25, deferred) |
| `numerator` on `CRat` | `numeratorC` (decision 26) |
| `expt` on `CRat` | `exptC r i`, `exptCInt` for an integer exponent, else `1` (decision 29) |
| `fc` | identity, inlined (decision 28) |
| `zip`, `ifix`, `integerp` on `CRat` | `zipR`, `ifixR`, `integerpC` (decision 29) |
| `zip`, `ifix`, `nfix` on a `CRat` argument | `zipC`, `ifixC`, `nfixC` (decision 69) |
| `expt` with any exponent | `exptC r i` with `i : CRat` (decision 69) |
| `nonneg-int-mod`, `nonneg-int-gcd`, the two multipliers, `nonnegative-integer-quotient` | opaque `CRat → CRat → CRat` (decision 70) |
| `alistp` on an alist | `alistp`, constant `True` on `AList` (decision 49) |
| `assoc-equal` | `assocEqual`, first match, `none` for `nil` (decision 49) |
| `getprops` | opaque `«getprops»` over `ACLSymbol`, `World`, result `AList ACLSymbol β` (decision 41) |
| --- | --- |

## Element decisions

### hack0

1. The local theorem uses `complex` and `real/rationalp` over real variables, and `*` of a real and a complex value.

### hack1

1. The local theorem states `real/rationalp (complex x y)` as the Prop `realrationalpC`, equivalent to `y = 0`.

### step-one

1. The local theorem compares complex values with `<` (`completion-of-<`). `cond` with no true clause is `False` (decision 19).

### helper-0

1. Unconstrained variables are `CRat` (decision 17). `fix` is `fixC`.

### helper-1

1. Unconstrained variables are `CRat`. `fix` is `fixC`.

### helper-2

1. Unconstrained variables are `CRat`.

### helper-3

1. Unconstrained variables are `CRat`.

### helper-4

1. Unconstrained variables are `CRat`. `fix` is `fixC`.

### helper-5

1. Unconstrained variables are `CRat`.

### helper-6

1. `x` is real, so it is `Rat`. `a` and `b` are `CRat`. The conditional compares reals with `0 < x`.

### helper-6a

1. Same as helper-6, with the real factor on the left.

### helper-7

1. `x` is `Rat`. `a`, `b` and `c` are `CRat`.

### helper-8

1. `x` is `Rat`. `a`, `b` and `c` are `CRat`.

### helper-9

1. `x` is `Rat`. `a`, `b` and `c` are `CRat`. The block-comment version of helper-9 is not generated (decision 20).

### helper-10

1. `x` is `Rat`. `a`, `b` and `c` are `CRat`.

### helper-11

1. `x` is real (`Rat`) and `y` is `CRat`. The `cond` has no else clause, and its missing case is `False` (decision 19).

### helper-12

1. `y` is real (`Rat`) and `x` is `CRat`. The `cond` has no else clause, so its missing case is `False` (decision 19).

### helper-13

1. `x` is real (`Rat`) and `y` is `CRat`. The `cond` has no else clause, so its missing case is `False` (decision 19).

### helper-14

1. `y` is real (`Rat`) and `x` is `CRat`. The `cond` has no else clause, so its missing case is `False` (decision 19).

### *-preserves-<=-1

1. Local. Real variables, `Rat`. The `realrationalp` hypotheses are `True`.

### *-preserves-<=-2

1. Local. Real variables, `Rat`.

### *-preserves-<-1

1. Local. Real variables, `Rat`.

### *-preserves-<-2

1. Local. Real variables, `Rat`.

### *-preserves-<=-for-nonnegatives

1. Real variables, `Rat`.

### *-preserves-<-for-nonnegatives

1. Real variables, `Rat`. The `:hints` are dropped.

### *-preserves-<-for-nonnegatives-stronger-1

1. Real variables, `Rat`.

### *-preserves-<-for-nonnegatives-stronger-2

1. Real variables, `Rat`.

### *-weakly-monotonic

1. `y` and `y+` (named `yp`) range over `CRat`, because the ACL2 statement holds for complex values (the `#| |#` counterexample is a comment). `x` is real, `Rat`. `<=` is `acl2le`. The name `y+` is `yp` (decision 22).

### *-strongly-monotonic

1. `y` and `yp` range over `CRat`. `x` is real, `Rat`. The name `y+` is `yp` (decision 22).

### *-weakly-monotonic-negative-multiplier

1. `y` and `yp` range over `CRat`. `x` is real, `Rat`. `<=` is `acl2le`. The name `y+` is `yp` (decision 22).

### *-strongly-monotonic-negative-multiplier

1. `y` and `yp` range over `CRat`. `x` is real, `Rat`. The name `y+` is `yp` (decision 22).

### /-weakly-monotonic

1. Real variables, `Rat`. `(/ y)` is `y⁻¹`.

### /-strongly-monotonic

1. Real variables, `Rat`. `(/ y)` is `y⁻¹`.

### x*y>1-positive

1. Real variables, `Rat`.

### x*y>1-positive-stronger

1. Real variables, `Rat`. The disjunction is kept.

### x*y>=1-positive

1. Real variables, `Rat`.

### x*y>1-negative

1. Real variables, `Rat`. `:hints` dropped.

### x*y>=1-negative

1. Real variables, `Rat`. `:hints` dropped.

### ratio-theory-of-1-a

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-b

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-c

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-d

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-e

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-f

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-g

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-h

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-i

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-j

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-k

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-l

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-m

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-n

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-o

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### ratio-theory-of-1-p

1. Real variables, `Rat`. `(/ x y)` is `x / y`, the ACL2 `/` of `Rat`.

### commutativity-2-of-*-lemma

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### commutativity-2-of-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### equiv-1-implies-equiv-*

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### right-cancellation-for-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### uniqueness-of-*-inverses-lemma

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### equal-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### functional-self-inversion-of-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### distributivity-of-/-over-*-lemma

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### distributivity-of-/-over-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### uniqueness-of-+-inverses-lemma

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### functional-commutativity-of-minus-*-right

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### equal-/-/-lemma

1. Local. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### equal-/-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, and `fix` is `fixC`. Hypotheses on numbers are `acl2NumberPC`, which is `True`.

### commutativity-2-of-+

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### functional-self-inversion-of-minus

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### distributivity-of-minus-over-+

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### minus-cancellation-on-right

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### minus-cancellation-on-left

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### right-cancellation-for-+

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### left-cancellation-for-+

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-minus-0

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-+-x-y-0

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. The `syntaxp` hypothesis is `syntaxpW`, always-inhabited (decision 25, deferred).

### equal-+-x-y-x

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-+-x-y-y

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-minus-minus

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### fold-consts-in-+

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. The `quotep` hypotheses are `quotepC`, always-inhabited (decision 25, deferred).

### commutativity-2-of-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### functional-self-inversion-of-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### distributivity-of-/-over-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### /-cancellation-on-right

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### /-cancellation-on-left

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### right-cancellation-for-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### left-cancellation-for-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-/-0

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-*-x-y-0

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-*-x-y-x

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-*-y-x-x

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### equal-/-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. The name also occurs in basic-arithmetic-helper.lean. The two modules are not imported into each other, so the names do not clash in Lean.

### fold-consts-in-*

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. The `quotep` hypotheses are `quotepC`, always-inhabited (decision 25, deferred).

### equal-/

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### numerator-nonzero-forward

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. `numerator` is `numeratorC` (decision 26).

### times-zero

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### functional-commutativity-of-minus-*-right

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### functional-commutativity-of-minus-*-left

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### reciprocal-minus-a

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`.

### expt-type-prescription-rationalp

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).
2. The `#+:non-standard-analysis` variant `expt-type-prescription-realp` is omitted (decision 12).

### expt-type-prescription-realp

1. Excluded: a `#+:non-standard-analysis` form, absent from standard ACL2 (decision 12).

### expt-type-prescription-positive-1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-type-prescription-positive-2

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-type-prescription-nonzero

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-type-prescription-integerp

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### equal-expt-0

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-0

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-minus

1. Local. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### exponents-add-1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### exponents-add-for-nonpos-exponents

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### exponents-add-for-nonneg-exponents

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### exponents-add-2

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### distributivity-of-expt-over-*

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### functional-commutativity-of-expt-/-base

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### Exponents-multiply

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-is-increasing-for-base>1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### Expt-is-decreasing-for-pos-base<1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### Expt-is-weakly-increasing-for-base>1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### Expt-is-weakly-decreasing-for-pos-base<1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### stupid-hack

1. Local. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt->-1-1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt->-1-2

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-<-1-1

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### expt-<-1-2

1. Statement over `CRat` with the rational exponent `i`. `expt` is `exptC` (decision 29). `fc` is inlined (decision 28).

### iff-equal

1. Local, `private`. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### /-preserves-positive

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### /-preserves-negative

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-0-minus

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-minus-zero

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-minus-minus

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-0-+-negative-1

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-0-+-negative-2

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-+-negative-0-1

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-+-negative-0-2

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-*-0

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### 0-<-*

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-*-right-cancel

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-*-left-cancel

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-*-x-y-y

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-*-y-x-y

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-y-*-x-y

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### <-y-*-y-x

1. Statement over `Rat`. `(fc e)` is inlined (decision 28). `cond` without a true clause is `False` (decision 19).

### iff-equal

1. Local, `private`. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### equal-*-/-1

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. `cond` without a true clause is `False` (decision 19).

### equal-*-/-2

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. `cond` without a true clause is `False` (decision 19).

### times-one

1. Local, `private`. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. `cond` without a true clause is `False` (decision 19).

### times-minus-one

1. Local, `private`. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-1

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-2

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-3-1

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-3-2

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-3-3

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### normalize-<-/-to-*-3-4

1. Statement over `Rat`. `(/ y)` is `y⁻¹`. `cond` without a true clause is `False` (decision 19).

### justify-induction

1. Local, `private`. Statement over `Rat` with the rational exponent. `expt` is `exptC` (decision 29).

### expt-is-increasing-for-base>1

1. Statement over `Rat` with the rational exponent. `expt` is `exptC` (decision 29).

### exponents-add-for-nonpos-exponents

1. Statement over `CRat` with the rational exponent. `expt` is `exptC` (decision 29).

### exponents-add-for-nonneg-exponents

1. Statement over `CRat` with the rational exponent. `expt` is `exptC` (decision 29).

### exponents-add-2

1. Statement over `CRat` with the rational exponent. `expt` is `exptC` (decision 29).

### exponents-add-1

1. Statement over `CRat` with the rational exponent. `expt` is `exptC` (decision 29).

### rewrite-linear-equalities-to-iff

1. Statement over `Rat`. The `in-theory` forms are not generated (decision 39).

### Uniqueness-of-*-inverses-lemma-2

1. Local, `private`. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`, `expt` is `exptC` (decision 29). The `in-theory` forms are not generated (decision 39).

### Uniqueness-of-*-inverses

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`, `expt` is `exptC` (decision 29). The `in-theory` forms are not generated (decision 39).

### expts-add-aggressive

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`, `expt` is `exptC` (decision 29). The `in-theory` forms are not generated (decision 39).

### expts-add-inverse

1. Statement over `CRat`. `(/ x)` is `CRat.inv x`, `fix` is `fixC`, `expt` is `exptC` (decision 29). The `in-theory` forms are not generated (decision 39).

### Nonneg-int-mod-<-divisor

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-nonnegative-integer-quotient

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-0

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-+-*

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-+-*-nonneg-int-mod

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-+-*-nonneg-int-mod-1

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Divisor-nonnegative-integer-quotient

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Left-nonneg-int-mod-*

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Right-nonneg-int-mod-*

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-*-0

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-Int-mod-+-0

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-Int-mod-minus-0

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Linear-combination-nonneg-int-mod

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Divisor-<=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-1

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd->-0

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-is-COMMON-divisor

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Linear-combination-for-nonneg-int-gcd

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-is-LARGEST-common-divisor-mod

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-is-LARGEST-common-divisor-<=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonnegative-integer-quotient-gcd

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Linear-combination-gcd=1

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Divisor-of-product-divides-factor

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-abs-+-*

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-abs->=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-mod-abs

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-abs-<=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-abs

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Commutativity-of-nonneg-int-gcd

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Cross-product-factor

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-1-right

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-1-left

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Nonneg-int-gcd-numerator-denominator

1. Statement over `CRat` (decision 43). Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Lowest-terms-nonneg-int-mod

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Lowest-terms-<=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### LEAST-numerator-denominator-nonneg-int-mod

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### LEAST-numerator-denominator-<=

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### Unique-rationalp

1. Statement over `Rat`. Uses opaque functions `nonneg-int-mod`, `nonneg-int-gcd` and their multipliers (decision 43) and `nonnegative-integer-quotient` (decision 42), as signatures only.

### numerator-minus

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### denominator-minus

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### numerator-integerp-lemma-1

1. Local, `private`. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### numerator-integerp-lemma

1. Local, `private`. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### numerator-when-integerp

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### integerp==>denominator=1

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### equal-denominator-1

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### *-r-denominator-r

1. Statement over `CRat` (decision 44). `numerator`, `denominator`, `rationalp` and `integerp` are the complex versions.

### pseudo-termp-of-dumb-negate-lit

Excluded: metaprogramming. The statement quantifies over ACL2 terms (`pseudo-termp`, `dumb-negate-lit`), which neither the shallow nor the current deep embedding represents.

### pseudo-termp-of-implicate

Excluded: metaprogramming. The statement concerns `pseudo-termp` and `implicate` on ACL2 terms (`pseudo-termp` in axioms.lisp, line 8333; `implicate` in tau.lisp, line 227). Open question for the user: a deep embedding with terms as `V` values would be needed to state it.

### consp-of-assoc-equal

Decision 49. The statement is `(implies (alistp alist) (iff (consp (assoc-equal key alist)) (assoc-equal key alist)))`. In the list-of-pairs representation, the value of `assoc-equal` is a pair or `nil`, and its truth is its being a pair. Both sides of the `iff` are therefore `(assocEqual key alist).isSome`, so the axiom is an identity. The hypothesis `alistp alist` is kept as the `alistp` predicate, which is `True`.

### alistp-of-getprops

Decision 49 and decision 41. `getprops` is an opaque signature whose result type is `AList ACLSymbol β`. The statement `alistp (getprops key world-name w)` holds by the type of `getprops`, so the axiom is stated with `alistp` of that value.

### characterp-of-char

Decision 50. `characterp` takes `Option Char` (deviation D1). The statement follows the ACL2 text, with `stringp` and `length` from ACL2.Base.

### code-char-char-code-is-identity-forced

Decision 50. The hypothesis `characterp c` is `characterp (some c)`, because `characterp` takes `Option Char`.

### char-code-code-char-is-identity-forced

Decision 50. `code-char` is total (deviation D2). The hypothesis `integerp n`, `0 ≤ n` and `n < 256` keeps the domain of ACL2 codes, so the statement is faithful on that domain.

### true-listp-when-arglistp

Decision 50. `arglistp` is an opaque signature (basis-a.lisp, line 856). `trueListp` is `True`.

### not-member-symbol-name-when-not-consp

Decision 50. The hypothesis `(not (consp l))` is `l = []`. `memberSymbolName` is the ACL2.Base definition.

### member-symbol-name-when-atom

Decision 50. The hypothesis `(atom symbols)` is `symbols = []`. `memberSymbolName` is the ACL2.Base definition.

### fix-when-acl2-numberp

Decision 52. `fix` is the ACL2.Base definition (identity on `Rat`). The hypothesis `acl2-numberp x` is `True`.

### acl2-numberp-of-fix

Decision 52. A `defthmd`, exported as a public axiom. The conclusion is `acl2NumberP (fix x)`, which is `True`.

### ifix-when-integerp

Decision 52. `ifix` is `ifixR` of ACL2.Base (decision 29).

### integerp-of-ifix

Decision 52. A `defthmd`, exported as a public axiom, using `ifixR`.

### nfix-when-natp

Decision 52. `natp` is the ACL2.Base definition, `integerp x ∧ 0 ≤ x`.

### natp-of-nfix

Decision 52. A `defthmd`, exported as a public axiom. `nfix` is the ACL2.Base definition.

### realfix-when-real/rationalp

Decision 52. `realfix` is the ACL2.Base identity. The hypothesis `real/rationalp x` is `realrationalp x`, which holds on `Rat`.

### real/rationalp-of-realfix

Decision 52. A `defthmd`, exported as a public axiom.

### rfix-when-rationalp

Decision 52. `rfix` is the ACL2.Base identity. The hypothesis `rationalp x` is `True` on `Rat`.

### rationalp-of-rfix

Decision 52. A `defthmd`, exported as a public axiom.

### string-listp-of-map-symbol-name

Decision 52. `string-listp` is `stringListp` of ACL2.Base, `True` on `List String`. `map-symbol-name` is an opaque signature (decision 41).

### map-symbol-name-of-cons

Decision 52. `map-symbol-name` is an opaque signature (decision 41). The statement uses `sym.name`, the `symbol-name` of `ACLSymbol`.

### true-listp-of-add-to-set-equal

Decision 52. `add-to-set-equal` is `addToSetEqual` of ACL2.Base. `true-listp` is `trueListp`, which is `True`.

### true-listp-of-add-to-set-equal-type

Decision 52. The `:rule-classes :type-prescription` is not part of the statement.

### arity-iff

Decision 52 and deviation. `fn` ranges over `ACLSymbol`, so `(consp fn)` is always false here, and the cons case is not represented. `arity` is an opaque signature (decision 41).

### primitivep-forward-to-symbolp

Decision 52 and deviation D3. `symbolp` is `True` on `ACLSymbol`, so the statement is trivial in this embedding.

### append-preserves-real-listp

Excluded in standard ACL2: the theorem sits under `#+:non-standard-analysis` (arithmetic/real-listp.lisp), so it is not generated (decision 12).

### realp-car-real-listp

Excluded in standard ACL2: the theorem sits under `#+:non-standard-analysis` (arithmetic/real-listp.lisp), so it is not generated (decision 12).

### booleanp-of-pseudo-event-formp

Excluded: metaprogramming. The theorem quantifies over ACL2 event forms as data (`pseudo-event-formp`), which the shallow embedding does not represent.

### pseudo-event-formp-of-cons

Excluded: metaprogramming. The theorem quantifies over ACL2 event forms as data (`pseudo-event-formp`), which the shallow embedding does not represent.

### true-listp-when-pseudo-event-form-listp-rewrite

Excluded: metaprogramming. The theorem quantifies over lists of ACL2 event forms as data (`pseudo-event-form-listp`), which the shallow embedding does not represent.

### realp-sumlist

Excluded in standard ACL2: the theorem sits under `#+:non-standard-analysis` (arithmetic/sumlist.lisp), so it is not generated (decision 12).

### append-preserves-rational-listp

1. Statement over `List Rat`, the shallow domain of decision 5. `append` is `++`, `true-listp` is `trueListp`, `rational-listp` is `rationalListp` (`True`, see decision 53). The statement is trivially true in Lean. The ACL2 content is not represented (deviation, decision 53).


### rationalp-car-rational-listp

1. Statement over `List Rat`. The hypothesis `x` (non-nil) is `x ≠ []`. `car x` is `x.headD 0`, and `rationalp` is `True`, so the conclusion is trivially true in Lean (deviation, decisions 53 and 54).


### rationalp-sumlist

The hypothesis `rational-listp` and the conclusion `rationalp` are both `True` on the Lean domain `Rat` and `List Rat`, as `rationalListp` and `rationalp` are defined in `Base.lean`. The axiom keeps the ACL2 hypothesis as `rationalListp x`, which imposes no condition on `List Rat`. This follows general decision 5, that quantified variables range over `List Rat`. The statement is the ACL2 statement, with its hypothesis, on that domain.


### equal-of-booleans-cheap

1. Statement over `Prop` (truth values, shallow table). `booleanp` is `True` (deviation D4, decision 53). The hypotheses `booleanp x` and `booleanp y` are kept, and they hold for every `x` and `y`.
2. `:rule-classes` are dropped. `backchain-limit-lst 0` is a prover setting, not part of the statement.


### equal-of-booleans

1. Statement as in `equal-of-booleans-cheap`. It is `defthmd`, disabled by default in ACL2. The axiom is `public`, and the `defthmd` status is not a rule class, so it is stated as a theorem.

## Deviation D4 (decision 53, proposed)

`booleanp` maps to `True` on `Prop`. ACL2 `booleanp` holds of exactly the two objects `t` and `nil`. A `Prop` ranges over all propositions, so the carrier has more values than the ACL2 domain of truth values. The statements remain true in the interpretation, because the equality `x = y` of propositions and `x ↔ y` coincide for every `x` and `y` by `propext`. The restriction to the two truth values is not represented, so the hypotheses `booleanp x` and `booleanp y` impose no condition. A faithful restriction needs a carrier with two values, such as `Bool`, and the choice is open for the user, as with D1.


### state-p1-of-update-acl2-oracle

The ACL2 hypothesis `(state-p1 state)` is `state-p1 st →`, and the conclusion `(equal (state-p1 ...) (true-listp x))` is the biconditional with `trueListp x`. The argument `x` ranges over `List α`
(decision 53). ACL2 accepts every object as `x`, so the axiom covers only the list case.

Theorems not generated: none. The `in-theory` forms (`disable`, `local (in-theory ...)`) are not theorems.
`update-acl2-oracle-preserves-state-p1` is named in the `in-theory` form, and this book does not
define it, so it is not an axiom of this module.

Result: no metaprogramming, so the book is generated.


### zero-digit-to-char

Decision 53. The variable `x` ranges over `Rat`. ACL2 `x` may be any object, and for a non-rational object the
ACL2 right side is true by `(not (integerp x))`. The Lean statement does not quantify over those objects, so
the statement covers the rationals only. The statement text follows the ACL2 `defthmd` as printed.


### digit-to-char-injective

No deviation. The hypotheses `integer-range-p 0 16` restrict `x` and `y` to integers, so the quantification over `Rat`
loses no case.

### true-listp-of-union-equal

No deviation in the statement. `union-equal` is the ACL2.Base definition `unionEqual` (decision 53), and `true-listp` is `trueListp`, which is `True` on lists.

### true-listp-of-union-equal-type

No deviation in the statement. Its `:rule-classes :type-prescription` is not part of the statement.

### open-input-channels-of-update-acl2-oracle

No deviation in the statement. `open-input-channels` and `update-acl2-oracle` are opaque signatures (decision 41), and the statement uses them as constants. The argument `x` ranges over `List α` (decision 53).

### w-of-update-acl2-oracle

No deviation in the statement. `w` and `update-acl2-oracle` are opaque signatures (decision 41). The argument `x` ranges over `List α` (decision 53).

### sumlist-append

No deviation in the statement. `sumlist` is an opaque signature (decision 41), and `append` is `++`.

### len-test-2

No deviation in the statement. `test-2` is an opaque constant of type `String` (decision 53). The statement `length (test-2) = 2` is a fact about the file encoding, which this embedding does not represent. It is recorded as a deviation.

### string-listp-of-symbol-name-lst

No deviation in the statement. `symbol-name-lst` is an opaque signature (decision 41), and `string-listp` is `stringListp`, which is `True` on lists of strings.

### len-of-symbol-name-lst

No deviation in the statement. `symbol-name-lst` is an opaque signature (decision 41), and `len` is the ACL2.Base definition.

### remove-weak-inequalities-one

The theorem is excluded. Its book, arithmetic-3/bind-free/remove-weak-inequalities, is excluded as metaprogramming. The ACL2 statement is `(<= x y)` implies `(<= x y)` under two `syntaxp` hypotheses over `mfc` and `state`.

### remove-weak-inequalities-two

The theorem is excluded. Its book, arithmetic-3/bind-free/remove-weak-inequalities, is excluded as metaprogramming. The ACL2 statement is `(< x y)` implies `(< x y)` under two `syntaxp` hypotheses over `mfc` and `state`.

### nonlinearp-default-hint-pass1

The defun is an opaque constant with no body (decision 41). Its ACL2 arguments are untyped, so the signature is {α β γ : Type} → Prop → List α → β → Option (List γ). The first argument is the truth value stable-under-simplificationp. The second is the history hist, and the third is the prover state pspv. The result is none for nil and some list for a computed hint. No statement of the book uses this constant, so the signature does not affect any statement.

### expt-crock

No deviation in the statement. The theorem is new with respect to the arithmetic-2 template, and its variable x ranges over CRat, because the ACL2 statement has no hypothesis.

### expt-minus-redux

New in arithmetic-3, absent from the template. It is local, so it is a `private axiom`. The ACL2 exponent `(* -1 i)` is written `-1 * i`. The `:hints` are dropped.

### arith-associativity-of-*

No deviation in the statement.

### arith-commutativity-of-*

No deviation in the statement.

### arith-commutativity-2-of-*

No deviation in the statement.

### arith-unicity-of-1

No deviation in the statement. `fix` on `CRat` is `fixC`.

### arith-times-zero

No deviation in the statement.

### arith-inverse-of-*-1

The variable `x` ranges over `Rat`, because `rationalp x` constrains it to the reals (general decision 17). The ACL2 `(/ x)` is `x⁻¹`.

### arith-inverse-of-*-2

The variable `x` ranges over `Rat` (general decision 17), and it is coerced with `↑` to `CRat` where the complex product occurs. The variable `y` ranges over `CRat`.

### arith-inverse-of-*-3

The variable `x` ranges over `Rat` (general decision 17), and it is coerced with `↑` to `CRat`. The variable `y` ranges over `CRat`.

### arith-functional-self-inversion-of-/

No deviation in the statement.

### arith-distributivity-of-/-over-*

No deviation in the statement.

### arith-functional-commutativity-of-minus-*-right

No deviation in the statement.

### arith-functional-commutativity-of-minus-*-left

No deviation in the statement.

### arith-reciprocal-minusa

No deviation in the statement.

### arith-distributivity-1

No deviation in the statement.

### arith-distributivity-2

No deviation in the statement.

### arith-fold-consts-in-*

Both `(syntaxp (quotep c))` and `(syntaxp (quotep d))` are represented as the hypothesis `syntaxpW` (general decision 25), so the `quotep` condition is not represented. The representation is deferred to the user.

### arith-expt-0

The exponent `i` ranges over `Rat`, as the template `expt.lean` states (general decision 29). The ACL2 variable `i` is unconstrained, so the Lean statement quantifies over fewer values than the ACL2 statement.

### arith-expt-1

The exponent `i` ranges over `Rat`, as in `arith-expt-0` (general decision 29).

### arith-expt-minus-1

No deviation in the statement. The exponent `-1` is a `Rat`, and `(/ x)` is `CRat.inv x`.

### arith-functional-commutativity-of-expt-/

The exponent `i` ranges over `Rat` (general decision 29). The sides follow the arithmetic-3 text, so the left side is `CRat.inv (exptC r i)`, which is the reverse of the template's `functional-commutativity-of-expt-/-base`.

### arith-expt-minus-exponent

The exponent `i` ranges over `Rat` (general decision 29).

### arith-expt-negative-constant-exponent

The hypothesis `(syntaxp (quotep i))` is represented as `syntaxpW` (general decision 25), so the `quotep` condition is not represented. The exponents `i` and `j` range over `Rat` (general decision 29).

### arith-exponents-multiply

The exponents `i` and `j` range over `Rat` (general decision 29). The hypotheses `integerp i` and `integerp j` are kept, and `integerp` on `Rat` is the Base interpretation.

### arith-distributivity-of-expt-over-*

The exponent `i` ranges over `Rat` (general decision 29).

### arith-fix-revealed

The hypothesis `acl2-numberp x` is `acl2NumberPC x`, which is constant `True` on `CRat`. No deviation otherwise.

### arith-Rational-implies2

The variable `x` ranges over `Rat`, because `rationalp x` constrains it to the rationals. The ACL2 `numerator` and `denominator` of a rational are written inline as the Lean projections `x.num` and `x.den` coerced to `Rat`, because `Base.lean` has `numeratorC` and `denominatorC` only for `CRat`. No primitive is added to Base.

### arith-exponents-add-1

The exponents `i` and `j` range over `Rat` (general decision 29). The `not equal` hypothesis is `¬ (i + j = 0)`, and the conclusion has no `if`, as the arithmetic-3 text has none.

### arith-exponents-add-for-nonpos-exponentsa

The exponents `i` and `j` range over `Rat` (general decision 29).

### arith-exponents-add-for-nonneg-exponentsa

The exponents `i` and `j` range over `Rat` (general decision 29).

### arith-exponents-add-2

The base `r` ranges over `CRat`, and the exponents `i` and `j` range over `Rat` (general decision 29).

### hack

No deviation in the statement. The variable is unconstrained, so it ranges over CRat (decision 14). The defthm at line 99 is non-local, so the axiom is public. The statement is `(* -1 x) = (- x)`, written `(-1 : CRat) * x = -x`.
