// Type 9 — Redundant file: identical to type9_redundant_primary_button.tsx
// (both export the same component under different names)

export function Button({ label, onClick }: { label: string; onClick: () => void }) {
  return <button className="btn" onClick={onClick}>{label}</button>;
}
