# Contributing to acl2Ax

Thanks for your interest in contributing. acl2Ax turns the theorems of certified
ACL2 books into Lean 4 axioms: each book becomes one Lean module with one
`axiom` per theorem, plus an HTML blueprint page. This guide covers how to build
and check it, the trust model, and how to send a change. It follows the shared
contribution standard used across the
[Beneficial AI Foundation](https://github.com/Beneficial-AI-Foundation) Lean
projects.

acl2Ax is a prototype; see [issue 1](https://github.com/Beneficial-AI-Foundation/acl2Ax/issues/1)
for planned work.

## Prerequisites

- [`elan`](https://github.com/leanprover/elan), the Lean toolchain manager. It
  reads `exports/llm/lean-toolchain` and fetches the exact Lean/Lake version
  used, so you don't install Lean by hand:

  ```sh
  curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
  ```

  The Lean library has no dependencies (no Mathlib), so nothing else is needed to
  build it.
- **Python 3** — for the generation pipeline: the scripts under
  `skills/acl2-to-lean-ax/scripts/` (scaffolding, axiom/name checks, blueprint
  rendering, licences) and `tools/cert-checker/gen_cl_symbols.py`.
- **A C compiler** (e.g. `clang`) and optionally **Node.js** — only for the ACL2
  certificate checkers in `tools/cert-checker/` (C, built natively) and
  `tools/cert-checker-js/` (Node). These are independent of the Lean build.

## Building

```sh
cd exports/llm
lake build            # type-check the whole axiom library (ACL2AxLLM)
```

The certificate checkers build on their own:

```sh
cd tools/cert-checker
clang -std=c99 -O2 -o cert_check_native native_main.c cert_check.c
```

## Testing

There is no separate test suite: `lake build` is the check — it verifies that
every axiom and definition in the export is well typed. In addition:

- The axiom names of a module must match the theorem names of its ACL2 book
  (`skills/acl2-to-lean-ax/scripts/check_axioms.py`).
- The certificate checkers compare a `.cert` file with its book (hashes, lengths
  and write dates) **without replaying proofs** — see
  `tools/cert-checker/README.md`.

CI (`.github/workflows/ci.yml`) runs `lake build` on the export on Linux and
macOS for every push and pull request. The Python pipeline and the certificate
checkers are not run in CI (the pipeline regenerates committed output and the
checkers need an ACL2 `books` tree); run them locally when you touch them.

## Axioms, not proofs

acl2Ax proves nothing in Lean: each ACL2 theorem becomes a Lean `axiom`, and each
ACL2 function an `opaque` constant. `lake build` checks only that the statements
are well typed, not that they mean the same as their ACL2 source. Every place a
Lean statement departs from its ACL2 source is recorded in
`exports/llm/EMBEDDING_DECISIONS.md`; keep that file in step with any change to a
statement or to the ACL2 primitive definitions in `exports/llm/Lean/ACL2/Base.lean`.
A new or changed axiom should follow the conventions in
`skills/acl2-to-lean-ax/SKILL.md`, and each module and blueprint page must keep
its book's copyright and licence (`exports/llm/NOTICE.md`,
`exports/llm/LICENSES/`).

## Submitting a change

1. **Branch** off `main` (or fork the repository).
2. Keep each pull request focused.
3. Make sure `lake build` passes in `exports/llm`, that axiom names still match
   (`check_axioms.py`), and that CI is green.
4. Write a clear PR description: what changed, why, and how you verified it.
5. By contributing, you agree your contribution is licensed under this
   repository's license (see `LICENSE`, 3-clause BSD), and you certify the
   [Developer Certificate of Origin](https://developercertificate.org/) — add a
   `Signed-off-by: Your Name <you@example.com>` line to your commits
   (`git commit -s`).

## Reporting issues

Open a GitHub issue with a clear title, what you expected and what happened, and
the book or module that reproduces it. Security-sensitive reports can be sent
privately to **support@beneficialaifoundation.org** instead of a public issue.

## Code of conduct

Be respectful and constructive. Harassment or abuse is not tolerated. Maintainers
may remove comments, commits or contributions that don't meet this standard.
