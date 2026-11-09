---
name: acl2-to-lean-ax
description: Export an ACL2 books tree to Lean 4 axioms, one Lean module per certified book, with an HTML blueprint per book. Use when the user wants to translate ACL2 books, theorems or lemmas into Lean axioms, with a shallow (Rat-valued) or deep (ACL2 value) embedding, produce a Lean module structure mirroring ACL2 book directories, or generate a Verso or HTML blueprint of an ACL2 formalization.
---

# acl2-to-lean-ax

This skill exports the certified books of an ACL2 books tree to a Lean 4 project. Each certified
book becomes one Lean module with one `axiom` per `defthm` or `defaxiom`, and each book gets an
HTML blueprint. The ACL2 tree is an input. Nothing in this skill depends on where that tree lives.

## Inputs to fix before starting

1. `BOOKS`, the ACL2 books directory. Pass it as a path. Any location works.
2. `PROJECT`, the new Lean project directory. It must not be inside `BOOKS`.
3. `GITHUB`, optional. The web prefix of the same tree, for example `https://github.com/acl2/acl2/blob/8.7/books`. Without it, the blueprint links are omitted.
4. The Lean toolchain. Use the one installed through elan. Write it to `PROJECT/lean-toolchain`.
5. `--model sonnet|opus|haiku|fable`, the model that runs the generation. It is optional. When it is
   omitted, the run uses the model of the session that starts it. The model is chosen when the
   agent is started, so the session that runs this skill passes the value as the agent's model.
   After the run, `scripts/usage.py` reports the models that appear in the agent transcript.
   Record that model in the run log, not the model assumed beforehand.
6. `--embedding shallow|deep`, the kind of embedding. It is required, and it is fixed for the project:
   - `shallow`: each ACL2 statement is a Lean proposition over `Rat` and `List Rat`. Mathlib may be
     used for the number types. To use it, add a `[[require]]` block to `PROJECT/lakefile.toml` before
     the first build. `roots.py` keeps that block.
   - `deep`: each ACL2 object is a value of `ACL2.V`, and each primitive is a Lean function on `V`.
     A statement is an axiom `truthy (formula)`.
7. `--check N|converge`, the number of checking passes for each generated module. It takes the same
   form as `--cert yes|no`. `N` is a positive integer. `converge` runs passes until a pass makes no
   change. Default: `--check 1`.

`SKILL_DIR` is the directory that contains this SKILL.md. Run the scripts with `python3`. They use only the standard library.

## Procedure

1. Create the project and the manifest.

   ```
   python3 SKILL_DIR/scripts/inventory.py BOOKS PROJECT
   ```

   This writes `PROJECT/manifest.json` with every certified book as `pending`, and creates the mirror
   directories under `PROJECT/Lean/`. The script first prints how many `.lisp` files have a `.cert`
   and how many do not. Read that line before going further.

   The option `--cert` chooses the books. `--cert yes`, the default, takes only certified books.
   `--cert no` takes every `.lisp` file, including those without a `.cert`:

   ```
   python3 SKILL_DIR/scripts/inventory.py BOOKS PROJECT --cert no
   ```

   Each manifest entry then carries `"cert": true` or `"cert": false`. An uncertified book is
   translated the same way, and its blueprint says it has no certificate.

2. Copy the templates.

   ```
   python3 SKILL_DIR/scripts/scaffold.py PROJECT --embedding shallow|deep
   ```

   This copies `Lean/ACL2/Base.lean` and `EMBEDDING_DECISIONS.md` from `assets/shallow` or
   `assets/deep`. It never overwrites an existing file.

3. Order the books.

   ```
   python3 SKILL_DIR/scripts/order.py BOOKS PROJECT/ORDER.txt
   ```

   The script reads every `include-book` form, local ones included, and writes the books with each
   book after the books it includes. It exits with 1 if the graph has a cycle. A book is translated
   only after every book it includes, locally or not, has a module. A module that includes a local
   book that has no module yet records that import as pending, in a comment at the top of the module.

4. For each book, in that order:
   - Read the `.lisp` file. List every `defun`, `defthm`, `defthmd`, `defaxiom` and `defmacro`,
     including those inside `local` and `encapsulate`.
   - Add the Lean interpretation of each primitive or definition the book uses to `Lean/ACL2/Base.lean`
     or to the book module, following the conventions below.
   - Write `PROJECT/Lean/<book-dir>/<book>.lean`. Start it with `module`, then `public import ACL2.Base`.
     Add `public import <module>` for each non-local include whose module exists, and `import <module>`
     for each local include whose module exists. A module that does not exist yet is listed in a
     comment. Then write one axiom per theorem inside `namespace ACL2`: `public axiom` for an exported
     theorem, and `private axiom` for a theorem inside `local`.
   - Run the checking passes, as described under "Checking passes" below.
   - Record every deviation in `PROJECT/EMBEDDING_DECISIONS.md`: a general decision in the first
     part, the interpretation in the table, and an element decision under `### <theorem-name>`.
   - Run `python3 SKILL_DIR/scripts/roots.py PROJECT <LibraryName>`. Then `cd PROJECT && lake build`.
     Fix every error before the next book.
   - Run the checking passes with the value of `--check`.
   - Set the book's status in `manifest.json` to `axioms generated, lake build passes`.

