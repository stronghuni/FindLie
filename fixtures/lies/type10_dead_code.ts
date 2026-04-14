// Type 10 — Dead code: unreachable branches, dead conditionals, unused exports

import { readFileSync } from "fs";

export function processData(data: number[]) {
  if (false) {
    console.log("never runs");
  }

  for (const item of data) {
    if (item < 0) return;
    console.log(item);
  }

  console.log("unreachable after the loop's early return pattern");
}

// Large commented-out block (10+ lines)
// const oldImplementation = () => {
//   const x = 1;
//   const y = 2;
//   const z = x + y;
//   console.log(z);
//   const a = 3;
//   const b = 4;
//   const c = a * b;
//   return c;
//   // leftover from previous refactor
// };

export function calculateTax(amount: number): number {
  return amount * 0.1;
}
