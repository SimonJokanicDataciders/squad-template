---
name: "cap-template-role-ops-core"
description: "Core operations bundle for Ralph — always loaded. Contains project structure, artifact schema, handoffs, checklists summary, and load-on-demand table for domain modules."
domain: "operations"
confidence: "high"
source: "split from cap-template-role-operations.md"
---

## Context

Use this bundle when `Ralph` is triaging work, assessing build/release concerns, checking security-sensitive changes, or validating monitoring/operations impact. This is the core module — always load this first, then load domain-specific modules as needed.

## Load on Demand

| Module | Load when task involves | File |
|--------|------------------------|------|
| Build | NUKE, Docker, migrations, versioning, compilation | `.copilot/skills/cap-template-role-ops-build.md` |
| Deploy | CI/CD, Pulumi, Azure, environment promotion, GitHub Actions | `.copilot/skills/cap-template-role-ops-deploy.md` |
| Monitor | Telemetry, metrics, logging, health checks, Aspire, OpenTelemetry | `.copilot/skills/cap-template-role-ops-monitor.md` |
| Secure | Security, auth, secrets, exception handling, OIDC, vulnerabilities | `.copilot/skills/cap-template-role-ops-secure.md` |

For triage tasks that span multiple domains, load all relevant modules.

## CAP.Template Project Structure Reference

```
src/
  Paso.Cap.Web/            -- ASP.NET host, endpoints, middleware
  Paso.Cap.Domain/         -- Domain entities, EF Core DbContext
  Paso.Cap.Shared/         -- Shared DTOs, custom exceptions (EntityNotFoundException, ConcurrencyException)
  Paso.Cap.Angular/        -- Angular frontend
  Paso.Cap.AppHost/        -- .NET Aspire orchestration host (Aspire 13.x)
  Paso.Cap.Infrastructure/ -- Pulumi IaC (AppStack.cs), OTel Collector
build/                     -- NUKE build system (partial class pattern)
docs/                      -- Architecture documentation
.github/workflows/ci.yml   -- CI/CD pipeline
```

## Artifact Schema

When producing operations artifacts, use this structure:

```yaml
artifact:
  type: operations.assessment
  agent: ralph
  scope: build | deploy | monitor | secure | triage
  risk_level: low | medium | high | critical
  files_reviewed:
    - path: "relative/path"
      concern: "description"
  checklist_result:
    passed: []
    failed: []
    skipped: []
  approval_required: true | false
  summary: "One-line description"
  open_risks: []
```

## Handoff Requirements

- **From Ripley (triage):** Receive work items touching build/deploy/monitor/secure; assess risk and route
- **From Fenster (backend):** Review CI impact, auth changes, runtime configuration
- **From Hockney (review):** Validate release readiness, security findings
- **To Scribe:** Provide operational findings for documentation in `docs/build-project.md` or `docs/infrastructure-project.md`
- **To any agent:** Always include risk level, checklist results, and whether human approval is required

## Boundaries

- **Always do:** Restore before compile, test before deploy, use NUKE targets (not raw dotnet CLI for CI), use OIDC, verify health checks, throw domain exceptions, validate inputs
- **Ask first:** Changing target dependency graph, modifying Docker base images, manual deployments, skipping environments, changing OIDC config, adding new exception types, changing CORS policy, adding new metrics instruments, changing OTel exporter config
- **Never do:** Skip Restore, deploy without testing, hardcode paths (use `AbsolutePath`), push to ACR without building first, deploy to Prod without Staging, store Azure credentials as secrets (use OIDC), hardcode secrets, return stack traces to clients, use `FromSqlRaw` with interpolation, disable HTTPS, log PII, use string interpolation for logs, mix OTel package versions, perform external/production-impacting actions without explicit approval

## Anti-Patterns

- Do not treat generated local Squad workflows as approved replacements for the repository's GitHub workflows.
- Do not perform external, deployment, or production-impacting actions without explicit approval.
- Do not hide security-sensitive implications inside a generic review summary.
- Do not skip the Dev -> Staging -> Prod promotion chain.
- Do not store service principal secrets; always use OIDC.

## Patterns

- Join the task when work touches CI/local build, deployment flow, security-sensitive configuration, observability, or release readiness
- Treat GitHub workflows and infrastructure as authoritative in the real repository
- Separate safe local evaluation from external actions: local reads/writes are fine; external or production-impacting actions require explicit human approval
- Capture operation-sensitive risks clearly so they are visible before a local experiment is mistaken for a production-ready workflow
- Support `Ripley` with triage and route build, deploy, secure, and monitor concerns early

## When Ralph Should Join Early

- Any work touching CI/build, deployment, observability, or security-sensitive config
- When release readiness, rollback, or explicit human approval is in question
- On changes to OIDC, Pulumi, health checks, or exception handling
- When cross-cutting risk or triage is needed (pair with Ripley)

## Common Pairings

- **Ripley:** Triage, risk routing, early build/deploy/security review
- **Fenster:** CI/auth/runtime config, backend changes
- **Hockney:** Release readiness, security review
- **Scribe:** Document operational findings for build/infrastructure docs