5. Generate the blueprint for each book.

   ```
   python3 SKILL_DIR/scripts/blueprint.py PROJECT <book-path> --books BOOKS --github GITHUB --embedding shallow|deep
   ```

   Add `--no-build` to skip the build step. The page is written to `PROJECT/blueprint/<book>-blueprint.html`.
   The page lists the ACL2 source, the Lean axiom and the element decisions of each theorem.
   The status row says whether `<book>.cert` is present. When it is absent, the page says the book
   is not certified, and it omits the certificate dump.

6. Report what was done. Give the count of axioms per book, the books not yet generated, and every
   deviation that needs the user's decision.

## Scope

- Metaprogramming is out of scope for this version of the skill. A book is skipped, and its manifest
  status is set to `excluded: metaprogramming`, when it defines a metafunction, a clause processor or a
  `:meta` rule, or when its functions take ACL2 terms as data. Such a book is listed in the final report.
- Each book is translated in the order of the dependency order file, which lists non-local includes
  before the books that use them. Build that order with the dependency script before the first book.

## Datatype mapping

Lisp has few data types, so each Lisp value is mapped to the Lean type that matches its use. Choose
the mapping from the book's guards, signatures and the theorems that use the values. Record each
mapping in `EMBEDDING_DECISIONS.md`.

| ACL2 value | shallow embedding | deep embedding (`V`) |
| --- | --- | --- |
| rational `r` | `Rat` | `V.num r` |
| complex rational | `CRat` | `V.num` with imaginary part, once the deep base has it |
| `t`, `nil` as a truth value | `Prop` | `T`, `NIL` through `truthy` |
| symbol | a symbol type in `Base.lean` | `V.sym` |
| string | `String` | `V.str` |
| character | `Char` | a `V` character constructor, added to the deep base when a book needs it |
| proper list of one element type | `List α` | `V` cons cells, `NIL` for the empty list |
| list of mixed type, or a dotted pair | not representable: exclude and record | `V.cons` |

Rules for the mapping:

- A list of numbers in the books is `List Rat` in the shallow embedding, with `nil` as `[]`. Do not use a
  general `V` for it when `List Rat` is the type the theorem uses.
- A value that is used both as a number and as a symbol, such as the result of `fix` on a non-number,
  needs the deep embedding. In the shallow embedding, record it as a deviation and keep the statement.
- Lisp `nil` is the empty list and also the false truth value. The shallow embedding keeps these apart:
  `[]` for the list and `False` for the truth value. The deep embedding uses `NIL` for both, as ACL2 does.
- Never map a value to a type that has more or fewer values than the ACL2 domain of that value, without
  a recorded deviation.

## Checking passes

A checking pass has two parts for one module:

1. Run the name check.

   ```
   python3 SKILL_DIR/scripts/check_axioms.py PROJECT <book-path> --books BOOKS --check N|converge
   ```

   Each call is one pass. The script records the pass count, a hash of the checked files and the
   result in the manifest entry under `"check"`. It prints `stop` when the stopping rule is met and
   `continue` otherwise. After a `continue`, make the corrections and call the script again.

   The script lists every ACL2 `defthm`, `defthmd` and `defaxiom` of the book that has no axiom,
   every axiom with no ACL2 form, and every duplicate. A name recorded under `### name` in
   `EMBEDDING_DECISIONS.md` with the word "excluded" is not expected.

2. Re-read the ACL2 source of each statement, and compare it with the Lean axiom. Correct any
   statement that differs from the ACL2 text. Then run `lake build`.

Stopping rules, as the script applies them:

- `--check N` stops after `N` passes, whether or not a pass changed the module.
- `--check converge` stops at a pass whose checked files are unchanged since the previous pass and
  whose names agree. The first pass never stops a `converge` run.

Each pass must end with `lake build` passing before the next pass is called.

## Dependency rule

- A generated module depends only on modules that exist, and it imports each of them. Run
  `python3 SKILL_DIR/scripts/check_deps.py PROJECT --books BOOKS` after each module. A module with a
  missing dependency is moved to `PROJECT/staged/`, out of `Lean/`, with its manifest status naming
  what it waits for. It is generated again when its dependencies exist.

## Visibility of local events (summary of the module rules)

