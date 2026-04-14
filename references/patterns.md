# FindLie — Detection Patterns Reference

This file defines the grep/ripgrep patterns used by FindLie to detect lie code.
Each pattern includes the Type it maps to, severity, and false-positive exclusion rules.

---

## Type 1: Mock/Fake Data

### Hardcoded dummy data arrays
```
PATTERN: \[\s*\{\s*(id|name|email|username)\s*:\s*["']\w+["']
SEVERITY: CRITICAL (in src/) | INFO (in test/mock/seed/fixture/)
EXCLUDE: __test__, __mock__, fixture, seed, demo, storybook, .stories.
EXAMPLE_HIT: const users = [{ id: 1, name: "John Doe" }]
```

### Fake email/phone patterns
```
PATTERN: ["'](john|jane|test|user|admin|foo|bar)@(example|test|fake|dummy)\.(com|org|net)["']
SEVERITY: WARNING
EXCLUDE: test files, documentation
EXAMPLE_HIT: email: "john@example.com"
```

### Math.random as fake data source
```
PATTERN: Math\.(random|floor\(Math\.random)\(\).*(?:id|price|score|count|amount|total)
SEVERITY: WARNING
EXCLUDE: test files, randomization utilities
EXAMPLE_HIT: const price = Math.floor(Math.random() * 100)
```

### Lorem ipsum / placeholder text
```
PATTERN: lorem\s+ipsum|placeholder\s+text|dummy\s+text|sample\s+data
FLAGS: case-insensitive
SEVERITY: WARNING
EXCLUDE: test, README, documentation
```

---

## Type 2: Incomplete Implementation (Stub/Skeleton)

### TODO/FIXME/HACK markers
```
PATTERN: (TODO|FIXME|HACK|XXX|TEMP|TEMPORARY|PLACEHOLDER)\b
FLAGS: case-insensitive
SEVERITY: WARNING (TODO) | CRITICAL (HACK, TEMP in production code)
EXCLUDE: none — always report
```

### Not implemented errors
```
PATTERN: throw\s+new\s+(Error|NotImplementedError)\s*\(\s*["'](not\s+impl|todo|fixme|implement)
FLAGS: case-insensitive
SEVERITY: CRITICAL
```

### Empty function bodies
```
PATTERN_JS: (function|=>)\s*\{[\s\n]*\}
PATTERN_PY: def\s+\w+\([^)]*\)\s*:\s*\n\s+(pass|\.\.\.)\s*$
SEVERITY: CRITICAL (for named functions) | WARNING (for callbacks)
EXCLUDE: interface declarations, abstract methods
```

### Placeholder console output
```
PATTERN: console\.(log|warn|info|debug)\s*\(\s*["'](placeholder|dummy|fake|mock|temp|todo|fixme|not.?impl)
FLAGS: case-insensitive
SEVERITY: WARNING
```

---

## Type 3: No-op / Silent Failure

### Empty catch blocks
```
PATTERN_JS: catch\s*\([^)]*\)\s*\{\s*\}
PATTERN_PY: except(\s+\w+)?:\s*\n\s+pass\s*$
SEVERITY: CRITICAL
EXCLUDE: intentionally silenced with comment like // intentional, // ignore
```

### Empty async functions
```
PATTERN: async\s+(function\s+)?\w+\s*\([^)]*\)\s*\{[\s\n]*(return;?)?[\s\n]*\}
SEVERITY: CRITICAL
```

### No-op event handlers
```
PATTERN: on(Click|Change|Submit|Error|Load|Ready)\s*[=:]\s*(\(\)\s*=>|function\s*\(\))\s*\{[\s\n]*\}
SEVERITY: WARNING
```

---

## Type 4: Deceptive Returns

### Always-true validation
```
PATTERN: (validate|verify|check|isValid|isAuth|canAccess)\w*\s*\([^)]*\)\s*(\{|=>)\s*(return\s+true|true)
SEVERITY: CRITICAL
```

