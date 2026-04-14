// Type 7 — Test deception
// Note: filename uses .spec.ts so test-file detection scans it

describe("UserService", () => {
  it("validates", () => {
    expect(true).toBe(true);
  });

  it("returns something", () => {
    const result = getUser();
    expect(result).toBeDefined();
  });

  it.skip("handles errors", () => {
    // skipped — never runs
  });

  test.todo("implement later");
});