- The module starts with `module`. A non-local `include-book` is `public import <module>`.
- A `local` `include-book` is a plain `import`. The module can use it, and it is not re-exported.
- An exported `defthm` or `defaxiom` is `public axiom`. A `local` one is `private axiom`.
- Each book's declarations are in the namespace `ACL2.<book path>`, for example `namespace ACL2.«arithmetic-2».pass1.«basic-arithmetic»`. The shared `Base.lean` stays in `ACL2`.
- Build the dependency order with local includes as well as non-local ones, using `scripts/order.py`.
  A local include must be generated before the book that includes it, so its module can be imported.
- The shallow and deep `Base.lean` templates are modules, with `public section`, so their declarations are public.

## Conventions for the Lean axioms, shallow embedding

- Statements follow the ACL2 `defthm` text exactly. Never change a statement to suit a proof or a
  Lean convenience. If a statement cannot be expressed faithfully, record the gap and ask.
- Variables range over `Rat`. An ACL2 `integerp` test becomes `integerp` on `Rat`. Hypotheses stay.
- Interpret `real/rationalp`, `rationalp`, `acl2-numberp` as `True` on `Rat`, and record that.
- A `defun` becomes a `def` whose name is the ACL2 name in guillemets. A recursion on an integer
  becomes a helper on `Int` plus a wrapper that applies `integerp` and the numerator.
- Use `termination_by` on a natural measure taken from the ACL2 `:measure` or from the recursion.
- Keep `:rule-classes`, `:hints`, `:in-theory` and proofs out of the Lean code.
- A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.
- The complex numbers of ACL2 are `CRat`. Its `<` is the lexicographic order, `<=` is `acl2le`, and `(/ x)` is `CRat.inv`.
- `numerator` of a complex rational is `numeratorC`. `expt` on complex rationals is `exptC`, and `fc` is the identity, so it is inlined.
- A `syntaxp` or `quotep` hypothesis is represented as an always-inhabited type, `PUnit`, as in `Lean/ACL2/Base.lean`. Its representation is deferred to the user, and the decisions file records the deferral.
- A `defun` of a book is an opaque constant with its type signature and no body. Its axioms are stated, not proved.
- Do not invent theorems. Each axiom corresponds to one ACL2 `defthm` or `defaxiom`.

## Conventions for the Lean axioms, deep embedding

- Every ACL2 object is a `ACL2.V`: `num`, `sym`, `str` or `cons`. `NIL` is `sym "NIL"` and `T` is `sym "T"`.
- Each primitive is a Lean function `V → V` or `V → V → V`, with ACL2 semantics for every argument,
  including non-numbers. Add a primitive to `Lean/ACL2/Base.lean` when a book first uses it, and record
  it in the interpretation table.
- A statement is `axiom «name» : truthy (formula)`. Connectives return `T` or `NIL`, using `ofProp`
  for a Lean proposition.
- Variables range over `V`. Hypotheses are conjuncts of the formula, as in ACL2.
- A `defun` becomes a Lean `def` on `V`, with `termination_by` taken from the ACL2 `:measure` or from the recursion.
- Keep `:rule-classes`, `:hints`, `:in-theory` and proofs out of the Lean code.
- A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.
- Do not invent theorems. Each axiom corresponds to one ACL2 `defthm` or `defaxiom`.

- Statements follow the ACL2 `defthm` text exactly. Never change a statement to suit a proof or a
  Lean convenience. If a statement cannot be expressed faithfully, record the gap and ask.
- Variables range over `Rat`. An ACL2 `integerp` test becomes `integerp` on `Rat`. Hypotheses stay.
- Interpret `real/rationalp`, `rationalp`, `acl2-numberp` as `True` on `Rat`, and record that.
- A `defun` becomes a `def` whose name is the ACL2 name in guillemets. A recursion on an integer
  becomes a helper on `Int` plus a wrapper that applies `integerp` and the numerator.
- Use `termination_by` on a natural measure taken from the ACL2 `:measure` or from the recursion.
- Keep `:rule-classes`, `:hints`, `:in-theory` and proofs out of the Lean code.
- A reader conditional that excludes a form in standard ACL2 excludes its axiom, and the exclusion is recorded.
- Do not invent theorems. Each axiom corresponds to one ACL2 `defthm` or `defaxiom`.

## Limits

- A module imports only the modules that exist. A pending import is recorded, and it is added when the module is generated.

- `lake build` checks that the axioms compile. It does not check that they are true in the interpretation.
- The ACL2 certificate is not checked by this skill. Use the ACL2 system to certify the books.
- A `.cert` file is a build artifact. A source checkout without certificates, such as a git clone, has no certified books until the books are certified.
- The blueprint shows the recorded decisions. A decision that was not recorded does not appear.
