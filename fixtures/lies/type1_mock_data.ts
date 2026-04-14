// Type 1 — Mock/Fake Data disguised as real implementation
// Expected detections: hardcoded array of objects, fake emails, Math.random as data source

export function getUsers() {
  const users = [
    { id: 1, name: "John Doe", email: "john@example.com" },
    { id: 2, name: "Jane Doe", email: "jane@example.com" },
    { id: 3, name: "Admin User", email: "admin@test.com" },
  ];
  return users;
}

export function getRandomPrice() {
  const price = Math.floor(Math.random() * 100);
  return price;
}

export function getProductDescription() {
  return "Lorem ipsum dolor sit amet, placeholder text for now.";
}
