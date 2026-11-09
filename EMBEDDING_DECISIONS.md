# EMBEDDING_DECISIONS

This file records every deviation from the ACL2 source in the Lean axioms.

## General decisions

1. The embedding is shallow. Each ACL2 theorem or lemma becomes a Lean proposition over Lean types, not over a deep syntax of ACL2 terms. The user chose this. It deviates from ACL2 semantics.
2. Every ACL2 number is a `Rat`. Integer arguments are tested with `integerp`, which is `den = 1`. ACL2 functions are interpreted on `Rat` and on `List Rat`.
3. ACL2 truth values `t` and `nil` become Lean `Prop`. The connectives `implies`, `and`, `or`, `not` and `equal` become the corresponding Lean connectives.
4. ACL2 primitives and definitions used in the books are interpreted by Lean functions, listed in the interpretation table. A definition of a book is a Lean `def` with the ACL2 name in guillemets.
5. Quantified variables range over `Rat` or `List Rat`, not over all ACL2 objects. A theorem with no hypothesis, such as `abs-uminus`, therefore holds in Lean only for rational arguments. The ACL2 statement is stronger on non-rational arguments.
6. Support definitions live in `Lean/ACL2/Base.lean`, outside the mirror of the books directory tree.
7. Hyphens in ACL2 names are kept with Lean guillemets, for example `«abs-*»`.
8. Each ACL2 theorem is an `axiom`. The `:rule-classes`, hints and proofs of the ACL2 theorems are not represented.
9. The axioms of a module do not import the modules of the books it includes with `local` `include-book`, because a local include is not visible to the books that include the module. Non-local includes are imported when their module exists.
10. Recursive ACL2 definitions that recurse on an integer argument are Lean `def`s with a helper on `Int`, named `…Z`. The helper unfolds to the ACL2 recursion. The termination proof is by `termination_by` on the natural measure of the ACL2 `:measure`.
11. Local theorems and lemmas are axioms too, because the requirement covers every theorem and lemma in the book file.
12. A reader conditional that excludes a form in standard ACL2 excludes its axiom. `realp-sumlist` in `sumlist.lisp` is guarded by `#+:non-standard-analysis`, so it has no axiom.
13. `Rat` division `a / b` equals ACL2 `(/ a b)`, because both give 0 for a zero divisor.

## Interpretation table

| ACL2 | Lean (`ACL2` namespace) |
| --- | --- |
| `realrationalp` | `realrationalp`, constant `True` on `Rat` |
| `acl2NumberP` | `acl2NumberP`, constant `True` on `Rat` |
| `rationalp` | `rationalp`, constant `True` on `Rat` |
| `rationalListp` | `rationalListp`, constant `True` on `List Rat` |
| `integerp` | `integerp r` is `r.den = 1` |
| `zp` | `zp x` is `integerp x → x ≤ 0` |
| `fix` | `fix`, identity on `Rat` |
| `nfix` | `nfix x` is `x` when `x` is a nonnegative integer, else `0` |
| `abs` | `abs`, `if x < 0 then -x else x` |
| `expt` | `expt r i`, `exptInt r i.num` for an integer `i`, else `1` |
| `factorial` | `factorial n`, `factorialZ n.num` for an integer `n`, else `1` |
| `choose` | `choose k n`, the factorial quotient for integers `0 ≤ k ≤ n`, else `0` |
| `choose-mk` | `choose-mk k n`, `chooseMkZ` on the numerators of integers, else `0` |
| `sumlist` | `sumlist`, the sum of a `List Rat` |
| `binomial-expansion` | `binomialExpansionZ`, a `List Rat`, on integers, else `[]` |
| `binomial-expansion-times-x` | `binomialExpansionTimesXZ`, on integers, else `[]` |
| `binomial-expansion-times-y` | `binomialExpansionTimesYZ`, on integers, else `[]` |
| `binomial-expansion-triangle` | `binomialExpansionTriangleZ`, on integers, else `[]` |
| `binomial-expansion-pascal-triangle` | `binomialExpansionPascalZ`, on integers, else `[]` |
| `n-expt` | `nExptZ`, on the numerator of an integer, else `1` |

## Element decisions

### abs-*

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### abs-uminus

1. Uses `fix`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. No hypothesis, so the axiom holds for rational arguments only (general decision 5).

### realp-abs

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### numberp-abs

1. Uses `acl2NumberP`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.

### abs-x->-0

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### abs-x-=-0-iff-x=0

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### not-abs-x-<-0

1. Uses `abs`, interpreted as in the table.
2. No hypothesis, so the axiom holds for rational arguments only (general decision 5).

### abs-x-generalize-weak

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### abs-x-generalize-strong

1. Uses `realrationalp`, interpreted as in the table.
2. Uses `abs`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### abs-triangle

1. Uses `abs`, interpreted as in the table.
2. No hypothesis, so the axiom holds for rational arguments only (general decision 5).

### factorial-positive-integer

1. Uses `integerp`, interpreted as in the table.
2. Uses `factorial`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### factorial-non-negative

1. Uses `factorial`, interpreted as in the table.

