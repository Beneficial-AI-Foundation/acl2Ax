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

- The repository holds one Lean project, the export in `exports/llm/`, made by the skill in `skills/acl2-to-lean-ax/`. `SKILL.md` gives the procedure and the conventions for the Lean axioms, and `exports/llm/EMBEDDING_DECISIONS.md` records every deviation from the ACL2 source.
- Each Lean project is a directory under `exports/`, named by how its Lean is produced: `llm` when a language model writes the axioms by following the skill. A project made another way, for example with ACL2Lean, goes beside it, as `exports/acl2lean/`.
- The status is kept in one place, the "Current scope" section of `README.md`. Update it there when a book is added.
- Planned work is tracked in [issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1).

## Commands

Run from the repository root.

- Build the export: `(cd exports/llm && lake build)`. The toolchain is pinned in `exports/llm/lean-toolchain` (v4.34.0, installed through elan). Do not run `lake update`.
- Check one module: `(cd exports/llm && lake env lean Lean/std/basic/nfix.lean)`.
- The scripts of the skill are in `skills/acl2-to-lean-ax/scripts/`. `SKILL.md` says when to run each one, and `README.md` lists them.
- Load a certificate read-only, to check that it matches its source: `(include-book "BOOKS/arithmetic/abs" :load-compiled-file nil)`, with `BOOKS` written out as an absolute path, piped into `ACL2/saved_acl2`, followed by `(good-bye)`. Run it from a scratch directory. This check does not replay proofs.
- Recertify a book, which replays proofs and overwrites the `.cert` file: `(certify-book "abs" ? t)` piped into `ACL2/saved_acl2` from inside `BOOKS/arithmetic`. Back up the `.cert` first. A copy of the books directory fails, because ACL2 requires the book at its installed path.

## Architecture

- `exports/llm/lakefile.toml` defines the library `ACL2AxLLM` with `srcDir = "Lean"`. `python3 skills/acl2-to-lean-ax/scripts/roots.py exports/llm ACL2AxLLM` writes its roots. Run it after adding a module, or `lake build` does not build it.
- `exports/llm/Lean/ACL2/Base.lean` holds the Lean meanings of the ACL2 primitives. `exports/llm/Lean/<book path>.lean` holds the axioms of one book, in the namespace `ACL2.<book path>`.
- `exports/llm/manifest.json` lists the 1452 certified books with a status for each.
- `exports/llm/blueprint/` holds one page per book and an `index.html`, made by `blueprint.py` and `landing.py`. `.github/workflows/pages.yml` publishes them to https://beneficial-ai-foundation.github.io/acl2Ax/ on each push to `main` that changes them.
- `tools/cert-checker/` and `tools/cert-checker-js/` hold integrity checkers for `.cert` files. Their READMEs give their status.
- `LICENSE` (BSD 3-Clause, Beneficial AI Foundation) covers acl2Ax's own files. The modules and the blueprint pages also keep the copyright and license of their ACL2 book: `exports/llm/NOTICE.md` lists them, `exports/llm/LICENSES/` holds the license texts, and `skills/acl2-to-lean-ax/scripts/licenses.py` writes both. `LICENSES/acl2/LICENSE` at the root is the license of ACL2's `axioms.lisp`, from which `tools/cert-checker/cl_symbols.h` is generated. `skills/acl2-to-lean-ax/LICENSE` is a copy of `LICENSE`; keep the two identical.
- `EMBEDDING_DECISIONS.md` is the record of deviations. It has three parts: general decisions, an interpretation table, and element decisions keyed by the ACL2 theorem name in `### name` headings.

## Embedding decisions

- The embedding is shallow. The user chose it.
- Each deviation is recorded in `EMBEDDING_DECISIONS.md`, and then shown in the blueprint. General decisions appear on the first page of the blueprint. Element decisions appear under their own theorem.
- Do not change the statement of an ACL2 theorem to suit a proof or a Lean convenience. Record any gap in `EMBEDDING_DECISIONS.md` and keep the ACL2 statement.

## Models

- Planning uses Fable 5.1. The generation of the axioms uses Haiku 5.5, as stated in the project goal.
