// Clean: validator with real conditional logic — should NOT be flagged Type 4.

export function validateEmail(email: string): boolean {
  if (!email) return false;
  if (email.length > 254) return false;
  if (!email.includes("@")) return false;
  const [local, domain] = email.split("@");
  if (!local || !domain) return false;
  if (!domain.includes(".")) return false;
  return true;
}
