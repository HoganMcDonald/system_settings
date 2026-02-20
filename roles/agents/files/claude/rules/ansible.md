---
paths:
  - "**/tasks/*.yml"
  - "**/defaults/*.yml"
  - "dotfiles.yml"
---
# Ansible

- Use YAML syntax, not key=value for module parameters.
- Use `creates` / `removes` for idempotency in shell/command tasks.
- Define variables in roles/*/defaults/main.yml.
- Use tags on every role for selective execution.
