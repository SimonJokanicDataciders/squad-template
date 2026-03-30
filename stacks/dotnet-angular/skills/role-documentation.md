---
name: "cap-template-role-documentation"
description: "Documentation and decision-capture bundle for Scribe in the local CAP.Template Squad"
domain: "documentation"
confidence: "high"
source: "manual"
---

## Context

Use this bundle when `Scribe` is updating local trial documentation, preserving decisions, or turning agent output into readable human guidance. This bundle embeds the full knowledge from the CAP.Template documentation agents so Scribe can operate without reading the original `.github/` files.

## CAP.Template Documentation Touchpoints

### 1. XML Documentation (C# Public APIs)

Every public method, class, and property must have XML docs. These feed directly into the OpenAPI spec via `Microsoft.AspNetCore.OpenApi`, displayed in Scalar (`/scalar`) or Swagger (`/swagger`).

```csharp
/// <summary>
/// Gets an order by its unique identifier.
/// </summary>
/// <param name="id">The order ID.</param>
/// <param name="cancellationToken">Cancellation token.</param>
/// <returns>The order DTO.</returns>
/// <exception cref="EntityNotFoundException">Thrown when the order does not exist.</exception>
public async Task<OrderDto> GetById(Guid id, CancellationToken cancellationToken = default) { }
```

### 2. REST Client File

**File:** `src/Paso.Cap.Web/CAP.http` -- Add example requests for every new endpoint:

```http
### Get all orders
GET {{host}}/api/orders

### Create order
POST {{host}}/api/orders
Content-Type: application/json

{
  "customerName": "Test Customer",
  "total": 99.99
}
```

### 3. README

**File:** `README.md` -- Update when new features added, build commands change, architecture changes, or new prerequisites needed.

### 4. Architecture Documentation

**Directory:** `docs/`
- `docs/build-project.md` -- NUKE build targets documentation
- `docs/infrastructure-project.md` -- Pulumi IaC documentation

### 5. Copilot Instructions

**File:** `.github/copilot-instructions.md` -- Update when new agents added, conventions change, or new custom agents created.

### 6. Agent Instructions

**Files:** `.github/agents/*.md` -- Update when stack versions change, new patterns established, or code standards evolve.

## Documentation Standards

**Writing style:**
- **Audience**: Write for developers new to this codebase
- **Clarity**: Be concise, specific, and value-dense
- **Examples**: Show code examples with explanations -- use `// Good` / `// Bad` patterns
- **Structure**: Use clear headings, lists, and tables

**Code examples pattern:**
```markdown
// Good -- Show what TO do
// Bad -- Show what NOT to do
```

## Decision Logging Format

Decisions use a canonical, append-only format. Never edit or delete existing entries. Before proposing a new approach, check for prior decisions on the same topic.

**Decision ID format:** `DECISION-{YYYY-MM-DD}-{sequence}`

**Schema:**
```yaml
- id: DECISION-{YYYY-MM-DD}-{sequence}
  title: Short decision title
  agent: Which agent made the decision
  phase: Which SDLC phase (design, plan, implement, review, etc.)
  context: Why this decision was needed
  choice: What was decided
  alternatives_considered:
    - Alternative and why it was rejected
  consequences: Impact of this decision
  supersedes: DECISION-ID (if replacing a prior decision, otherwise omit)
```

**Per-session parallel decisions:** Individual decision files go to `decisions/` directory with naming `{YYYY-MM-DD}-{agent}-{slug}.md`. These are reviewed and merged into the canonical log periodically.

**Rules:**
- Before proposing a new approach, check the log for prior decisions on the same topic
- Do not contradict an existing decision without explicit justification and `needs-approval` status
- When superseding a decision, add a new entry referencing the superseded decision by ID; the old entry remains for history

## Documentation Checklist (per change)

- [ ] XML docs on all new public APIs
- [ ] REST client file (`CAP.http`) updated with new endpoint examples
- [ ] README updated if architecture or setup changed
- [ ] `docs/` updated if build or infrastructure changed
- [ ] Copilot instructions updated if conventions changed
- [ ] Decision log entry appended (never edited) for architectural choices

## Patterns

- Write for humans first:
  - what changed
  - why it changed
  - where to inspect it
  - what is still uncertain
- Keep decision capture append-only:
  - propose decisions in `.squad/decisions/inbox/`
  - do not rewrite prior decisions
  - use the `DECISION-{YYYY-MM-DD}-{sequence}` ID format
- Cite evidence from actual local runs, files, and commands instead of summarizing from memory.
- Preserve operational caveats explicitly:
  - local-only scope
  - model-selection uncertainty
  - test or environment blockers
- Work in parallel with `Ripley`, `Hockney`, and `Ralph` when a change affects routing, review outcomes, or release behavior.

## CAP.Template Project Structure Reference

```
src/
  Paso.Cap.Web/            -- ASP.NET host, endpoints, middleware
  Paso.Cap.Domain/         -- Domain entities, EF Core DbContext
  Paso.Cap.Shared/         -- Shared DTOs, custom exceptions
  Paso.Cap.Angular/        -- Angular frontend
  Paso.Cap.AppHost/        -- .NET Aspire orchestration host
  Paso.Cap.Infrastructure/ -- Pulumi IaC, OTel Collector
build/                     -- NUKE build system (partial class pattern)
docs/                      -- Architecture documentation
.github/workflows/ci.yml   -- CI/CD pipeline
```

## Artifact Schema

When producing documentation artifacts, use this structure:

```yaml
artifact:
  type: documentation.delta
  agent: scribe
  files_touched:
    - path: "relative/path"
      action: created | updated | reviewed
  decision_ids: []          # Any DECISION-* IDs created
  summary: "One-line description"
  open_questions: []        # Uncertainties to flag
```

## Handoff Requirements

When handing work to or receiving from other agents:
- **From Hockney/Fenster (code changes):** Verify XML docs on new public APIs, update REST client file
- **From Ralph (operations changes):** Update `docs/build-project.md` or `docs/infrastructure-project.md`
- **To Ripley (routing):** Provide decision IDs and documentation delta summary
- **To any agent:** Always include file paths (absolute), decision references, and open questions

## Boundaries

- **Always do:** Write XML docs on public APIs, update REST client file, keep README current, use append-only decision logging
- **Ask first:** Major README restructures, adding new `docs/` files, copilot instruction changes
- **Never do:** Skip XML docs, document implementation details (document behavior), include secrets in docs, modify source code (READ code, WRITE docs), write vague documentation without examples, present local Squad artifacts as approved GitHub replacements

## Anti-Patterns

- Do not blur observed facts with assumptions.
- Do not replace decision history instead of appending to it.
- Do not describe generated GitHub workflows as approved for the real repository.
- Do not commit secrets or sensitive information into documentation.
- Do not use string interpolation examples in logging documentation (use structured parameters).
