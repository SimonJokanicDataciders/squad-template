---
name: "cap-template-sdlc-context-core"
description: "Foundational SDLC context for CAP.Template local Squad sessions — core reference"
domain: "workflow"
confidence: "high"
source: "manual"
---

## Context

Use this skill when Squad is working inside the CAP.Template repository or a local worktree derived from it.

CAP.Template already has a mature GitHub-native agent system under `.github/`. Squad is a local collaboration layer for experiments and guided execution, not a replacement for the repository's existing GitHub workflows, routing, or SDLC rules.

Start from the universal SDLC contract first, then apply CAP.Template-specific overlay rules.

For full artifact schemas, decision logging format, and governance rules, read `cap-template-sdlc-context-reference.md`.

## CAP.Template Project Structure

```
CAP.Template/
├── .github/              # GitHub Agentic Workflows, Copilot instructions
├── .nuke/                # NUKE build system configuration
├── .pipeline/            # Pipeline configurations
├── .template.config/     # Template metadata
├── build/                # NUKE build scripts
├── docs/                 # Documentation
├── src/                  # Source code
├── tests/                # Test projects
└── Paso.Cap.sln          # Solution file
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend runtime | .NET 10 / C# (latest stable) |
| Frontend framework | Angular 21 with Nx workspace |
| ORM / data access | Entity Framework Core |
| Cloud orchestration | .NET Aspire 13.x |
| Infrastructure as Code | Pulumi (Azure targets) |
| Build system | NUKE |
| Testing framework | xUnit |
| Package management | Central via `Directory.Packages.props` |
| Commit convention | Conventional Commits (`type(scope): description`) |

## Delivery Flow Sequence

```
design → plan → implement / frontend / database → lint → test → integration-test → review → build → deploy → monitor
                    ↑                                                                                    ↓
                scaffold (optional)                                                            document (parallel)
```

## Squad Member to Delivery Flow Phase Mapping

| Squad Member | Delivery Flow Phases | Domain |
|--------------|---------------------|--------|
| **Ripley** | design, plan | Architecture, domain modeling, task decomposition, delivery sequencing |
| **Fenster** | implement, api-contract, database | Backend services, endpoints, EF Core models, migrations, DTOs, API contracts |
| **Dallas** | frontend, scaffold | Angular/Nx work, UI components, user flows, file scaffolding |
| **Hockney** | lint, test, integration-test, review | Code quality, unit tests, integration tests, PR review, quality gates |
| **Scribe** | document | API docs, README, changelog, decision capture, trial summaries |
| **Ralph** | build, deploy, monitor, secure | NUKE builds, CI/CD, Azure deployment, Pulumi IaC, security review, observability, incident triage |

## Response Tier Classification

| Tier | When | Max Agents | Squad Behavior | Example |
|------|------|------------|----------------|---------|
| **Direct** | Status checks, routing questions, simple factual queries | 0 (coordinator answers inline) | Coordinator answers without spawning any member | "Which agent handles database work?" |
| **Lightweight** | Single-file edits, quick fixes, isolated changes | 1 agent, focused scope | Single member, minimal artifact | "Fix the null check in UserService.cs" |
| **Standard** | Normal feature work within 1-2 SDLC phases | 1-2 agents, full workflow | 1-2 members, complete artifact with decisions | "Add a new GET endpoint for orders" |
| **Full** | Multi-domain features, 3+ layers, high/critical risk | 3+ agents, design review ceremony | Multiple members, ceremony participation, cross-cutting checks | "Add a new Orders feature with API, DB, and frontend" |

## Status Semantics

| Status | Meaning | Expected Behavior |
|--------|---------|-------------------|
| `success` | Work completed and ready to hand off | Return artifact and next step |
| `blocked` | Cannot continue with available inputs | Return exact blocker and missing requirement |
| `needs-approval` | Work can continue only after human approval | Return approval packet and hold |
| `failed` | Attempted work but encountered a verifiable failure | Return failure evidence and recovery options |
