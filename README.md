# acl2Ax

acl2Ax turns the theorems of certified ACL2 books into Lean 4 axioms. Each ACL2 book becomes one
Lean module with one `axiom` per theorem, and each book gets an HTML blueprint page that shows the
ACL2 source next to its Lean statement. "Ax" stands for axioms: the theorems are proved in ACL2,
not in Lean, so Lean takes them as axioms.

acl2Ax is a prototype. The blueprint pages are published at
<https://beneficial-ai-foundation.github.io/acl2Ax/>. Planned work is tracked in
[issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1).

## What acl2Ax does

- It mirrors the ACL2 books tree. For example, the book `std/basic/nfix.lisp` becomes the Lean
  module `Lean/std/basic/nfix.lean`.
- It writes one Lean `axiom` per `defthm`, `defthmd` or `defaxiom` in the book.
- It gives each ACL2 primitive and function that a book uses a Lean meaning, in
  `Lean/ACL2/Base.lean` or in the book's module.
- It records every place where a Lean statement departs from its ACL2 source, in
  `EMBEDDING_DECISIONS.md`.
- It checks each module: the axiom names must match the theorem names of the book, and
  `lake build` must pass.
- It writes one blueprint page per book.
- It keeps the copyright and license of each book. Before it translates a book, it checks that the
  book is under a 3-clause BSD license, and it stops otherwise. Each module and each blueprint page
  then carries the book's copyright line.

For example, the book `std/basic/nfix.lisp` has, at line 21:

```lisp
(defthm nfix-when-natp
  (implies (natp x)
           (equal (nfix x) x)))
```

The export states it in `exports/acl2-8.7-local-haiku-lean/Lean/std/basic/nfix.lean` as:

```lean
public axiom «nfix-when-natp» : ∀ x : Rat, natp x → nfix x = x
```

## What acl2Ax does not do

- It proves nothing in Lean, and it does not replay ACL2 proofs.
- It does not check that a Lean statement means the same as its ACL2 source. The name check
  compares names only, and `lake build` checks only that the statements are well typed.
- It finds theorems by reading the text of the book. A theorem that a macro creates, such as the
  `:returns` theorem of a `define`, gets no axiom.
- It treats a `defaxiom` like a `defthm`. ACL2 proves each `defthm`, but it assumes each
  `defaxiom` without proof, and both become the same kind of Lean axiom. It does not mark books
  that use `skip-proofs` or a trust tag.
- Its blueprint script finds only `defthm` and `defthmd` forms in the source, so the blueprint
  step stops on a book that has a `defaxiom`.
- It treats every `encapsulate` as transparent. In an `encapsulate` with signatures, the local
  theorems are about the local witness, yet they become axioms about the constrained function.
- It skips metaprogramming books (metafunctions, clause processors, `:meta` rules, functions on ACL2
  terms) and events under `#+:non-standard-analysis`. A skipped book gets a module with no axioms.
- It keeps no hints, rule classes or proofs.

[Issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1) plans fixes for most of these.

## Why axioms

ACL2 has a large library of proved theorems, but its proofs do not carry over to Lean directly. ACL2
finds a proof inside its own prover, by rewriting and induction, and a certified book records that
the proof succeeded, not a proof that Lean could check. Replaying those proofs in Lean, or proving
the theorems again, takes far more work than stating them.

So acl2Ax states each theorem in Lean and takes it as an axiom. Lean users get the statements now,
and the trust they place in them stays visible: `#print axioms` lists every acl2Ax axiom a theorem
uses. An axiom can later be replaced by a Lean proof under the same name, without changing the
theorems that use it ([issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1), item 18).

## What an axiom rests on

An axiom of acl2Ax is only as good as three assumptions:

1. **ACL2 proved the theorem.** The book is certified, and ACL2 is trusted. acl2Ax does not check
   certificates. The checkers in `tools/cert-checker/` and `tools/cert-checker-js/` compare a
   `.cert` file with its book, without replaying proofs.
2. **The Lean statement says what the ACL2 theorem says.** A language model writes the statements.
   They are checked by name and by re-reading the source, but nothing proves them equivalent.
3. **The Lean definitions of the ACL2 primitives match ACL2.** They are in `Lean/ACL2/Base.lean`
   and in some modules. Where they differ from ACL2, the difference is recorded in
   `EMBEDDING_DECISIONS.md`.

