# Customization Guide

How to create a stack preset for your project's tech stack.

## Estimated Effort

| Component | Time | Reusability |
|-----------|------|-------------|
| Run init.sh | 1 min | Copy |
| Analyze your codebase | 1-2h | Document once |
| Write agent charters (4-6) | 2-3h | Per project |
| Write skill bundles (4-8) | 3-5h | Per stack (reuse across projects) |
| Customize routing + ceremonies | 30 min | ~70% copy |
| First benchmark + fixes | 1-2h | Pay once |
| **Total** | **8-12h** | **Amortizes at 3-4 features** |

## Step 1: Identify Your Reference Implementation

Find the best-documented, most complete feature in your codebase. This becomes the pattern all agents follow. It should demonstrate:

- Entity/model definition
- Service/business logic
- API endpoint/route
- Tests (unit + integration)
- Database migration (if applicable)

**Example:** CAP Template uses `WeatherForecasts` — a complete slice from entity to endpoint to tests.

## Step 2: Write Agent Charters

Copy from `stacks/_template/agents/` and fill in:

### What Makes a Good Charter

**Bad (generic):**
```
## Responsibilities
- Collaborate with team members
- Maintain code quality
```

**Good (embedded knowledge):**
```
## Guardrails
### Code Conventions
- All classes are sealed by default unless abstract
- Immutable DTOs: `sealed record` with `init` properties
- Null checks: ALWAYS `is null` / `is not null` (never `== null`)
- XML docs on ALL public APIs

### What NEVER to Do
- NEVER manually edit migration files
- NEVER add endpoint handlers without registering routes
```

### Key Charter Sections

1. **Project Context** — stack, primary bundle path, reference implementation path
2. **Responsibilities** — 3-5 bullet points of what the agent owns
3. **Guardrails** — concrete coding conventions + what NEVER to do
4. **Skill Loading Protocol** — which bundles to read and when
5. **Work Style** — communication and collaboration rules

## Step 3: Write Skill Bundles

Skill bundles are NOT generic best practices. They are **project-specific embedded knowledge**.

### Structure

```markdown
---
name: "role-backend-core"
description: "Core conventions for backend development"
domain: "backend"
confidence: "medium"
source: "manual"
---

# Backend Developer — Core Skill Bundle

## Project Structure
{Your actual directory layout}

## Code Conventions
{Your actual coding rules with examples}

## Entity Pattern
{How entities look in YOUR project, with code}

## Service Pattern
{How services look in YOUR project, with code}

## Endpoint Pattern
{How endpoints look in YOUR project, with code}

## Implementation Checklist
- [ ] {Your actual verification steps}
```

### Tiered Loading

Split knowledge into:

1. **Core bundle** (always loaded, ~250 lines) — conventions that apply to every task
2. **On-demand modules** (loaded only when relevant) — auth patterns, form patterns, etc.

This saves 70-80% context overhead.

## Step 4: Customize Routing

Edit `routing.md`:
- Replace `{Name}` placeholders with your agent cast names
- Add/remove work types for your tech stack
- Keep the 7 routing principles (they're universal)

## Step 5: Customize Ceremonies

Edit `ceremonies.md`:
- Add stack-specific trigger conditions
- Adjust thresholds for your repo size
- Keep Design Review and Retrospective (they're universal)

## Step 6: Document Failures

**This is the single highest-ROI investment.**

After every failed agent run, add to `failure-patterns.md`:

```markdown
## N. {Pattern Name}

**What happened:** {description}
**Root cause:** {why}
**Mitigation:** {how to prevent}
**Checklist:**
- [ ] {verification step}
```

Examples from CAP Template:
- Hallucinated method names → always cite file:line
- Entity property without migration → tests fail with "Invalid column"
- Endpoint handler without route mapping → invisible at runtime
- 3+ parallel agents → API errors, cap at 2

## Step 7: Run a Benchmark

1. Pick a simple feature (like adding a new CRUD entity)
2. Run Squad: `copilot --agent squad`
3. Give the task: "Add a {feature} following the {reference} pattern"
4. Observe what goes wrong
5. Document failures and update charters/bundles
6. Repeat until a feature completes with <2 failures

After 3-4 features, your Squad team will be production-ready.
