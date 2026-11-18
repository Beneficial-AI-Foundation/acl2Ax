# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project goal

This project is a prototype that creates Lean axioms for every theorem in ACL2.

- ACL2 source: the `books` directory of ACL2 8.7, called `BOOKS` below. `ACL2` below is the ACL2 directory that holds `saved_acl2`. Both can be anywhere.
- There must be created the same directory structure that is used in the ACL2 source books directory.
- A book is a .lisp file with a matching .cert file. Use the .acl2 files only for settings, includes and namespacing.
- The Verso/Blueprint may link to the source .lisp files. The Lean axioms must represent the ACL2 code.
- Use Fable 5.1 to plan this and Haiku 5.5 model.
- Create a mechanism that saves the progress of the generation such that after each book is transformed a claude /clear command can be run, the assignment and progress reloaded, and then move to the next book.
- The deliverables are the Lean module structure  with the axioms and a Verso/Blueprint document for the formalization.
- The Lean axioms must reflect every theorem and lemma in the .lisp book files, one axiom per ACL2 theorem or lemma.

## Scope and status

- The repository holds two Lean projects. The pilot is the project at the repository root: four books from `books/arithmetic`, written with the conventions in this file. The export is the project in `exports/acl2-8.7-local-haiku-lean/`, made by the skill in `skills/acl2-to-lean-ax/`. `README.md` compares the two.
- The status is kept in one place, the "Current scope" section of `README.md`. Update it there when a book is added.
- Planned work is tracked in [issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1).

## Commands

Run from the repository root.

- Build the Lean project at the root (the four pilot books): `lake build`. It does not build the export. The toolchain is pinned in `lean-toolchain` (v4.34.0, installed through elan). Do not run `lake update`.
- Build the export: `(cd exports/acl2-8.7-local-haiku-lean && lake build)`.
- Check one module: `lake env lean Lean/arithmetic/abs.lean`.
- Regenerate the blueprint for abs: `python3 tools/blueprint/build_blueprint.py abs`. It writes `tools/blueprint/abs-blueprint.html`. It reads the books from the path in `ACL2_BOOKS` at the top of the script, so set that path for the machine first.
- Load a certificate read-only, to check that it matches its source: `(include-book "BOOKS/arithmetic/abs" :load-compiled-file nil)`, with `BOOKS` written out as an absolute path, piped into `ACL2/saved_acl2`, followed by `(good-bye)`. Run it from a scratch directory. This check does not replay proofs.
- Recertify a book, which replays proofs and overwrites the `.cert` file: `(certify-book "abs" ? t)` piped into `ACL2/saved_acl2` from inside `BOOKS/arithmetic`. Back up the `.cert` first. A copy of the books directory fails, because ACL2 requires the book at its installed path.

## Blueprint page

- These rules are for the pilot's pages in `tools/blueprint/`. The export's pages are in `exports/acl2-8.7-local-haiku-lean/blueprint/`, made by `skills/acl2-to-lean-ax/scripts/blueprint.py`, and `.github/workflows/pages.yml` publishes them to https://beneficial-ai-foundation.github.io/acl2Ax/ on each push to `main` that changes them.
- The pilot's abs blueprint is published as an Artifact at `https://claude.ai/artifact/Y2aghL3pVRjDJKuGbVKiAw`. Publish the same file path again to update that URL, and never create a new artifact for it.
- The page has these parts, in this order:
  1. A status row with the book, the axiom count, the embedding, the ACL2 certification and the Lean build.
  2. A collapsible general embedding decisions section, taken from `EMBEDDING_DECISIONS.md`.
  3. The four support definitions, linked to `axioms.lisp` at tag 8.7.
  4. One section per axiom, with the ACL2 `defthm` source, the Lean `axiom`, a link to the GitHub line at tag 8.7, and a collapsible block of that element's decisions.
  5. A collapsible block with the full certificate, as an xxd hex dump, because the `.cert` file is binary.
- The source links point to the GitHub tag `8.7` of `acl2/acl2`. That copy of `abs.lisp` is identical to the local one. The GitHub repository tracks no `.cert` files, so the certificate is embedded instead of linked.
- Backticks in the decisions text render as code elements.

