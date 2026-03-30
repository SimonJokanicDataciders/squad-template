# Work Routing

How to decide who handles what for the local CAP.Template Squad trial. This file merges the universal SDLC routing rules with the CAP.Template overlay routing and maps each route to the correct Squad member.

## Delivery Flow

```
design → plan → implement / frontend / database → lint → test → integration-test → review → build → deploy → monitor
                    ↑                                                                                    ↓
                scaffold (optional)                                                            document (parallel)
```

**CAP.Template difference from universal:** This overlay includes a separate `frontend` phase for Angular/Nx work. The universal library merges frontend guidance into `implement`.

## Routing Table

| Work Type | SDLC Phase Agent | Route To (Squad) | Examples |
|-----------|-----------------|-------------------|----------|
| Architecture / design | design | **Ripley** | Feature shaping, boundaries, architecture decisions, trade-offs |
| Planning / task breakdown | plan | **Ripley** | Delivery plan, sequencing, issue decomposition, commit strategy |
| .NET backend implementation | implement | **Fenster** | Services, endpoints, DI, application code, domain logic |
| OpenAPI contracts, endpoint specs | api-contract | **Fenster** | REST API contracts, DTOs, endpoint definitions |
| Database / EF Core | database | **Fenster** | EF Core models, migrations, schema changes, queries |
| Frontend / Angular / Nx | frontend | **Dallas** | Angular components, Nx workspace, UI-facing changes |
| File scaffolding from plan | scaffold | **Dallas** | Boilerplate structure generation |
| User-flow / UX alignment | frontend | **Dallas** | Contract clarity, developer experience, UI implications |
| Format, lint, static analysis | lint | **Hockney** | Pre-commit quality, formatting checks |
| Unit and component tests | test | **Hockney** | xUnit tests, edge cases, regression coverage |
| Integration and e2e tests | integration-test | **Hockney** | Cross-boundary verification, e2e scenarios |
| PR review, quality gate | review | **Hockney** | Classified review findings, quality validation |
| API docs, README, changelog | document | **Scribe** | Documentation updates, decision capture, trial summaries |
| Decision capture / session logs | document | **Scribe** | Decision logs, exported outputs, session notes |
| Compile, package, container image | build | **Ralph** | NUKE builds, Docker images, GitHub Actions pipeline |
| Environment promotion, rollback | deploy | **Ralph** | Azure deployment, Pulumi IaC, environment promotion |
| Traces, metrics, logging, alerts | monitor | **Ralph** | Observability, alert configuration, production health |
| Vulnerability review, auth, secrets | secure | **Ralph** | Azure auth, OIDC config, security audit, secrets review |
| Incident triage, mitigation | incident-response | **Ralph** | Production incidents, triage, post-mortem |
| Inbox triage / queue coordination | coordinator | **Ralph** | Initial task sorting, cross-cutting risk check |
| Orchestration, routing | coordinator | (Coordinator) | Entry point — classify work, validate artifacts, dispatch |

## CAP.Template Routing Overrides

When work is CAP.Template-specific, prefer the overlay agent over the universal agent:

| Work Type | Universal Agent | CAP.Template Overlay Agent | When to Use Overlay |
|-----------|-----------------|---------------------------|---------------------|
| Angular, Nx, frontend | implement | frontend | Any Angular or Nx work |
| EF Core models, migrations | database | database (overlay) | EF Core schema or database-specific work |
| REST API endpoints, services | api-contract | api-contract (overlay) | REST API contracts |
| Authentication, security | secure | secure (overlay) | Azure auth and security config |
| Docker build, GitHub Actions | build | build (overlay) | NUKE build or GitHub Actions pipeline work |
| Azure deployment, Pulumi | deploy | deploy (overlay) | Azure environment promotion |

## Universal Fallback Agents

For work types without CAP.Template overlay, use the universal agent directly:

| Work Type | Universal Agent | Squad Member |
|-----------|-----------------|-------------|
| Code restructuring | refactor | Fenster / Ripley (by domain) |
| Performance optimization | performance | Fenster / Ralph (by domain) |
| Production incidents | incident-response | Ralph |
| Framework upgrades | migration | Ripley + Fenster |
| New developer setup | onboarding | Scribe |
| File scaffolding | scaffold | Dallas |

