---
description: Git workflow, commit conventions, and PR process
---

# Git Workflow

## Conventional Commits

Every commit message must follow the format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Commit Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature or capability | `feat(auth): add OAuth2 login flow` |
| `fix` | Bug fix | `fix(orders): correct tax calculation for EU` |
| `refactor` | Code restructuring, no behavior change | `refactor(api): extract validation middleware` |
| `docs` | Documentation only | `docs(readme): add deployment instructions` |
| `test` | Adding or updating tests | `test(users): add integration tests for signup` |
| `chore` | Tooling, config, dependencies | `chore(deps): upgrade xUnit to 2.8` |
| `perf` | Performance improvement | `perf(queries): add index for order lookups` |
| `ci` | CI/CD pipeline changes | `ci(github): add staging deploy workflow` |

### Rules

- Type and scope are lowercase
- Description starts with lowercase verb in imperative mood ("add", not "added" or "adds")
- Description is under 72 characters
- Scope is the module or feature area affected
- Body explains WHY, not WHAT (the diff shows what)
- Breaking changes use `!` after type: `feat(api)!: change response format`

```
WRONG:
  "Fixed bug"
  "WIP"
  "update stuff"
  "Changes to user service"

CORRECT:
  "fix(cart): prevent negative quantity on line items"
  "feat(notifications): add email digest for weekly summary"
  "refactor(auth): replace custom JWT parsing with library"
```

## Branch Naming

```
feature/<ticket-id>-short-description
fix/<ticket-id>-short-description
refactor/<ticket-id>-short-description
chore/<ticket-id>-short-description
```

Examples:
```
feature/PROJ-123-user-registration
fix/PROJ-456-cart-total-rounding
refactor/PROJ-789-extract-payment-service
```

## Pull Request Process

### Creating a PR

1. Analyze the FULL diff from the base branch — not just the latest commit
2. Title follows conventional commit format: `feat(scope): description`
3. Description includes:
   - Summary of changes (1-3 bullet points)
   - Test plan with specific verification steps
   - Link to related ticket/issue

### Reviewing a PR

1. Read the full diff, not just changed files individually
2. Check for:
   - Security checklist compliance
   - Test coverage for new/changed code
   - Consistent naming and patterns
   - No TODO comments without linked tickets
   - No commented-out code
3. Approve only when all checks pass

### PR Size

| Metric | Target | Maximum |
|--------|--------|---------|
| Files changed | 1-10 | 20 |
| Lines changed | 50-200 | 500 |

PRs over 500 lines should be split. Large PRs get superficial reviews.

## Merging

- Squash merge feature branches to keep main history clean
- Delete the branch after merge
- Never force-push to main/master
- Ensure CI passes before merge — no exceptions
