---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript

- Prefer strict TypeScript. Avoid `any` unless genuinely unavoidable (and document why).
- Use discriminated unions over optional fields when modeling state.
- Use explicit return types on exported functions.
- Prefer `const` assertions and `as const` where applicable.
