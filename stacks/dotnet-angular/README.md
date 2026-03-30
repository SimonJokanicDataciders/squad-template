# dotnet-angular Stack Preset

Pre-built Squad configuration for **.NET 10 + Angular 21** projects, extracted from the CAP Template.

## What's Included

### Agent Charters (6)
- `architect.charter.md` — Lead/architect with delivery flow and routing
- `backend.charter.md` — .NET backend with sealed classes, EF Core, compiled queries
- `frontend.charter.md` — Angular 21, Nx workspace, standalone components, signals
- `qa.charter.md` — xUnit, Testcontainers, evidence-driven review
- `docs.charter.md` — Documentation specialist
- `ops.charter.md` — NUKE build, Pulumi deploy, OpenTelemetry monitoring

### Skill Bundles (22)
Core bundles (always loaded per agent) + on-demand modules for auth, entities, forms, material, tests, build, deploy, monitor, secure.

### Pre-configured
- `routing.md` — Work types mapped to SDLC phases and agents
- `ceremonies.md` — Design Review, PR Review, Post-Incident Retrospective

## How to Apply

```bash
~/squad-template/init.sh ~/my-dotnet-project --stack dotnet-angular
```

After Squad creates your team:
1. Open `.squad/agents/{cast-name}/charter.md`
2. Copy the guardrails and skill loading sections from the matching charter in this directory
3. Save and restart your Squad session

## Conventions Embedded

- Sealed classes by default
- Immutable DTOs (`sealed record` with `init`)
- `IAggregateRoot` marker, `RowVersion` for concurrency
- Compiled queries, `ExecutionStrategy` wrapping
- `EndpointGroupBase`, `.WithDefaultMetadata()`, plural routes
- Standalone Angular components, OnPush, inject(), signal()
- xUnit, `MethodName_Condition_ExpectedResult` naming
- 10 documented failure patterns with mitigations
