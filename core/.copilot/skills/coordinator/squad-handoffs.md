# Squad Handoffs — Structured Agent-to-Agent Communication

**Load when:** Multi-agent tasks, orchestrated workflows, or any task involving 2+ agents.

---

## Handoff Document Format

When one agent's output feeds into another agent's input, the coordinator must structure the handoff as follows:

### Architecture Handoff (Lead → Implementation Agents)

```markdown
## Architecture Handoff

### Domain Model
- Entity: {name}, properties, relationships, constraints
- DTOs: {input DTO}, {output DTO} with field mappings

### API Contracts
| Method | Path | Request Body | Response | Status Codes |
|--------|------|-------------|----------|-------------|
| GET | /api/{resource} | — | {DTO}[] | 200, 404 |
| POST | /api/{resource} | {CreateDTO} | {DTO} | 201, 400 |

### File Structure
| File | Directory | Agent | Purpose |
|------|-----------|-------|---------|
| {Entity}.cs | src/domain/{feature}/ | Backend | Entity definition |
| {Entity}Service.cs | src/domain/{feature}/ | Backend | Business logic |

### Implementation Order
1. Entity/model (Backend) — no dependencies
2. Service layer (Backend) — depends on entity
3. API endpoints (Backend) — depends on service
4. Database migration (Backend) — depends on entity
5. Frontend components (Frontend) — depends on API contracts
6. Tests (Tester) — depends on implementation

### Key Decisions
- {Decision 1 with rationale}
- {Decision 2 with rationale}
```

### Implementation Handoff (Backend → Frontend)

```markdown
## Implementation Handoff

### Completed
- Files created: {list with paths}
- Endpoints available: {method + path + response shape}
- Database migration: {name, what it does}

### For Frontend
- API base URL: {path}
- Response types: {TypeScript interface shapes}
- Auth required: {yes/no, which endpoints}

### Open Questions
- {Any unresolved design decisions}
```

### QA Handoff (Implementation → Tester)

```markdown
## QA Handoff

### What to Test
- {Feature area 1}: {key scenarios}
- {Feature area 2}: {key scenarios}

### Files Changed
- {file path}: {what changed and why}

### Known Risks
- {Edge case 1}
- {Area that might break}

### Recommendations
- {Specific test scenarios to prioritize}
```

### Final Report (All Agents → User)

```markdown
## Final Report

### Verdict: {SHIP | NEEDS WORK | BLOCKED}

### What Was Built
- {Summary of work with file counts}

### Files Created/Modified
| File | Action | Agent |
|------|--------|-------|
| {path} | Created | {agent} |

### How to Run
- Install: {command}
- Dev server: {command}
- Tests: {command}

### How to Test
- {Step 1}
- {Step 2}

### Known Limitations
- {If any}
```

## Rules

1. The coordinator constructs the handoff document from the completed agent's output
2. The handoff is inlined into the next agent's spawn prompt — agents don't read handoff files
3. Every handoff must include exact file paths, not generic descriptions
4. Open questions should be resolved by the coordinator before passing to the next agent