### Hardcoded success returns
```
PATTERN: return\s+(true|"success"|"ok"|200|\{\s*success:\s*true\s*\}|null)\s*;?\s*(//|$)
SEVERITY: WARNING (needs context — may be legitimate)
CONTEXT_CHECK: Look at function name; if it implies validation/check, upgrade to CRITICAL
```

### Ignored parameters
```
DESCRIPTION: Function accepts parameters but never references them in body
DETECTION: AST-based (not grep) — check param names vs body references
SEVERITY: WARNING
```

---

## Type 5: Intent Mismatch

### Send/notify functions without HTTP/SMTP
```
PATTERN: (function|const|async)\s+(send|notify|email|dispatch|publish|emit)\w*\s*[=(]
CHECK: Same file must contain fetch/axios/http/smtp/nodemailer/sgMail/twilio or equivalent
SEVERITY: CRITICAL if no external call found
```

### Save/persist functions without DB/file access
```
PATTERN: (function|const|async)\s+(save|store|persist|write|insert|update|upsert)\w*\s*[=(]
CHECK: Same file must contain prisma/knex/mongoose/sequelize/typeorm/fs/writeFile or equivalent
SEVERITY: CRITICAL if no storage access found
```

### Auth functions without actual verification
```
PATTERN: (function|const|async)\s+(auth|login|verify|authenticate|authorize)\w*\s*[=(]
CHECK: Must contain jwt/bcrypt/crypto/hash/token comparison/session
SEVERITY: CRITICAL if no verification found
```

### Delete/remove functions without actual deletion
```
PATTERN: (function|const|async)\s+(delete|remove|destroy|purge|drop)\w*\s*[=(]
CHECK: Must contain DELETE/remove/destroy/unlink/drop operation
SEVERITY: CRITICAL if no deletion found
```

---

## Type 6: Disconnected Integration

### Placeholder URLs
```
PATTERN: ["'](https?://)?(localhost:\d+|127\.0\.0\.1|example\.(com|org|net)|placeholder\.[a-z]{2,6}(/|["'])|your-?api\.|api\.test[/"']|fake-?api\.|dummy-?api\.|httpbin\.org)
SEVERITY: WARNING (localhost) | CRITICAL (example.com/placeholder.* in production config)
EXCLUDE: test files, documentation, development config
NOTE: The bare word "placeholder" is NOT a match — a TLD or path must follow
      (e.g., "placeholder.io/", "placeholder.com"). This prevents false positives
      on variable names like `const placeholders = [...]`.
```

### Empty/missing environment variables
```
PATTERN: process\.env\.\w+\s*\|\|\s*["']\s*["']
PATTERN_ALT: (getenv|os\.environ\.get)\s*\(\s*["']\w+["']\s*,\s*["']\s*["']\s*\)
SEVERITY: WARNING
```

### Unused imports
```
DESCRIPTION: Module imported but never referenced in file body
DETECTION: Extract import names, grep for usage in same file
SEVERITY: INFO (single) | WARNING (multiple in same file)
```

---

## Type 7: Test Deception

### Tautological assertions
```
PATTERN: expect\s*\(\s*(true|1|""|null|undefined)\s*\)\s*\.\s*(toBe|toEqual|toStrictEqual)\s*\(\s*(true|1|""|null|undefined)\s*\)
SEVERITY: CRITICAL
```

### Weak assertions only
```
PATTERN: expect\s*\([^)]+\)\s*\.\s*(toBeDefined|toBeTruthy|toBeFalsy)\s*\(\s*\)
SEVERITY: WARNING (if this is the ONLY assertion in a test case)
```

### Skipped tests
```
PATTERN: (it|test|describe)\.(skip|todo)\s*\(
PATTERN_ALT: x(it|test|describe)\s*\(
SEVERITY: WARNING
```

### Commented-out tests
```
PATTERN: //\s*(it|test|describe)\s*\(|/\*[\s\S]*?(it|test|describe)\s*\(
SEVERITY: WARNING
```

---

## Type 8: Duplicate Code