### abs-factorial

1. Uses `abs`, interpreted as in the table.
2. Uses `factorial`, interpreted as in the table.

### rationalp-sumlist

1. Uses `rationalp`, interpreted as in the table.
2. Uses `rationalListp`, interpreted as in the table.
3. Uses `sumlist`, interpreted as in the table.
4. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
5. Interpretation of `rational-listp` as `rationalListp` is `True`, so the hypothesis holds on `List Rat`.

### sumlist-append

1. Uses `sumlist`, interpreted as in the table.

### factorial-n/n-1

1. Uses `integerp`, interpreted as in the table.
2. Uses `factorial`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### factorial-n/n-1/x

1. Uses `integerp`, interpreted as in the table.
2. Uses `factorial`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
4. local in the book, included as an axiom (general decision 11).

### choose-reduction

1. Uses `integerp`, interpreted as in the table.
2. Uses `choose`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### choose-mk-choose

1. Uses `choose`, interpreted as in the table.
2. Uses `choose-mk`, interpreted as in the table.

### choose-is-non-negative-integer

1. Uses `integerp`, interpreted as in the table.
2. Uses `choose`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### binomial-expansion-times-x-correct

1. Uses `sumlist`, interpreted as in the table.
2. Uses `binomial-expansion`, interpreted as in the table.
3. Uses `binomial-expansion-times-x`, interpreted as in the table.

### binomial-expansion-times-y-correct

1. Uses `sumlist`, interpreted as in the table.
2. Uses `binomial-expansion`, interpreted as in the table.
3. Uses `binomial-expansion-times-y`, interpreted as in the table.

### binomial-expansion-times-x-plus-times-y

1. Uses `sumlist`, interpreted as in the table.
2. Uses `binomial-expansion-times-x`, interpreted as in the table.
3. Uses `binomial-expansion-times-y`, interpreted as in the table.
4. Uses `binomial-expansion-triangle`, interpreted as in the table.

### silly-inequality

1. Uses `integerp`, interpreted as in the table.
2. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
3. local in the book, included as an axiom (general decision 11).

### choose-k-k

1. Uses `integerp`, interpreted as in the table.
2. Uses `choose`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
4. local in the book, included as an axiom (general decision 11).

### expt-x-0

1. Uses `expt`, interpreted as in the table.
2. local in the book, included as an axiom (general decision 11).

### binomial-expansion-triangle-x-y-k-1+k

1. Uses `binomial-expansion-triangle`, interpreted as in the table.
2. local in the book, included as an axiom (general decision 11).

### binomial-expansion-triangle-x-y-k-k-lemma

1. Uses `integerp`, interpreted as in the table.
2. Uses `expt`, interpreted as in the table.
3. Uses `binomial-expansion-triangle`, interpreted as in the table.
4. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
5. local in the book, included as an axiom (general decision 11).

### binomial-expansion-pascal-triangle-correct

1. Uses `integerp`, interpreted as in the table.
2. Uses `expt`, interpreted as in the table.
3. Uses `choose`, interpreted as in the table.
4. Uses `sumlist`, interpreted as in the table.
5. Uses `binomial-expansion-triangle`, interpreted as in the table.
6. Uses `binomial-expansion-pascal-triangle`, interpreted as in the table.
7. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### binomial-expansion-zero

1. Uses `binomial-expansion`, interpreted as in the table.

### pascal-triangle-binomial

1. Uses `integerp`, interpreted as in the table.
2. Uses `sumlist`, interpreted as in the table.
3. Uses `binomial-expansion`, interpreted as in the table.
4. Uses `binomial-expansion-pascal-triangle`, interpreted as in the table.
5. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### choose-0-n

1. Uses `integerp`, interpreted as in the table.
2. Uses `choose`, interpreted as in the table.
3. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### binomial-theorem-induction-lemma

1. Uses `integerp`, interpreted as in the table.
2. Uses `sumlist`, interpreted as in the table.
3. Uses `binomial-expansion`, interpreted as in the table.
4. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### distributivity-2

1. local in the book, included as an axiom (general decision 11).

### binomial-theorem-fake

1. Uses `integerp`, interpreted as in the table.
2. Uses `sumlist`, interpreted as in the table.
3. Uses `binomial-expansion`, interpreted as in the table.
4. Uses `n-expt`, interpreted as in the table.
5. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### n-expt-expt

1. Uses `integerp`, interpreted as in the table.
2. Uses `expt`, interpreted as in the table.
3. Uses `n-expt`, interpreted as in the table.
4. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### binomial-theorem

1. Uses `integerp`, interpreted as in the table.
2. Uses `expt`, interpreted as in the table.
3. Uses `sumlist`, interpreted as in the table.
4. Uses `binomial-expansion`, interpreted as in the table.
5. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.

### binomial-sum-commutes

1. Uses `integerp`, interpreted as in the table.
2. Uses `sumlist`, interpreted as in the table.
3. Uses `binomial-expansion`, interpreted as in the table.
4. Hypotheses are kept. Their interpretation holds on `Rat` as in the table.
