---
name: "cap-template-sdlc-context-reference"
description: "Full artifact schemas, decision logging, and governance rules for CAP.Template Squad sessions"
domain: "workflow"
confidence: "high"
source: "manual"
---

## Context

Full reference for artifact validation, decision logging, safety governance, and patterns. Load alongside `cap-template-sdlc-context-core.md`.

Primary reference files:
- `.github/universal-sdlc-agents/copilot-instructions.md`
- `.github/universal-sdlc-agents/ROUTING.md`
- `.github/universal-sdlc-agents/AGENT-STANDARDS.md`
- `.github/universal-sdlc-agents/CEREMONIES.md`
- `.github/sdlc-phase-agents/copilot-instructions.md`
- `.github/sdlc-phase-agents/ROUTING.md`

## Artifact Validation Chain

Each phase produces a typed artifact consumed by the next. The coordinator validates that the required artifact exists before dispatching a downstream agent.

| Phase Agent | Produces | Consumed By |
|-------------|----------|-------------|
| design | `design.brief` | plan |
| plan | `plan.tasks` | implement, database, scaffold, frontend |
| implement | `implementation.summary` | lint, test |
| database | (part of implementation) | lint, test |
| frontend | (part of implementation) | lint, test |
| test | `test.report` | review |
| review | `review.report` | build |
| build | `build.record` | deploy |
| deploy | `deployment.record` | monitor |
| document | `documentation.delta` | (terminal) |
| secure | `security.review` | review, deploy, incident-response |
| incident-response | `incident.record` | secure, deploy, migration |
| migration | `migration.assessment` | deploy, monitor |
| monitor | `monitoring.report` | (terminal / feeds back to incident-response) |

### Cross-Cutting Agents (triggered by context, not position)

- **secure** — any change touching auth, secrets, transport, permissions, or customer data
- **incident-response** — production alert, outage, or security breach
- **refactor** — structural improvement outside feature delivery
- **performance** — bottleneck or optimization work
- **onboarding** — new developer joining the team
- **migration** — major framework or platform upgrade

## Input Context Schema

Each invocation should carry a context payload equivalent to:

```yaml
request_id: unique identifier
agent_name: phase agent name
objective: short problem statement
scope:
  repository: name or path
  systems: affected services, apps, or data stores
constraints:
  deadlines: optional
  approvals_required: optional list
  non_functional: security, performance, availability, compliance
artifacts_in:
  - prior phase outputs
  - design docs
  - ticket or PR links
risk_tier: low | medium | high | critical
```

## Output Artifact Schema

Every agent must return an artifact equivalent to:

```yaml
status: success | blocked | needs-approval | failed
summary: short outcome statement
artifacts_out:
  - named documents, plans, reports, or commands
evidence:
  - commands run
  - files reviewed
  - tests or checks performed
risks:
  - open risks or known gaps
decisions:
  - key design or operational decisions
questions:
  - only when status is blocked or needs-approval
recommended_next_agent: agent name or null
```

## Decision Logging Format

Every agent must log key design or operational decisions in the artifact's `decisions` field:

