#!/usr/bin/env python3
"""Write lakefile.toml with one library whose roots are the Lean modules that exist.

Usage: roots.py <project-dir> [library-name]

[[require]] blocks already in lakefile.toml are kept.
Every Lean/**/*.lean file becomes a root, named by its path below Lean/ with dots.
Path components that contain a hyphen are quoted with guillemets, as Lean requires.
The library name defaults to the project directory name without characters that are not
letters or digits. Run this after each batch of generated modules.
"""
import pathlib
import re
import sys


def main() -> None:
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    project = pathlib.Path(sys.argv[1]).resolve()
    lean = project / "Lean"
    default = re.sub(r"[^A-Za-z0-9]", "", project.name) or "Axioms"
    name = sys.argv[2] if len(sys.argv) == 3 else default
    def part(x):
        # A component with a hyphen is not an identifier, so it is quoted with guillemets.
        return f"«{x}»" if "-" in x else x

    roots = sorted(
        ".".join(part(x) for x in p.relative_to(lean).with_suffix("").parts)
        for p in lean.rglob("*.lean")
    )
    roots_toml = ", ".join(f'"{r}"' for r in roots)
    # Keep any [[require]] blocks that were added by hand, for example Mathlib.
    old = project / "lakefile.toml"
    requires = ""
    if old.is_file():
        old_text = old.read_text(encoding="utf-8")
        blocks = old_text.split("[[require]]")[1:]
        requires = "".join("\n[[require]]" + b.rstrip() + "\n" for b in blocks)
    text = (
        f'name = "{name}"\n'
        'version = "0.1.0"\n'
        f'defaultTargets = ["{name}"]\n\n'
        '[[lean_lib]]\n'
        f'name = "{name}"\n'
        'srcDir = "Lean"\n'
        f"roots = [{roots_toml}]\n"
    ) + requires
    (project / "lakefile.toml").write_text(text, encoding="utf-8")
    print(f"lakefile.toml with {len(roots)} roots")


if __name__ == "__main__":
    main()
