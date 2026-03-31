---
name: "role-backend-core"
description: "Core backend conventions — load first for every backend task"
domain: "backend"
confidence: "medium"
source: "manual"
---

# Backend Developer — Core Skill Bundle

## Project Structure

<!-- Replace with YOUR project's actual directory layout. Example: -->
```
src/
├── domain/              # Entities, services, DTOs, database context
│   ├── {Feature}/       # One folder per domain feature
│   │   ├── {Entity}.cs          # Entity class
│   │   ├── {Entity}Service.cs   # Service with business logic
│   │   ├── {Entity}Dto.cs       # DTOs (immutable records)
│   │   └── {Entity}Configuration.cs  # ORM configuration
│   ├── ApplicationDbContext.cs  # Database context
│   └── Migrations/              # Database migrations
├── api/                 # Endpoints, middleware, routes
│   ├── Endpoints/       # One file per endpoint group
│   └── Infrastructure/  # DI registration, middleware
├── shared/              # Cross-cutting types, interfaces
└── tests/
    ├── unit/            # Unit tests
    └── integration/     # Integration tests with real database
```

## Code Conventions

<!-- Replace with YOUR language/framework conventions. Examples: -->
- Follow existing code style exactly — read the reference implementation first
- All public APIs must have documentation (XML docs, JSDoc, docstrings)
- Use consistent error handling patterns (structured errors, not raw exceptions)
- Use dependency injection — never instantiate services directly
- Configuration via environment variables, not hardcoded values
- Use async/await for all I/O operations

## Entity Pattern

<!-- Replace with YOUR entity pattern. Example: -->
```
// Your entity pattern goes here
// Copy a REAL entity from your reference implementation
// Include: class definition, properties, markers, constraints
```

**Rules:**
- One entity per file, named `{EntityName}.cs` / `{entity_name}.py`
- Include all constraints (required fields, max lengths, relationships)
- Include version/concurrency field if applicable

## Service Pattern

<!-- Replace with YOUR service pattern. Example: -->
```
// Your service pattern goes here
// Copy a REAL service from your reference implementation
// Include: constructor, CRUD methods, error handling
```

**Rules:**
- One service per entity/aggregate
- Async methods with cancellation support where applicable
- Return DTOs, not entities, from public methods
- Handle not-found cases explicitly (don't return null silently)

## Endpoint / Route Pattern

<!-- Replace with YOUR endpoint pattern. Example: -->
```
// Your endpoint/route pattern goes here
// Copy a REAL endpoint group from your reference implementation
// Include: route definition, handlers, validation, response types
```

**Rules:**
- Plural lowercase resource names: `/api/items`, `/api/users`
- Use typed responses (Created for POST, NoContent for DELETE)
- Validate all input — never trust user data
- Every handler must be registered in the route configuration

## Database Conventions

<!-- Replace with YOUR ORM/database conventions. Examples: -->
- Use the project's ORM for all database access (never raw SQL unless performance-critical)
- Create a migration for every schema change
- NEVER manually edit migration files — regenerate if needed
- Seed data goes in a dedicated seeder class
- Use transactions for multi-step writes

## Key Commands

<!-- Replace with YOUR project's actual commands -->
| Command | Purpose |
|---------|---------|
| `dotnet build` / `npm run build` | Build the project |
| `dotnet test` / `npm test` | Run tests |
| `dotnet ef migrations add {Name}` | Create database migration |
| `dotnet ef database update` | Apply migrations |

## Implementation Checklist

- [ ] Code follows project conventions (read reference implementation first)
- [ ] New files are registered/imported where needed
- [ ] Database changes have corresponding migrations
- [ ] All endpoints are registered in route configuration
- [ ] DTOs are immutable (readonly/record types)
- [ ] Error handling follows existing patterns
- [ ] Build passes with zero errors after changes
- [ ] No unnecessary dependencies added
