## General Coding Standards

<!-- Replace this entire file with YOUR language-specific conventions -->
<!-- This file is loaded by GitHub Copilot as coding instructions for the project -->

### Code Style
- Follow the existing codebase style — consistency over personal preference
- Use the project's formatter/linter configuration (`.editorconfig`, `.eslintrc`, `.prettierrc`)
- Prefer explicit over implicit (type annotations, return types, named parameters)

### Naming
- Files: match the project's existing naming convention (PascalCase, kebab-case, snake_case)
- Classes/types: PascalCase
- Functions/methods: camelCase or snake_case (match existing code)
- Constants: UPPER_SNAKE_CASE or PascalCase (match existing code)
- Private fields: prefix with `_` or use `#` (match existing code)

### Error Handling
- Handle errors explicitly — never silently swallow exceptions
- Use structured error types (not generic Error/Exception)
- Return meaningful error messages for API consumers
- Log errors with context (what operation, what input, what failed)

### Testing
- Write tests alongside implementation — not as an afterthought
- Test naming should describe the behavior, not the implementation
- Prefer integration tests over excessive mocking
- Every public API should have at least one happy-path and one error test

### Security
- Never hardcode secrets, API keys, or credentials
- Validate and sanitize all user input
- Use parameterized queries (never string concatenation for SQL/queries)
- Follow the principle of least privilege for auth/permissions
