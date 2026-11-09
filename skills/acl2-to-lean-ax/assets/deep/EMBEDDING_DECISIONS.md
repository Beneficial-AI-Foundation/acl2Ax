# EMBEDDING_DECISIONS

This file records every deviation from the ACL2 source in the Lean axioms.

## General decisions

1. The embedding is deep. An ACL2 object is a value of `ACL2.V`, and each ACL2 primitive is a Lean function on `V`.
2. Truth follows ACL2. A formula is true when its value is not `NIL`. A theorem is an axiom `truthy (formula)`.
3. ACL2 `nil` is `NIL`, and `t` is `T`. A Lean proposition used as a value passes through `ofProp`.
4. Every ACL2 primitive and definition used in a book is a Lean function on `V`, listed in the interpretation table. A definition of a book is a Lean `def` with the ACL2 name in guillemets.
5. Variables range over all of `V`. A theorem therefore has the ACL2 statement exactly.
6. Support definitions live in `Lean/ACL2/Base.lean`, outside the mirror of the books directory tree.
7. Hyphens in ACL2 names are kept with Lean guillemets, for example `«abs-*»`.
8. Each ACL2 theorem is an `axiom`. The `:rule-classes`, hints and proofs are not represented.
9. Visibility follows ACL2. A non-local `include-book` is a `public import`. A `local` `include-book` is a plain `import`, usable in the module and not re-exported. An exported axiom is `public axiom`, and a local axiom is `private axiom`. Local includes are imported only when their module exists. Until then the module records them as pending in a comment.
10. A recursive ACL2 definition is a Lean `def`. Recursion on a natural measure from the ACL2 `:measure` is given by `termination_by`.
11. Rule-set bookkeeping forms are not generated. These are `in-theory`, `deftheory`, `theory-invariant`, and the `enable` and `disable` forms they contain. They select which rewrite rules the ACL2 prover uses, and they state no theorem about values. Each theorem they refer to is still generated as its own axiom.
11. Local theorems and lemmas are axioms too.
12. A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.

10. Each book's declarations live in the namespace `ACL2.<book path>`, so that local includes do not clash with the book's own names.

## Interpretation table

| ACL2 | Lean (`ACL2` namespace) |
| --- | --- |
| `nil` | `NIL` |
| `t` | `T` |
| `car` | `car` |
| `cdr` | `cdr` |
| `consp` | `consp` |
| `acl2-numberp` | `acl2NumberP` |

## Element decisions
