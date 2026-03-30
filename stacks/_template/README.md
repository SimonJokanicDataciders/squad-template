# Creating a New Stack Preset

This directory is a blank template for creating stack-specific presets.

## Steps

1. **Copy this directory** to `stacks/{your-stack-name}/` (e.g., `stacks/node-react/`)

2. **Fill in agent charters** (`agents/*.charter.md`):
   - Replace `<!-- TODO -->` comments with your actual conventions
   - Add your stack-specific guardrails, anti-patterns, and skill loading protocols
   - Reference your project's reference implementation

3. **Write skill bundles** (`skills/*.md`):
   - `role-backend-core.md` — Your backend language/framework conventions
   - `role-frontend-core.md` — Your frontend framework conventions
   - `role-qa-core.md` — Your testing framework and patterns
   - `failure-patterns.md` — Start empty, add as you discover failures

4. **Customize routing** (`routing.md`):
   - Replace `{Name}` placeholders with your agent cast names
   - Add or remove work types for your stack

5. **Customize ceremonies** (`ceremonies.md`):
   - Add project-specific trigger conditions
   - Adjust thresholds (file count, line count)

6. **Add coding instructions** (`instructions/`):
   - Language-specific coding standards for Copilot

## What Makes a Good Skill Bundle

The difference between generic and effective:

**Generic (useless):** "Follow best practices for error handling"
**Effective:** "All endpoint handlers wrap async operations in try/catch. Catch specific exceptions first (ValidationException → 400, NotFoundException → 404), then catch Exception → 500 with structured logging via ILogger."

Embed actual patterns, not advice. Include code examples from your reference implementation.
