// Clean: a standalone utility in a flat library without any entry point.
// The orphan-file check's precondition (entry-point existence) must suppress
// the orphan warning here. Regression guard for the FP where every file in a
// flat project was flagged as orphan.

export function add(a: number, b: number): number {
  return a + b;
}
