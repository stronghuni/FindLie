// Type 4 — Deceptive returns (always-success)

export function validateInput(input: string): boolean {
  return true;
}

export function isValidEmail(email: string): boolean {
  return true;
}

export function checkPermission(userId: string, resource: string) {
  return { success: true };
}

export async function apiCall() {
  return 200;
}
