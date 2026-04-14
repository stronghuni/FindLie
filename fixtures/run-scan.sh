#!/bin/bash
# FindLie — fixture regression harness
# Verifies that detection patterns hit every lies/ fixture and miss every clean/ fixture.
# Uses grep -E (POSIX ERE) for maximum portability — no ripgrep dependency.

set -u
cd "$(dirname "$0")"

LIES_DIR="lies"
CLEAN_DIR="clean"
FAIL=0
PASS=0

# --- Pattern registry -------------------------------------------------------
# Each entry: "TYPE_ID|LIE_FILE|PATTERN"
# PATTERN is POSIX ERE. Must match at least once in LIE_FILE.
PATTERNS=(
  # Type 1: Mock/Fake Data
  "T1|type1_mock_data.ts|\\[[[:space:]]*\\{[[:space:]]*id[[:space:]]*:[[:space:]]*[0-9]"
  "T1|type1_mock_data.ts|(john|jane|admin)@(example|test|fake)\\."
  "T1|type1_mock_data.ts|[Ll]orem [Ii]psum"
  # Type 2: Stubs, TODOs, not-implemented
  "T2|type2_stub.ts|(TODO|FIXME|HACK)"
  "T2|type2_stub.ts|throw new Error\\(\"Not implemented"
  "T2|type2_stub.ts|console\\.log\\(\"placeholder"
  # Type 3: Empty catch, empty async, no-op handlers
  "T3|type3_noop.ts|catch[[:space:]]*\\([^)]*\\)[[:space:]]*\\{[[:space:]]*\\}"
  "T3|type3_noop.ts|async function saveRecord"
  # Type 4: Always-true validators
  "T4|type4_deceptive_return.ts|validateInput[^{]*\\{[[:space:]]*return true"
  "T4|type4_deceptive_return.ts|isValidEmail[^{]*\\{[[:space:]]*return true"
  # Type 5: Intent mismatch (name promises, body lies)
  "T5|type5_intent_mismatch.ts|sendEmail"
  "T5|type5_intent_mismatch.ts|saveToDatabase"
  "T5|type5_intent_mismatch.ts|encryptPassword"
  # Type 6: Disconnected integration
  "T6|type6_disconnected.ts|(localhost:[0-9]+|example\\.com|placeholder)"
  "T6|type6_disconnected.ts|process\\.env\\.[A-Z_]+[[:space:]]*\\|\\|[[:space:]]*\"\""
  # Type 7: Test deception
  "T7|type7_test_deception.spec.ts|expect\\(true\\)\\.toBe\\(true\\)"
  "T7|type7_test_deception.spec.ts|(it|test)\\.(skip|todo)"
  "T7|type7_test_deception.spec.ts|toBeDefined"
  # Type 8: Duplicate code block signature present in both files
  "T8|type8_duplicate_block_a.ts|padStart\\(2, \"0\"\\)"
  "T8|type8_duplicate_block_b.ts|padStart\\(2, \"0\"\\)"
  # Type 9: Redundant component shape
  "T9|type9_redundant_button.tsx|<button className=\"btn\""
  "T9|type9_redundant_primary_button.tsx|<button className=\"btn\""
  # Type 10: Dead branches + deprecated filenames
  "T10|type10_dead_code.ts|if[[:space:]]*\\([[:space:]]*false[[:space:]]*\\)"
  "T10|old_deprecated_helper.ts|legacyHelper"
)

# --- False-positive guards --------------------------------------------------
# Each pattern must match ZERO times across clean/ (after excludes).
# Format: "LABEL|PATTERN"
CLEAN_NEGATIVES=(
  "empty_catch|catch[[:space:]]*\\([^)]*\\)[[:space:]]*\\{[[:space:]]*\\}"
  "always_true_validator|(validate|verify|check|isValid)[a-zA-Z]*[[:space:]]*\\([^)]*\\)[[:space:]]*:[[:space:]]*boolean[[:space:]]*\\{[[:space:]]*return true"
  "todo_marker|(TODO|FIXME|HACK|XXX)"
  "placeholder_url|(localhost:[0-9]+|example\\.com|placeholder)"
)

# Files in clean/ that are legitimately exempt from certain rules
# (seed data, test files — mirrors the SKILL's runtime exclusions).
CLEAN_EXCLUDE_GREP_ARGS=(
  --exclude=*.seed.*
  --exclude=*.test.*
  --exclude=*.spec.*
  --exclude=fixture_*
)

echo "═══ FindLie fixture regression harness ═══"
echo ""

# --- Positive checks --------------------------------------------------------
echo "[positive] lies/ — each pattern must match:"
for entry in "${PATTERNS[@]}"; do
  IFS='|' read -r TYPE FILE PAT <<< "$entry"
  TARGET="$LIES_DIR/$FILE"
  if [ ! -f "$TARGET" ]; then
    echo "  ✗ $TYPE $FILE :: fixture missing"
    FAIL=$((FAIL + 1))
    continue
  fi
  if grep -Ezq "$PAT" "$TARGET" 2>/dev/null; then
    SHORT=$(printf '%s' "$PAT" | cut -c1-48)
    echo "  ✓ $TYPE $FILE :: $SHORT"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $TYPE $FILE :: did NOT match — $PAT"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "[negative] clean/ — patterns must match ZERO times:"
for entry in "${CLEAN_NEGATIVES[@]}"; do
  IFS='|' read -r LABEL PAT <<< "$entry"
  # Count matching lines across clean/, excluding seed/test files
  # -z makes grep treat each file as one record, enabling multi-line matches.
  # We count files that match at least once, not line hits.
  HITS=$(grep -Erlz "${CLEAN_EXCLUDE_GREP_ARGS[@]}" "$PAT" "$CLEAN_DIR" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$HITS" = "0" ]; then
    echo "  ✓ $LABEL :: 0 hits"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $LABEL :: $HITS file(s) match — rule over-matches"
    grep -Erlz "${CLEAN_EXCLUDE_GREP_ARGS[@]}" "$PAT" "$CLEAN_DIR" 2>/dev/null | sed 's/^/      /'
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "═══ Summary ═══"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
