# Customization Guide

How to create a stack preset for your project's tech stack.

> **Note:** You don't always need a full preset. If you just want to get started, use `init.sh --auto` — it auto-detects your stack, applies matching seeds and language rules, and the coordinator's auto-learn generates skill bundles from your codebase on first session. A full preset is for when you want maximum control and consistency across multiple projects.

## Estimated Effort

| Component | Time | Reusability |
|-----------|------|-------------|
| Run init.sh | 1 min | Copy |
| Analyze your codebase | 1-2h | Document once |
| Write agent charters (4-6) | 2-3h | Per project |
| Write skill bundles (4-8) | 3-5h | Per stack (reuse across projects) |
| Customize routing + ceremonies | 30 min | ~70% copy |
| Create cast.conf (optional) | 5 min | Per stack |
| First benchmark + fixes | 1-2h | Pay once |
| **Total** | **8-12h** | **Amortizes at 3-4 features** |

## Step 1: Copy the Template

```bash
cp -r ~/squad-template/stacks/_template ~/squad-template/stacks/your-stack
```

The `_template/` directory contains **ready-to-customize files** with `<!-- Replace -->` markers — not empty TODOs. Every file has real structure and guidance.

## Step 2: Identify Your Reference Implementation

Find the best-documented, most complete feature in your codebase. This becomes the pattern all agents follow. It should demonstrate:

- Entity/model definition
- Service/business logic
- API endpoint/route
- Tests (unit + integration)
- Database migration (if applicable)

**Example:** CAP Template uses `WeatherForecasts` — a complete slice from entity to endpoint to tests.

## Step 3: Write Agent Charters

Edit `agents/*.charter.md` in your preset. Each charter should have these sections:

### Required Charter Sections

| Section | Purpose |
|---|---|
| **Project Context** | Stack, primary bundle path, reference implementation path |
| **Model** | Preferred model (`claude-opus-4.6`, `claude-sonnet-4.6`, or `claude-haiku-4.5`) with rationale |
| **Tools** | Allowed tools (Read/Grep/Glob for read-only agents, full access for implementers) |
| **Responsibilities** | 3-5 bullet points of what the agent owns |
| **Guardrails** | Concrete coding conventions + "What NEVER to Do" list |
| **Scope Boundaries** | Explicit DO/DON'T — what the agent handles vs routes to others |
| **Skill Loading Protocol** | Which bundles to read and when (core always, on-demand by task) |
| **Work Style** | Communication rules, self-validation requirement |

### What Makes a Good Charter

**Bad (generic):**
```markdown
## Responsibilities
- Collaborate with team members
- Maintain code quality
```

**Good (embedded knowledge):**
```markdown
## Model
- **Preferred:** `claude-sonnet-4.6`
- **Rationale:** Code generation needs accuracy. Standard tier balances quality and cost.

## Tools
- **Allowed:** Read, Grep, Glob, Edit, Write, Bash (full access — writes code and runs builds)

## Guardrails
### Code Conventions
- All classes are sealed by default unless abstract
- Immutable DTOs: `sealed record` with `init` properties
- Null checks: ALWAYS `is null` / `is not null` (never `== null`)
- XML docs on ALL public APIs

### What NEVER to Do
- NEVER manually edit migration files
- NEVER add endpoint handlers without registering routes
- NEVER run parallel DB queries on the same context/session

## Scope Boundaries
**DO:**
- Write backend services, endpoints, DTOs, database code
- Create database migrations
- Run build verification after changes

**DON'T:**
- Write frontend components (route to Frontend)
- Write tests (route to Tester)
- Make architecture decisions (route to Lead)
```

## Step 4: Write Skill Bundles

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

## Step 5: Create Cast Names (optional)

Create `cast.conf` to map generic role names to stack-specific agent names:

```
lead=ripley
backend=fenster
frontend=dallas
tester=hockney
scribe=scribe
ralph=ralph
```

`init.sh` renames agent directories and updates `team.md` automatically.

## Step 6: Customize Routing

Edit `routing.md`:
- Replace `{Name}` placeholders with your agent cast names
- Add/remove work types for your tech stack
- Keep the 7 routing principles (they're universal)

## Step 7: Customize Ceremonies

Edit `ceremonies.md`:
- Add stack-specific trigger conditions (e.g., "database migration present", "10+ files changed")
- Adjust thresholds for your repo size
- Keep Design Review and Retrospective (they're universal)

## Step 8: Document Failures

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

General patterns go in `shared/failure-patterns-global.md` (inherited by ALL projects).
Stack-specific patterns go in `stacks/your-stack/skills/failure-patterns.md`.

Examples from stress tests:
- Hallucinated method names → always cite file:line
- Concurrent DB queries on shared context → sequential queries or separate connections
- Frontend build walking into backend output dirs → exclude in tsconfig
- Entity property without migration → tests fail with "Invalid column"
- Endpoint handler without route mapping → invisible at runtime
- 3+ parallel agents → API errors, cap at 2

## Step 9: Run a Benchmark

1. Pick a simple feature (like adding a new CRUD entity)
2. Run Squad: `copilot --agent squad`
3. Give the task: "Add a {feature} following the {reference} pattern"
4. Observe what goes wrong
5. Document failures and update charters/bundles
6. Repeat until a feature completes with <2 failures

After 3-4 features, your Squad team will be production-ready.