## Issue Label Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, check risk, assign `squad:{member}` label | Ralph |
| `squad:ripley` | Pick up architecture, planning, or coordination work | Ripley |
| `squad:fenster` | Pick up backend, database, or API work | Fenster |
| `squad:dallas` | Pick up UI or user-flow work | Dallas |
| `squad:hockney` | Pick up testing and review work | Hockney |
| `squad:scribe` | Pick up documentation and decision-capture work | Scribe |
| `squad:ralph` | Pick up triage, release, security, or monitoring work | Ralph |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, Ralph performs the first triage and assigns the right `squad:{member}` label.
2. When a `squad:{member}` label is applied, that member picks up the issue in the next session.
3. Members can reassign by removing their label and adding another member label.
4. The `squad` label is the inbox for untriaged Squad work.

## Routing Principles

### 1. Eager Routing

Default to the most specific agent. If an overlay agent exists for the work type, prefer it over the universal agent. Spawn all agents who could usefully start work, including anticipatory downstream work.

### 2. Fan-Out on Multi-Domain

When work streams are independent (e.g., backend + frontend + database), dispatch agents in parallel rather than sequentially. Use `Promise.allSettled` semantics -- one agent's failure should not block independent streams.

**CAP-specific fan-out:** Backend (`implement` / Fenster) and frontend (`frontend` / Dallas) work can proceed in parallel after `plan` produces `plan.tasks`.

**Squad shorthand:** `"Team, ..."` triggers fan-out -- spawn all relevant members in parallel when the task naturally splits.

### 3. Anticipate Downstream

If `implement` touches the database, also queue `database`. If a change modifies API surface, queue `api-contract` for validation.

**CAP-specific anticipation:**
- New entity -> also queue `database` (Fenster) for migration
- New endpoint -> also queue `api-contract` (Fenster) for contract validation
- New feature -> also queue `frontend` (Dallas) if Angular UI is enabled
- Any user-facing change -> also queue `document` (Scribe)
- Feature being built -> involve Hockney early for tests and Scribe early for user-facing impact

### 4. Doc-Impact Check

Any user-facing change (new endpoint, configuration change, setup change) must trigger the `document` agent (Scribe) before the delivery flow completes. Scribe joins any substantial outcome for documentation and decision capture.

### 5. Security-Impact Check

Any change touching authentication, secrets, transport, permissions, or customer data must trigger the `secure` agent (Ralph).

**CAP-specific security triggers:** Changes to Azure credentials, OIDC config, or feature flags controlling production features must trigger `secure` (Ralph). Ralph joins any build, deploy, security, or monitoring-sensitive task early.

### 6. Fallback Cascade

Overlay agent -> universal agent -> coordinator asks the human. Never silently drop a routing miss.

### 7. Ceremony Awareness

Before dispatching to implementation, check ceremony triggers for design review conditions. Before merge, check for PR review ceremony triggers.

**CAP-specific ceremony triggers:**
- EF Core migration altering existing tables -> triggers Design Review
- New Pulumi infrastructure -> triggers Design Review
- Database migration in PR -> triggers PR Review Ceremony

## Routing Rules

1. **Follow the delivery flow by default.** Start at design, end at monitor.
2. **Skip phases that don't apply.** Not every feature needs database, scaffold, or integration-test.
3. **Cross-cutting agents run on demand.** Invoke them when the situation requires, not in sequence.
4. **Each agent consumes the prior agent's artifact.** See artifact chain in `cap-template-sdlc-context.md`.
5. **When two agents could handle it**, pick the one whose domain is the primary concern.
6. **Escalate across workflows.** If review finds a security issue, route to secure (Ralph). If deploy fails, route to incident-response (Ralph).
7. **Universal first, overlay second.** Read the universal contract, then the CAP.Template overlay, then the local member bundle.
8. **Quick facts -> coordinator answers directly.** Do not spawn an agent for simple repository facts.
9. **Prefer CAP.Template specializations when possible.** Architecture → Ripley; backend → Fenster; testing → Hockney; documentation → Scribe. Always use Squad cast names, never `.github/agents/` role titles.
10. **Do not auto-adopt generated GitHub workflows.** Any workflow-level change must be reviewed separately against the repository's existing `.github` setup.
11. **Treat model choice as an observed result.** Prefer `gpt-4.1`, but document what the tool actually used.
12. **The repository's existing `.github` SDLC system remains authoritative.** This Squad roster is a local collaboration layer, not a replacement for CAP.Template GitHub workflows.
