# FindLie — Regression Fixtures

These fixtures exist so that changes to `references/patterns.md` can be verified
without running the skill against a real codebase.

## Structure

- `lies/` — one file per Type (1–10). Each file contains a clear positive example
  the detection patterns must catch. A fixture is considered passing if at least
  one pattern from its Type emits a match.
- `clean/` — negative samples. These represent the common false-positive cases
  that have historically tripped lie-detection tools: barrel re-exports, Python
  abstract methods (`pass`), intentionally silenced catches with explanatory
  comments, seed/fixture data files, and real validators with branching logic.
  Every file in `clean/` must produce **zero** matches from any pattern.

## Running the harness

```bash
./fixtures/run-scan.sh
```

Exits 0 if all lies are detected and all clean files are silent; non-zero otherwise.

## Adding a fixture

- **New lie type:** add `fixtures/lies/typeN_<short_name>.<ext>`. Keep each file
  focused on a single Type so detection-rate reporting stays readable.
- **New false-positive case:** add `fixtures/clean/<descriptive_name>.<ext>` and
  add a one-line comment at the top explaining *why* it must not be flagged.

## Caveats

- These fixtures do **not** exercise duplicate-file SHA-256 detection across the
  full project (Type 8/9 inter-file checks) — that requires the skill's runtime
  logic. The fixtures verify single-file pattern hits only.
- Python fixtures are sparse; most patterns target JS/TS. PRs welcome.
