// Clean: a variable literally named "placeholders" must NOT trip the T6
// placeholder-URL rule. Regression guard for the FP discovered during
// end-to-end testing on 2026-04-14 where db.ts had `const placeholders = ...`.

export function buildInsertSql(table: string, row: Record<string, unknown>) {
  const keys = Object.keys(row);
  const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
  return `INSERT INTO ${table} (${keys.join(", ")}) VALUES (${placeholders})`;
}