## Architecture

- The export is a separate Lake project. It follows `skills/acl2-to-lean-ax/SKILL.md` and its own `EMBEDDING_DECISIONS.md`, not the conventions below.
- `Lean/ACL2/Base.lean` holds the shallow interpretation of the ACL2 primitives used by the pilot books. It defines `realrationalp`, `acl2NumberP`, `rationalp`, `rationalListp`, `integerp`, `zp`, `fix`, `nfix`, `abs`, `exptInt` and `expt` over `Rat`. It sits outside the mirror of the books tree, and `EMBEDDING_DECISIONS.md` records this.
- `Lean/<book dir>/<book>.lean` holds the axioms for one ACL2 book, at the same path as the book under `BOOKS`. The pilot has four modules: `abs`, `binomial`, `factorial` and `sumlist`, in `Lean/arithmetic/`.
- `lakefile.toml` defines the library `ACL2Ax` with `srcDir = "Lean"` and the roots `ACL2.Base`, `arithmetic.abs`, `arithmetic.factorial`, `arithmetic.sumlist` and `arithmetic.binomial`. Add each new module to `roots`, or `lake build` does not build it.
- `manifest.json` lists the 1452 certified books with a status for each. Update the status of a book after its axioms build.
- `mappings/arithmetic.json` records, for each arithmetic book, its package, its Lean namespace, its Lean file, and its `include-book` targets with the `local` flag. The package of every arithmetic book is `ACL2`, so the Lean namespace is `ACL2`.
- `tools/cert-checker/` and `tools/cert-checker-js/` hold integrity checkers for `.cert` files. Their READMEs give their status.
- `EMBEDDING_DECISIONS.md` is the record of deviations. It has three parts: general decisions, an interpretation table, and element decisions keyed by the ACL2 theorem name in `### name` headings.

## Conventions for the Lean axioms

These are the pilot's conventions. The export follows `skills/acl2-to-lean-ax/SKILL.md`.

- Each `defthm` becomes one `axiom`, in the file for its book, inside `namespace ACL2`.
- ACL2 names are kept verbatim, with guillemets, for example `«abs-*»`.
- Variables range over `Rat`. Hypotheses such as `real/rationalp x` stay in the statement, and `realrationalp` is `True` on `Rat`.
- An ACL2 theorem without hypotheses is stated over `Rat` only, and `EMBEDDING_DECISIONS.md` records this.
- `:rule-classes`, hints and proofs are not represented.
- Every new interpretation of an ACL2 primitive goes into `Lean/ACL2/Base.lean`, into the interpretation table, and into the element decisions of each theorem that uses it.

## Embedding decisions

- The embedding is shallow. The user chose it.
- Each deviation is recorded in `EMBEDDING_DECISIONS.md`, and then shown in the blueprint. General decisions appear on the first page of the blueprint. Element decisions appear under their own theorem.
- Do not change the statement of an ACL2 theorem to suit a proof or a Lean convenience. Record any gap in `EMBEDDING_DECISIONS.md` and keep the ACL2 statement.

## Process used so far

1. Inventory: list every `.cert` file under `books`, and keep the `.lisp` file that shares its name. This gives 1452 books. Write `manifest.json` with status `pending` for each.
2. Mirror: create a directory under `Lean/` for every book directory in the manifest. Keep the ACL2 spelling, including hyphens.
3. Namespaces: read the `in-package` and `include-book` forms of each book, skipping forms inside block comments and escaped strings. Write `mappings/<dir>.json`.
4. Axioms: for each book, emit one `axiom` per `defthm`, add the interpretations to `Lean/ACL2/Base.lean`, record the deviations, then run `lake build`.

The steps 3 and 4 for abs were written by hand after reading the source. The skill in `skills/acl2-to-lean-ax/` now has scripts for the inventory, the dependency order, the lakefile roots and the checks, and a model writes the axioms of step 4 by following `SKILL.md`. A new book must follow the same pattern, and the mapping and the axiom file must be checked against the ACL2 source.

## Models

- Planning uses Fable 5.1. The generation of the axioms uses Haiku 5.5, as stated in the project goal.
