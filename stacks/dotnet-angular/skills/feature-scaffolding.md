---
name: "cap-template-feature-scaffolding"
description: "CAP.Template-specific feature scaffolding flow, agent handoff, and artifact expectations"
domain: "workflow"
confidence: "high"
source: "manual"
---

## Context

Use this skill when scaffolding a new feature in CAP.Template, especially when following the overlay SDLC and WeatherForecasts reference pattern. This skill summarizes when and how to use the scaffold/design/plan cluster, the order of work, agent handoffs, and anti-patterns.

## When to Use Scaffold/Design/Plan
- **Design**: Always start with the design agent for new features, domain models, or major changes. Output: `design.brief`.
- **Plan**: After design, use the plan agent to decompose work into ordered tasks, files, and risks. Output: `plan.tasks`.
- **Scaffold**: Use the scaffold agent after plan to generate boilerplate files and structure, following the WeatherForecasts reference. Output: initial file tree and stubs.
- **Note**: Scaffold is optional but recommended for new features or when reference alignment is critical.

## Expected Order of Work
1. **Design** (Ripley): Define architecture, domain, and boundaries. Reference WeatherForecasts for structure.
2. **Plan** (Ripley): Decompose into tasks, files, and commit strategy. Identify dependencies and risks.
3. **Scaffold** (Dallas): Generate file/folder structure and stubs, matching WeatherForecasts.
4. **Implement** (Fenster/Dallas): Fill in backend, frontend, and database logic.
5. **QA/Review** (Hockney): Lint, test, review.
6. **Document** (Scribe): Update docs, log decisions.
7. **Build/Deploy/Monitor** (Ralph): CI, deployment, monitoring, security.

## WeatherForecasts Reference Pattern
- Always use the WeatherForecasts feature as the canonical example for new features.
- Match structure: entity, configuration, DTOs, service, endpoint, feature flag, Angular folder (if UI).
- Do not deviate from this pattern without explicit human approval and a logged decision.

## Handoff and Agent Roles
- **Ripley**: Owns design and plan, validates artifacts, triggers handoff.
- **Dallas**: Handles scaffolding and frontend structure.
- **Fenster**: Implements backend, API, and database logic.
- **Hockney**: Linting, testing, review.
- **Scribe**: Documentation, decision capture.
- **Ralph**: Build, deploy, monitor, security.
- Handoffs are always artifact-based: each agent consumes the prior phase's output (e.g., `plan.tasks` → scaffold).

## High-Value Artifacts
- `design.brief`: Architecture, domain, and risk summary.
- `plan.tasks`: Ordered task list, file map, risk/approval notes.
- Scaffolded file tree: All stubs and folders matching WeatherForecasts.
- Implementation summary, test reports, review logs, documentation delta.

## Anti-Patterns
- Do **not** skip the design or plan phase before scaffolding.
- Do **not** scaffold without referencing WeatherForecasts.
- Do **not** centralize all work in Ripley—handoff to specialists per routing.
- Do **not** create mutable DTOs, entities without `RowVersion`, or skip feature flags.
- Do **not** bypass artifact handoff or ceremony triggers (e.g., design review for migrations).
- Do **not** treat scaffold as a replacement for implementation—it's a starting point only.

## References
- `.github/sdlc-phase-agents/agents/design.md`, `plan.md`, `scaffold.md`
- `.github/sdlc-phase-agents/ROUTING.md`, `.squad/routing.md`
- `.squad/skills/cap-template-sdlc-context.md`, `cap-template-sdlc-phase-agents-overlay.md`
- WeatherForecasts feature in `src/Paso.Cap.Domain/WeatherForecasts/`
