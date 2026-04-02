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
| Architecture, domain model | design | Lead | System design, API contracts, data model |
| Task decomposition, commit strategy | plan | Lead | Breaking work into steps, ordering |
| Backend services, endpoints | implement | Backend | API routes, business logic, data access |
| Database schema, migrations | database | Backend | Schema changes, seed data |
| UI components, user flows | frontend | Frontend | Pages, forms, components, styling |
| File scaffolding | scaffold | Frontend | Generate boilerplate, project structure |
| Lint, formatting, static analysis | lint | Tester | Code style, linting rules |
| Unit and component tests | test | Tester | Unit tests, mocks, assertions |
| Integration and e2e tests | integration-test | Tester | API tests, browser tests |
| PR review, quality gates | review | Tester | Code review, approval |
| API docs, README, decision capture | document | Scribe | Documentation, changelogs |
| Session logging | — | Scribe | Automatic — never needs routing |

## Routing Principles

1. **Eager routing** — pick the most specific agent
2. **Fan-out on multi-domain** — parallel when independent
3. **Anticipate downstream** — queue related work proactively
4. **Doc-impact check** — user-facing changes trigger Scribe
5. **Security-impact check** — auth/secrets changes need review
6. **Fallback cascade** — project rules → universal → ask human
7. **Ceremony awareness** — check triggers before dispatching
