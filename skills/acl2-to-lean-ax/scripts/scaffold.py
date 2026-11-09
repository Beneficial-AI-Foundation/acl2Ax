#!/usr/bin/env python3
"""Copy the templates for one embedding into a project.

Usage: scaffold.py <project-dir> --embedding shallow|deep

  shallow  Rat-valued Lean statements (assets/shallow). Mathlib may be used: add a
           [[require]] block to lakefile.toml by hand. roots.py keeps such blocks.
  deep     ACL2 values as a Lean type V (assets/deep).

Copies Lean/ACL2/Base.lean and EMBEDDING_DECISIONS.md. An existing file is not overwritten.
"""
import argparse
import pathlib
import shutil
import sys

SKILL = pathlib.Path(__file__).resolve().parents[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("--embedding", required=True, choices=["shallow", "deep"])
    a = ap.parse_args()
    project = pathlib.Path(a.project).resolve()
    src = SKILL / "assets" / a.embedding
    pairs = [
        (src / "Base.lean", project / "Lean" / "ACL2" / "Base.lean"),
        (src / "EMBEDDING_DECISIONS.md", project / "EMBEDDING_DECISIONS.md"),
    ]
    for s, d in pairs:
        if d.exists():
            sys.exit(f"exists, not overwritten: {d}")
    for s, d in pairs:
        d.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(s, d)
        print(f"copied {d}")
    (project / "EMBEDDING").write_text(a.embedding + "\n", encoding="utf-8")
    print(f"embedding: {a.embedding}")


if __name__ == "__main__":
    main()
