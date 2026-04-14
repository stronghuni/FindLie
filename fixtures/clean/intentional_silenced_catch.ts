// Clean: catch block is intentionally empty with an explanatory comment.
// patterns.md Type 3 rule excludes `// intentional` and `// ignore` comments.

export function tryParseJson(raw: string): unknown | null {
  try {
    return JSON.parse(raw);
  } catch (e) {
    // intentional: caller treats null as "not JSON"
    return null;
  }
}