```yaml
decisions:
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

### Decision Logging Protocol

1. **In-artifact**: Always include decisions in the artifact's `decisions` field using the standard format.
2. **Canonical log**: Significant decisions (architectural choices, pattern selections, technology decisions) should also be appended to `.squad/decisions.md`.
3. **Parallel work**: When multiple agents work simultaneously, write individual decision files to `decisions/inbox/` with naming: `{YYYY-MM-DD}-{agent}-{slug}.md`. These are reviewed and merged into the canonical log periodically.
4. **Superseding**: To override a prior decision, add a new entry with a `supersedes` field referencing the old decision ID. Never edit or delete existing entries.
5. **Checking**: Before proposing a new approach, agents MUST check `.squad/decisions.md` for prior decisions on the same topic.

### Cross-Session Learning

1. **Before proposing**: check decisions log and prior phase artifacts for existing decisions on the same topic.
2. **When diverging**: if a new decision contradicts a prior one, explicitly state the prior decision, why it no longer applies, and return `needs-approval` if the change is significant.
3. **When reinforcing**: if a decision aligns with a prior one, reference it to build consistency.

## Safety and Governance Action Classes

| Action Class | Examples | Approval Rule |
|--------------|----------|---------------|
| **Read-only** | Search, inspect, review, analyze | No approval required |
| **Local write** | Edit code, update docs, add tests | Approval by normal code review flow |
| **External change** | Create cloud resources, change CI, rotate secrets | Explicit human approval required |
| **Production-impacting** | Deploy, rollback, schema change, incident mitigation | Named approver required before execution |

### Destructive Operations

Agents must not perform destructive operations without explicit approval and a rollback path. This includes:
- Dropping or truncating data
- Destructive schema changes
- Deleting infrastructure
- Rotating or revoking credentials
- Bypassing protected workflows

### Data and Secrets

- Never place secrets in prompts, source files, commits, or examples.
- Redact secrets and access tokens in logs before sharing them.
- Treat customer data, credentials, internal URLs, and incident evidence as sensitive by default.
- Default to the stricter handling class if data classification is uncertain.

### Auditability

Production-impacting decisions must leave an audit trail containing: who approved the action, what changed, why it changed, when it changed, and rollback or recovery notes.

### Review Severity Taxonomy

| Severity | Meaning | Typical Action |
|----------|---------|----------------|
| Blocker | Unsafe to merge or deploy | Must fix before proceeding |
| Major | Significant quality or risk issue | Should fix before merge or release |
| Minor | Improvement with limited risk | Fix or document |
| Nit | Preference or polish item | Optional |

## Patterns

- Treat the **universal SDLC layer** as the foundation for routing, artifact expectations, ceremony triggers, decision logging, and operating rules.
- Treat the **CAP.Template SDLC overlay** as the source for stack-specific conventions such as WeatherForecasts-style structure, .NET patterns, EF Core expectations, testing expectations, and CAP.Template implementation guardrails. See also: `.squad/skills/cap-template-sdlc-phase-agents-overlay.md` for a concise overlay skill reference.
- Read work in this order:
  1. universal contract
  2. CAP.Template overlay
  3. role bundle for the assigned member
  4. member charter
- Follow the delivery flow by default:
  - `design -> plan -> implement / frontend / database -> lint -> test -> integration-test -> review -> build -> deploy -> monitor`
- Trigger documentation work for any setup, user-facing, or behavior-changing change.
- Trigger security/operations review for any CI, auth, deployment, monitoring, secrets, or production-adjacent change.
- Use the fixed local cast as role carriers:
  - `Ripley` -> architecture and planning
  - `Fenster` -> backend, API, and database
  - `Dallas` -> frontend and user-flow concerns
  - `Hockney` -> lint, test, review
  - `Scribe` -> documentation and decision capture
  - `Ralph` -> triage, build, release, security, and monitoring
- Prefer **sync collaboration** for tightly related work:
  - architecture + backend
  - backend + QA
  - backend + frontend when contracts must stay aligned
  - backend + operations when changes touch build, deploy, or security
- Keep shared state append-only:
  - decision proposals belong in `.squad/decisions/inbox/`
  - consolidated decisions belong in `.squad/decisions.md`
  - agent learnings belong in `.squad/agents/*/history.md`
  - session/orchestration details belong in `.squad/orchestration-log/`
- Keep the repository's `.github` system authoritative for GitHub automation and formal SDLC enforcement.

## Examples

- Universal routing and delivery flow: `.github/universal-sdlc-agents/ROUTING.md`
- Universal operating contract and handoff expectations: `.github/universal-sdlc-agents/AGENT-STANDARDS.md`
- Ceremony triggers such as design review and review gates: `.github/universal-sdlc-agents/CEREMONIES.md`
- CAP.Template-specific local behavior and refusal rules: `.github/sdlc-phase-agents/copilot-instructions.md`
- CAP.Template-specific routing overrides: `.github/sdlc-phase-agents/ROUTING.md`
- Local Squad roster and routing for this trial: `.squad/team.md`, `.squad/routing.md`
- Local role bundles:
  - `.squad/skills/cap-template-role-architect.md`
  - `.squad/skills/cap-template-role-backend.md`
  - `.squad/skills/cap-template-role-frontend.md`
  - `.squad/skills/cap-template-role-qa-core.md`
  - `.squad/skills/cap-template-role-documentation.md`
  - `.squad/skills/cap-template-role-operations.md`

## Anti-Patterns

- Do not treat Squad as a drop-in replacement for the existing `.github` SDLC system.
- Do not auto-adopt generated Squad GitHub workflows into CAP.Template without a separate review.
- Do not bypass routing by having the coordinator perform domain work directly.
- Do not edit shared append-only records casually or rewrite history instead of appending.
- Do not load every `.github` markdown file into base context; start with the universal core and then apply the CAP.Template overlay only where needed.
- Do not import `.github/workflows/*.md`, `.github/workflows/*.lock.yml`, `.github/copilot-skills/*`, or `.github/aw/actions-lock.json` into the base Squad context.
- Do not assume the preferred model is actually enforced just because `.squad/config.json` requests it; validate and record what was observed.
