// Type 9 — Redundant file: duplicates Button component with a different name.

export function PrimaryButton({ label, onClick }: { label: string; onClick: () => void }) {
  return <button className="btn" onClick={onClick}>{label}</button>;
}
