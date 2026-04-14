// Type 3 — No-op / silent failure

export async function saveRecord(data: unknown) {
  // Empty async function — declares intent but does nothing
  return;
}

export function handleClick() {
  try {
    JSON.parse("invalid");
  } catch (e) {}
}

export function onSubmit(event: Event) {
  // no-op handler
}
