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
| Compile, package, Docker build | build | Ops | Build pipeline, containerization |
| Environment promotion, rollback | deploy | Ops | CI/CD, infrastructure |
| Traces, metrics, logging, health checks | monitor | Ops | Observability, alerting |
| API docs, README, decision capture | document | Docs | Documentation, changelogs |
| Security audit, auth, secrets | secure | Ops | Security review, vulnerability scan |
| Session logging | — | Scribe | Automatic — never needs routing |

## Routing Principles

1. **Eager routing** — pick the most specific agent; prefer project overlay over universal
2. **Fan-out on multi-domain** — backend + frontend work in parallel when independent
3. **Anticipate downstream** — if backend touches DB, queue database phase too
4. **Doc-impact check** — any user-facing change triggers Docs agent
5. **Security-impact check** — any auth/secrets change triggers Ops agent
6. **Fallback cascade** — project overlay → universal → ask human
7. **Ceremony awareness** — check if design review or PR review should be triggered before dispatching