The export's `Base.lean` also has three technical axioms, `worldNonempty`, `stateNonempty` and
`inputChannelsNonempty`. They say that its opaque types for the ACL2 world, state and input
channels have at least one value.

A wrong axiom can make Lean prove `False`, so a Lean theorem that uses these axioms holds only
under these assumptions. `#print axioms <theorem>` lists the axioms that a theorem uses.

## Repository layout

The repository holds two Lean projects with different conventions.

| | Pilot | Export |
| --- | --- | --- |
| Location | the repository root (`Lean/`, `lakefile.toml`) | `exports/acl2-8.7-local-haiku-lean/` |
| Books | 4 from `books/arithmetic`: `abs`, `binomial`, `factorial`, `sumlist` | 57, see [Current scope](#current-scope) |
| A book's `defun` | a `def` with a body | an `opaque` constant with no body |
| Lean library | `ACL2Ax` | `AcL2LocalHaiku` |
| Namespace | `ACL2` | `ACL2.<book path>` |
| Conventions | `CLAUDE.md` and the root `EMBEDDING_DECISIONS.md` | `skills/acl2-to-lean-ax/SKILL.md` and the export's `EMBEDDING_DECISIONS.md` |
| Blueprint | `tools/blueprint/<book>-blueprint.html` | `blueprint/` in the export, published at <https://beneficial-ai-foundation.github.io/acl2Ax/> |

Other files:

- `LICENSE`, `NOTICE.md` and `LICENSES/`: see [License](#license).
- `skills/acl2-to-lean-ax/`: the Claude Code skill that made the export. It holds `SKILL.md`, the
  scripts, and the templates for a new project.
- `tools/blueprint/`: the pilot's blueprint generator and pages. `blueprint/` at the root holds
  another version of the pilot's `abs` page.
- `tools/cert-checker/` and `tools/cert-checker-js/`: certificate checkers in C and in Node.js.
  Their READMEs give their status and use.
- `mappings/arithmetic.json`: the package, Lean namespace and includes of each `books/arithmetic`
  book, for the pilot.
- `manifest.json`: the 1452 books that were certified in the ACL2 8.7 tree used here, with the
  pilot's status for each. The export has its own `manifest.json`.
- `.github/workflows/pages.yml`: publishes the export's blueprint to GitHub Pages on each push to
  `main` that changes it.

## Building

Both projects need [elan](https://github.com/leanprover/elan), which installs the Lean version
pinned in `lean-toolchain` (v4.34.0). Neither uses Mathlib.

Run both from the repository root:

```sh
lake build                                              # the pilot
(cd exports/acl2-8.7-local-haiku-lean && lake build)    # the export
```

## Running the skill

The export was made with the skill in `skills/acl2-to-lean-ax/`. To run it, you need:

- Claude Code;
- an ACL2 books tree with `.cert` files, that is, certified books (a git clone of ACL2 has none
  until its books are certified);
- Python 3.10 or later (the scripts use only the standard library);
- elan.

Make the skill available to Claude Code by linking it into your skills directory, from the
repository root, then ask Claude Code to run `acl2-to-lean-ax` with the inputs below:

```sh
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/acl2-to-lean-ax" ~/.claude/skills/acl2-to-lean-ax
```

| Input | Meaning |
| --- | --- |
| `BOOKS` | The ACL2 books directory. |
| `PROJECT` | The Lean project to create. It must not be inside `BOOKS`. |
| `GITHUB` | The web address of the same books, for the blueprint's source links, for example `https://github.com/acl2/acl2/blob/8.7/books`. `SKILL.md` calls it optional, but `blueprint.py` requires it. |
| `--embedding shallow\|deep` | Required. `shallow`: ACL2 values become Lean values such as `Rat`, `CRat` (complex rationals), `Prop`, `List Rat` and `String`. `deep`: every ACL2 value is a value of one Lean type, `ACL2.V`. |
| `--model` | Optional. The model that writes the axioms: `sonnet`, `opus`, `haiku` or `fable`. By default, the model of the session. |
| `--check N\|converge` | The number of checking passes per module. Default: 1. |
| `--cert yes\|no` | Certified books only (the default), or every `.lisp` file. |
| `COPYRIGHT` | Optional. The translator's copyright line, which each module and page carries next to the book's. acl2Ax uses `Copyright (c) 2026, Beneficial AI Foundation`. |

The skill writes into `PROJECT`:

- `lakefile.toml`, `lean-toolchain`, and `Lean/ACL2/Base.lean` with the Lean meanings of the ACL2
  primitives;
- one module per book, `Lean/<book path>.lean`;
- `manifest.json`, with every book and its status;
- `ORDER.txt`, the books in dependency order;
- `EMBEDDING_DECISIONS.md`, with every deviation from the ACL2 source;
- `blueprint/`, with one page per book and an `index.html`;
- `NOTICE.md`, with the copyright and license file of each book, and `LICENSES/`, with the
  license texts of the books and of acl2Ax.

The export also keeps a run log, `RUN_LOG.md`. It records only the first run, which stopped at the
second book, with the model and the token use of that run.

The scripts are in `skills/acl2-to-lean-ax/scripts/`, and each one can also be run by hand:

| Step | Script | What it does |
| --- | --- | --- |
| 1 | `inventory.py` | Lists the books, writes `manifest.json`, and creates the module directories. |
| 2 | `scaffold.py` | Copies `Base.lean` and `EMBEDDING_DECISIONS.md` for the chosen embedding. |
| 3 | `order.py` | Writes the dependency order, `ORDER.txt`. |
| 4 | `licenses.py check`, the model, then `roots.py`, `check_axioms.py`, `check_deps.py`, `licenses.py apply` | The first script checks the book's license. The model writes each module. The scripts update `lakefile.toml`, compare axiom names with the book, check the module's imports, and add the book's copyright to the module and to `NOTICE.md`. |
| 5 | `blueprint.py`, `landing.py` | Write the blueprint pages and the index. |
| after | `usage.py` | Sums the token use of the run. |

`SKILL.md` gives the full procedure and the conventions.

## Current scope

As of November 2026 (commit a4e1961), with the ACL2 8.7 books and the shallow embedding:

- **Export.** 57 of the 1452 books in its manifest have a module: 46 with axioms, 3 that only import
  other books, and 8 for excluded books (7 metaprogramming, 1 non-standard analysis). Together they
  have 439 axioms. The books come from `arithmetic-2`, `arithmetic-3`, `std`, `kestrel`,
  `arithmetic`, `acl2s` and `misc`.
- **Pilot.** 38 axioms in 4 books from `books/arithmetic`.

## Planned work

[Issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1) lists the planned
improvements in five phases: documentation and cleanup, reading each book's theorems from ACL2
itself, a provenance record for each declaration, checks of the translations, and making the axioms
easier to use and to prove.

## License

acl2Ax is under the BSD 3-Clause license in `LICENSE`, Copyright (c) 2026, Beneficial AI Foundation.

The Lean modules and the blueprint pages translate or quote ACL2 books, so each keeps the copyright
and the license of its book. Every book translated so far is under a 3-clause BSD license. Each
module starts with a comment that gives the book's copyright line, the Beneficial AI Foundation's
line for the translation, and the license file. Each blueprint page shows the same lines and the
license text.

- `exports/acl2-8.7-local-haiku-lean/NOTICE.md` lists the books of the export, and `NOTICE.md` at
  the root the books of the pilot. `skills/acl2-to-lean-ax/scripts/licenses.py` writes both.
- `LICENSES/acl2/` holds copies of the ACL2 license files that these books use, at their paths in
  the ACL2 source tree. The export has its own copy, and also a copy of acl2Ax's license, because it
  starts from the skill's templates. `skills/acl2-to-lean-ax/LICENSE` is a copy of `LICENSE`, so the
  skill keeps its license when it is copied on its own.
- `tools/cert-checker/cl_symbols.h` lists Common Lisp symbols taken from ACL2's `axioms.lisp`, which
  is under the ACL2 license in `LICENSES/acl2/LICENSE`.

ACL2 sets licenses per directory and per file, and some ACL2 books are under other licenses, such as
the GPL. The skill therefore checks each book before it translates it. It accepts only the five
license texts reviewed so far, which `KNOWN_LICENSES` in `licenses.py` lists; a book under any other
text stops the run until someone reviews that text.
