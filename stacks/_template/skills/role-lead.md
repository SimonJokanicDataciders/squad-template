---
name: "role-lead"
description: "Core conventions and delivery flow for the Lead/Architect agent"
domain: "architecture"
confidence: "medium"
source: "manual"
---

# Lead / Architect — Core Skill Bundle

## Delivery Flow

```
design → plan → implement / frontend / database → lint → test
    → integration-test → review → build → deploy → monitor
         ↑                                              ↓
      scaffold (optional)               document (parallel)
```

### Phase Dependencies

| Phase | Input Artifacts | Output Artifacts | Agent |
|-------|----------------|-----------------|-------|
| design | User request | Architecture handoff, API contracts, file list | Lead |
| plan | Architecture handoff | Task breakdown, ordered steps | Lead |
| implement | Contracts, task list | Backend code, database changes | Backend |
| frontend | API contracts, backend endpoints | UI components, pages | Frontend |
| test | Implementation code | Unit + integration tests, review findings | Tester |
| document | All completed work | API docs, README, decisions | Scribe |

### Serialization Rules

1. **Lead runs SYNC first** — defines architecture, contracts, file structure
2. **Backend spawns AFTER Lead** — receives Lead's contracts as facts
3. **Frontend spawns AFTER Backend** — receives endpoint details as facts
4. **Tester spawns AFTER Backend + Frontend** — needs actual code to test
5. **Scribe runs LAST** (background) — documents everything
6. **Read-only agents (explore) CAN run in parallel** — analysis, audits, reviews

## Routing Principles

1. **Eager routing** — pick the most specific agent for each task
2. **Fan-out on multi-domain** — parallel when work streams are independent
3. **Anticipate downstream** — queue tests, docs while code is being written
4. **Doc-impact check** — user-facing changes trigger Scribe
5. **Security-impact check** — auth/secrets changes trigger Ralph

## Architecture Handoff Format

When the Lead produces an architecture handoff, it MUST include:

```markdown
## Architecture Handoff

### Domain Model
- Entity name, properties, relationships, constraints

### API Contracts
- Endpoint paths, HTTP methods, request/response shapes

### File Structure
- Exact file paths for every file to be created
- Which project/directory each file belongs to

### Implementation Order
1. Entity/model (Backend)
2. Service layer (Backend)
3. API endpoints (Backend)
4. Database migration (Backend)
5. Frontend components (Frontend)
6. Tests (Tester)

### Handoff Facts
- Key decisions and their rationale
- Constraints from existing codebase
- Reference implementation paths
```

## Decision Logging Format

```yaml
id: DECISION-{YYYY-MM-DD}-{sequence}
title: Short title
agent: Which agent made it
phase: Which SDLC phase
context: Why this was needed
choice: What was decided
alternatives_considered: What else was considered
consequences: Impact of this decision
```
