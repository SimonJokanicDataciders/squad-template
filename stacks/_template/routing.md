# Work Routing

How to decide who handles what.

## Delivery Flow

```
design → plan → implement / frontend / database → lint → test
    → integration-test → review → build → deploy → monitor
         ↑                                              ↓
      scaffold (optional)               document (parallel)
```

## Routing Table

| Work Type | SDLC Phase | Route To | Examples |
|-----------|-----------|----------|----------|
| Architecture, domain model, API contracts | design | Lead | System design, boundaries, data model, trade-offs |
| Task decomposition, commit strategy | plan | Lead | Breaking work into steps, ordering, sequencing |
| Backend services, endpoints, business logic | implement | Backend | API routes, services, domain logic, DI |
| API contracts, endpoint specs | api-contract | Backend | REST API contracts, DTOs, endpoint definitions |
| Database schema, migrations, seed data | database | Backend | ORM models, migrations, schema changes, queries |
| UI components, pages, user flows | frontend | Frontend | Components, pages, forms, styling |
| File scaffolding from plan | scaffold | Frontend | Boilerplate structure generation |
| Format, lint, static analysis | lint | Tester | Pre-commit quality, formatting checks |
| Unit and component tests | test | Tester | Unit tests, edge cases, regression coverage |
| Integration and e2e tests | integration-test | Tester | Cross-boundary verification, e2e scenarios |
| PR review, quality gate | review | Tester | Code review findings, quality validation |
| API docs, README, changelog | document | Scribe | Documentation updates, decision capture |
| Decision capture, session logs | document | Scribe | Decision logs, session notes |
| Build, package, container image | build | Ralph | Build pipeline, Docker images, CI |
| Deploy, environment promotion | deploy | Ralph | CD pipeline, infrastructure, rollback |
| Monitoring, logging, alerts | monitor | Ralph | Observability, alert configuration |
| Security review, auth, secrets | secure | Ralph | Auth config, secrets audit, vulnerability review |
| Incident triage, mitigation | incident-response | Ralph | Production incidents, post-mortem |

## Issue Label Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up issue and complete the work | Named member |

## Routing Principles

### 1. Eager Routing
Default to the most specific agent. Spawn all agents who could usefully start work, including anticipatory downstream work.

### 2. Fan-Out on Multi-Domain
When work streams are independent (e.g., backend + frontend + database), dispatch agents in parallel rather than sequentially.

### 3. Anticipate Downstream
If implementation touches the database, also queue database work. If a change modifies API surface, queue contract validation. If a feature is being built, spawn the tester to write test cases from requirements simultaneously.

### 4. Doc-Impact Check
Any user-facing change (new endpoint, configuration, setup) must trigger Scribe before the delivery flow completes.

### 5. Security-Impact Check
Any change touching authentication, secrets, transport, permissions, or customer data must trigger Ralph for security review.

### 6. Fallback Cascade
Project-specific rules → universal rules → ask human. Never silently drop a routing miss.

### 7. Ceremony Awareness
Before dispatching to implementation, check ceremony triggers. Before merge, check PR review ceremony triggers.

## Routing Rules

1. **Follow the delivery flow by default.** Start at design, end at monitor.
2. **Skip phases that don't apply.** Not every feature needs database, scaffold, or integration-test.
3. **Each agent consumes the prior agent's artifact.** Design → implement → test → document.
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **Quick facts → coordinator answers directly.** Don't spawn an agent for simple questions.
6. **Prefer stack specializations when possible.** Architecture → Lead; backend → Backend; testing → Tester.
