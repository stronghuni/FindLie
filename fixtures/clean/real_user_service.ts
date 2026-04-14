// Clean: real implementation of user-service operations.
// Must NOT trip Type 1 (no hardcoded users), Type 4 (conditional validation),
// Type 5 (saveUser actually calls db.insert).

import { db } from "./db";

export async function saveUser(user: { email: string; name: string }) {
  if (!user.email.includes("@")) {
    throw new Error("invalid email");
  }
  const result = await db.insert("users", user);
  return result.id;
}

export async function validateCredentials(email: string, password: string) {
  const row = await db.query("SELECT password_hash FROM users WHERE email = $1", [email]);
  if (!row) {
    return false;
  }
  if (row.password_hash !== password) {
    return false;
  }
  return true;
}