### Duplicate file detection — raw hash
```
METHOD: SHA-256 hash comparison of full file contents
COMMAND: find . -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.tsx" -o -name "*.jsx" | xargs shasum -a 256 | sort | uniq -D -w 64
SEVERITY: WARNING (identical files) | INFO (similar files > 80%)
LIMITATION: Misses files that differ only in identifiers (common agent pattern:
            same body, different function name).
```

### Duplicate file detection — normalized body hash
```
METHOD: Strip incidental differences, then SHA-256.
NORMALIZATION (applied in order):
  1. Delete pure-comment lines (// or #)
  2. Replace `function NAME`, `const NAME`, `class NAME`, `def NAME` with
     `function NAME`, `const NAME`, `class NAME`, `def NAME` — i.e. strip the
     identifier so `formatUserDate` and `formatOrderDate` normalize to the same
     token.
  3. Drop blank lines
  4. SHA-256 the result
COMMAND: sed -E -e '/^[[:space:]]*(\/\/|#)/d' \
                -e 's/(function|const|class|def)[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*/\1 NAME/g' \
                -e '/^[[:space:]]*$/d' <file> | shasum -a 256
SEVERITY: CRITICAL (agent context-loss duplicate) | WARNING (intentional parallel impls)
RATIONALE: Exact SHA matches catch lazy copy-paste; normalized SHA matches catch
           agent context loss where the same logic is re-implemented under a new
           name. The second case is the more common failure mode in AI-generated code.
```

### Duplicate code blocks (5+ lines)
```
METHOD: Sliding window tokenization with variable name normalization
DETECTION: Normalize whitespace, replace identifiers with placeholders, hash blocks
SEVERITY: WARNING (5-10 lines) | CRITICAL (20+ lines identical)
```

### Duplicate export names
```
COMMAND: rg "export\s+(function|const|class|type|interface)\s+(\w+)" --no-filename -o | sort | uniq -d
SEVERITY: WARNING
```

---

## Type 9: Redundant Files & Functions

### Same-name files in different directories
```
METHOD: Extract basenames, find duplicates
COMMAND: find . -name "*.ts" -o -name "*.tsx" | xargs -I{} basename {} | sort | uniq -d
SEVERITY: INFO (review needed)
```

### Similar file content (80%+ match)
```
METHOD: Normalized diff comparison of file pairs with similar names/sizes
SEVERITY: WARNING (80-95% similar) | CRITICAL (95%+ similar)
```

---

## Type 10: Dead Code

### Unreachable code after return
```
PATTERN_JS: return\s+[^;]+;\s*\n\s*[a-zA-Z]
PATTERN_PY: return\s+.*\n\s+[a-zA-Z]
SEVERITY: WARNING
EXCLUDE: switch/case fall-through
```

### Dead conditional branches
```
PATTERN: if\s*\(\s*(false|0|!1|null|undefined|"")\s*\)\s*\{
SEVERITY: WARNING
```

### Large commented-out code blocks
```
METHOD: Count consecutive comment lines (// or #)
THRESHOLD: 10 or more consecutive comment lines
SEVERITY: INFO
```

### Unused imports
```
METHOD: Extract imported symbols, check usage in file body
COMMAND: For each file, extract import names and grep for their usage
SEVERITY: INFO
```

### Orphan files (not imported anywhere)
```
METHOD: Build import graph, find unreferenced source files
EXCLUDE: Entry points (index, main, app, server), config files, scripts, test files
SEVERITY: WARNING
PRECONDITION: Project must have ≥1 canonical entry point (index/main/app/server
              or a framework routes directory). If none exists — e.g. a flat
              library of standalone scripts — skip this check and emit a single
              INFO finding instead. Without an entry point, every file would
              appear orphan, drowning the report in false positives.
```

### Files with deprecated/old prefixes
```
PATTERN_FILENAME: (old_|backup_|_deprecated|_old|\.bak$|\.orig$|\.backup$|copy_of_|~$)
SEVERITY: WARNING
```
