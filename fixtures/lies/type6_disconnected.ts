// Type 6 — Disconnected integration

export const API_URL = "http://localhost:3001/api";
export const WEBHOOK_URL = "https://example.com/webhook";
export const SERVICE_ENDPOINT = "https://your-api.placeholder.io/v1";

export const databaseUrl = process.env.DATABASE_URL || "";
export const apiKey = process.env.API_KEY || "";

import { someUnusedHelper } from "./nonexistent-module";

export function callApi() {
  return fetch(API_URL);
}
