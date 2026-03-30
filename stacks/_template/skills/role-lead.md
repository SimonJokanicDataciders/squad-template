---
name: "role-lead"
description: "Core conventions and delivery flow for the Lead/Architect agent"
domain: "architecture"
confidence: "medium"
source: "manual"
---

# Lead / Architect — Core Skill Bundle

<!-- TODO: Fill in your project's delivery flow, routing rules, and architectural patterns -->

## Delivery Flow

<!-- TODO: Define the sequence of SDLC phases for your project -->
```
design → plan → implement / frontend / database → lint → test
    → integration-test → review → build → deploy → monitor
```

## Routing Principles

1. Eager routing — pick the most specific agent
2. Fan-out on multi-domain work (parallel when independent)
3. Anticipate downstream work (tests, docs while code is being written)
4. Doc-impact check on user-facing changes
5. Security-impact check on auth/secrets changes

## Architecture Patterns

<!-- TODO: Document your project's key architectural decisions -->
<!-- Example:
### Domain-Driven Design
- Entities implement IAggregateRoot marker interface
- Services are sealed classes, one per aggregate
- DTOs are immutable records
-->

## Decision Logging Format

```yaml
id: DECISION-{YYYY-MM-DD}-{sequence}
title: Short title
agent: Which agent made it
phase: Which SDLC phase
context: Why this was needed
choice: What was decided
consequences: Impact of this decision
```
