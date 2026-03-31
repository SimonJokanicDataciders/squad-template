---
name: "role-frontend-core"
description: "Core frontend conventions — load first for every frontend task"
domain: "frontend"
confidence: "medium"
source: "manual"
---

# Frontend Developer — Core Skill Bundle

## Project Structure

<!-- Replace with YOUR project's actual directory layout. Example: -->
```
src/
├── app/
│   ├── {feature}/           # One folder per feature
│   │   ├── {feature}.routes.ts      # Lazy-loaded routes
│   │   ├── {feature}-list/          # List component
│   │   ├── {feature}-detail/        # Detail component
│   │   ├── {feature}-form/          # Create/edit form
│   │   └── {feature}.service.ts     # API service
│   ├── shared/              # Shared components, pipes, directives
│   └── app.routes.ts        # Root route configuration
├── components/              # Reusable UI components
├── stores/                  # State management (if applicable)
├── types/                   # Shared TypeScript interfaces
├── api/                     # API client layer
└── assets/                  # Static assets
```

## Component Pattern

<!-- Replace with YOUR component pattern. Example: -->
```
// Your component pattern goes here
// Copy a REAL component from your reference implementation
// Include: imports, component decorator/function, props/inputs, template
```

**Rules:**
- One component per file
- Use strict TypeScript — no `any` types
- Handle loading, error, and empty states
- Props/inputs should have clear types and defaults
- Cleanup subscriptions/effects on destroy

## Service / Data Access Pattern

<!-- Replace with YOUR service pattern. Example: -->
```
// Your API service pattern goes here
// Copy a REAL service from your reference implementation
// Include: HTTP client usage, error handling, type mapping
```

**Rules:**
- All API calls through a service layer (never call fetch/http directly in components)
- Type all request/response shapes — match backend DTOs exactly
- Handle errors consistently (show user-friendly messages)

## Routing Pattern

<!-- Replace with YOUR routing conventions. Example: -->
- Lazy-load feature routes for code splitting
- Use guards for authenticated routes
- Define routes in a dedicated routes file per feature
- Register feature routes in the root router via `loadChildren` or dynamic imports

## State Management

<!-- Replace with YOUR state management approach. Example: -->
- Use signals/stores for shared state (Zustand, NgRx signals, Vue Pinia)
- Component-local state for UI-only concerns
- Persist auth state to localStorage if needed
- Keep stores focused — one store per domain

## Frontend Checklist

- [ ] Components follow project conventions (read reference implementation first)
- [ ] Types/interfaces match backend DTOs exactly
- [ ] Routes are properly registered and lazy-loaded
- [ ] No `any` types used anywhere
- [ ] Loading, error, and empty states handled
- [ ] No `innerHTML` with user input
- [ ] Build passes with zero errors after changes
- [ ] Lint passes with zero warnings
