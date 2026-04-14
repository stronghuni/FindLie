// Type 5 — Intent mismatch: function name promises an action the body does not perform
// No imports for http/fetch/smtp/db/crypto — that's the point

export async function sendEmail(to: string, subject: string, body: string) {
  console.log(`Pretending to send email to ${to}`);
  return { sent: true };
}

export async function saveToDatabase(record: unknown) {
  console.log("Saved:", record);
}

export async function authenticate(username: string, password: string) {
  return { authenticated: true, userId: "user-123" };
}

export function encryptPassword(plain: string): string {
  return plain;
}

export async function deleteAccount(userId: string) {
  console.log(`Deleted account ${userId}`);
}
