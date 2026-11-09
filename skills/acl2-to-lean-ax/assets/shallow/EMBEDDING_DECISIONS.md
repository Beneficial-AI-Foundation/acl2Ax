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
9. Visibility follows ACL2. A non-local `include-book` is a `public import`. A `local` `include-book` is a plain `import`, usable in the module and not re-exported. An exported axiom is `public axiom`, and a local axiom is `private axiom`. Local includes are imported only when their module exists. Until then the module records them as pending in a comment.
10. A recursive ACL2 definition on an integer argument is a Lean `def` with a helper on `Int`, named `…Z`. The helper unfolds to the ACL2 recursion.
11. Rule-set bookkeeping forms are not generated. These are `in-theory`, `deftheory`, `theory-invariant`, and the `enable` and `disable` forms they contain. They select which rewrite rules the ACL2 prover uses, and they state no theorem about values. Each theorem they refer to is still generated as its own axiom.
11. Local theorems and lemmas are axioms too.
14. ACL2 complex rationals are the Lean type `CRat`, pairs of `Rat` with the field operations. A real `Rat` embeds in `CRat` with imaginary part 0. Theorems over the reals keep `Rat`, and theorems over numbers that may be complex use `CRat`.
15. The order `<` on `CRat` is the lexicographic order of `completion-of-<` (axioms.lisp, lines 25364 to 25374): `x < y` holds when `realpart x < realpart y`, or when the real parts are equal and `imagpart x < imagpart y`. On real arguments it coincides with the order on `Rat`.
16. No Mathlib dependency is used. The `CRat` type is defined in core Lean, so the shallow embedding needs no `require`.
12. A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.

10. Each book's declarations live in the namespace `ACL2.<book path>`, so that local includes do not clash with the book's own names.

## Interpretation table

| ACL2 | Lean (`ACL2` namespace) |
| `CRat` (ACL2 complex rational) | structure `CRat` with `re`, `im : Rat`, field operations, `Coe` from `Rat` |
| `realpart`, `imagpart` | `CRat.realpart`, `CRat.imagpart` |
| `<` on complex arguments | `CRat.lt`: lexicographic on `(realpart, imagpart)`, from `completion-of-<` (axioms.lisp 25364 to 25374) |
| `acl2-numberp` on `CRat` | `acl2NumberPC`, constant `True` |
| `/` on `CRat` | `CRat.inv` and `Div`, `0` for a zero argument, as `(/ 0)` in ACL2 |
| --- | --- |

## Element decisions
