---
name: "role-backend-core"
description: "Core backend conventions — load first for every backend task"
domain: "backend"
confidence: "medium"
source: "manual"
---

# Backend Developer — Core Skill Bundle

<!-- TODO: Fill in your project's backend conventions, patterns, and reference implementation details -->

## Project Structure

<!-- TODO: Document your backend directory layout -->
<!-- Example:
```
src/
├── domain/          # Entities, services, DTOs
├── api/             # Endpoints, middleware, routes
├── infrastructure/  # Database, external services
└── shared/          # Cross-cutting utilities
```
-->

## Code Conventions

<!-- TODO: Document your language/framework conventions -->
<!-- Examples for C#:
- Sealed by default (all classes `sealed` unless abstract)
- Immutable DTOs: `sealed record` with `init` properties
- Null checks: ALWAYS `is null` / `is not null`
- XML docs on all public APIs
- File-scoped namespaces
-->

## Entity Pattern

<!-- TODO: Document how entities are structured in your project -->

## Service Pattern

<!-- TODO: Document how services are structured -->

## Endpoint / Route Pattern

<!-- TODO: Document how API endpoints are structured -->

## Database Conventions

<!-- TODO: Document ORM patterns, migration rules, etc. -->

## Implementation Checklist

- [ ] Code follows project conventions
- [ ] New files are registered/imported where needed
- [ ] Database changes have corresponding migrations
- [ ] Build passes after changes
- [ ] No unnecessary dependencies added
