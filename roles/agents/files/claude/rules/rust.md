---
paths:
  - "**/*.rs"
  - "Cargo.toml"
---
# Rust

- Follow clippy suggestions. Run `cargo clippy` before committing.
- Prefer `.expect("reason")` over `.unwrap()` with a meaningful message.
- Use `thiserror` for library error types, `anyhow` for applications.
