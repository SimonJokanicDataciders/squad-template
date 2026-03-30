# Work Routing

How to decide who handles what.

## Delivery Flow

<!-- TODO: Customize for your project's SDLC phases -->
```
design → plan → implement / frontend / database → lint → test
    → integration-test → review → build → deploy → monitor
```

## Routing Table

<!-- TODO: Replace {Name} placeholders with your actual agent cast names -->
| Work Type | SDLC Phase | Route To | Examples |
|-----------|-----------|----------|----------|
| Architecture, domain model | design | {Lead} | System design, API contracts |
| Task decomposition | plan | {Lead} | Breaking work into steps |
| Backend services, endpoints | implement | {Backend} | API routes, business logic |
| Database schema, migrations | database | {Backend} | Schema changes, seed data |
| UI components, user flows | frontend | {Frontend} | Pages, forms, components |
| Lint, static analysis | lint | {Tester} | Code style checks |
| Unit tests | test | {Tester} | Unit tests, assertions |
| Integration tests | integration-test | {Tester} | API tests, e2e tests |
| PR review | review | {Tester} | Code review, approval |
| Build, package | build | {Ops} | Build pipeline |
| Deploy, promote | deploy | {Ops} | CI/CD, infrastructure |
| Monitoring | monitor | {Ops} | Observability, alerting |
| Documentation | document | Scribe | Docs, changelogs |
| Session logging | — | Scribe | Automatic |

## Routing Principles

1. **Eager routing** — pick the most specific agent
2. **Fan-out on multi-domain** — parallel when independent
3. **Anticipate downstream** — queue related work proactively
4. **Doc-impact check** — user-facing changes trigger Scribe
5. **Security-impact check** — auth/secrets changes trigger Ops
6. **Fallback cascade** — project overlay → universal → ask human
7. **Ceremony awareness** — check triggers before dispatching
