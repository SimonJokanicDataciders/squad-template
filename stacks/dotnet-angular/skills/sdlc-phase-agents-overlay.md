---
name: "cap-template-sdlc-phase-agents-overlay"
description: "Reusable Squad skill summarizing the CAP.Template SDLC overlay in .github/sdlc-phase-agents/ for local Squad sessions"
domain: "workflow"
confidence: "high"
source: "manual"
---

## Context

Use this skill when a local Squad session needs to understand or apply the CAP.Template-specific SDLC overlay found in `.github/sdlc-phase-agents/`. This overlay extends the universal SDLC agent system with stack-specific conventions, agent prompts, and routing rules tailored for CAP.Template.

## Overlay Purpose

- Provides CAP.Template-specific SDLC guidance layered on top of the universal agent contract.
- Maps overlay agent prompts to Squad roles (e.g., design, plan, implement, frontend, database, lint, test, integration-test, review, build, deploy, monitor, document, secure).
- Captures routing overrides, refusal rules, and stack conventions unique to CAP.Template.
- Ensures local Squad work aligns with both universal and overlay expectations.

## File Clusters

- **Overlay root:** `.github/sdlc-phase-agents/README.md` — overview and quick start
- **Agent prompts:** `.github/sdlc-phase-agents/agents/` — 16 flat-named agent files, each mapping to a Squad role or SDLC phase
- **Routing:** `.github/sdlc-phase-agents/ROUTING.md` — CAP.Template-specific routing overrides
- **Instructions:** `.github/sdlc-phase-agents/copilot-instructions.md` — identity, session protocol, refusal rules

## Mapping to Squad Members

- Ripley: architecture, planning, routing
- Fenster: backend, API, database
- Dallas: frontend
- Hockney: lint, test, review
- Scribe: documentation, decision capture
- Ralph: build, deploy, monitor, security

## Overlay-vs-Universal Differences

- Overlay adds stack-specific agent prompts (e.g., Angular frontend, EF Core database, .NET build/deploy)
- Routing and refusal rules may differ from universal defaults
- Overlay agents expect CAP.Template conventions (WeatherForecasts, .NET patterns, dual-DB, etc.)
- Universal layer remains the foundation for workflow, artifact, and ceremony rules

## High-Value Knowledge Clusters (Source Docs)

- **Scaffolding:** `.github/sdlc-phase-agents/agents/scaffold.md`
- **Build/Deploy:** `.github/sdlc-phase-agents/agents/build.md`, `.github/sdlc-phase-agents/agents/deploy.md`
- **Monitoring/Security:** `.github/sdlc-phase-agents/agents/monitor.md`, `.github/sdlc-phase-agents/agents/secure.md`
- **Integration Testing:** `.github/sdlc-phase-agents/agents/integration-test.md`

Consult these source docs for detailed implementation, operational, or test guidance not fully captured in this summary.

## When to Consult the Overlay

- When a Squad session needs stack-specific SDLC guidance beyond the universal contract
- When routing, refusal, or artifact rules differ from the universal system
- When onboarding new Squad members to CAP.Template conventions
- When troubleshooting agent handoff, ceremony triggers, or delivery flow in CAP.Template

## Anti-Patterns

- Do not treat overlay agents as replacements for the universal SDLC contract
- Do not skip the universal layer when applying overlay rules
- Do not assume overlay conventions apply to non-CAP.Template projects
