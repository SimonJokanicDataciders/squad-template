---
name: "cap-template-role-frontend-core"
description: "Core Angular 21 conventions for Dallas — always load this first. Workspace, structure, patterns, checklist, boundaries."
domain: "frontend"
confidence: "high"
source: "split-from-cap-template-role-frontend"
---

## Context

Always load this bundle first for any Angular/Nx frontend work. It contains the essential conventions, scaffold recipe, and checklist.

For additional topics, load on demand (see "Load on Demand" section at the bottom).

This bundle is self-contained for scaffolding. Dallas does NOT need to read the original `.github/sdlc-phase-agents/` files.

## CAP.Template Frontend Architecture

### Workspace

- **Root:** `src/Paso.Cap.Angular/` — Nx 22.6 monorepo with Angular 21.x
- **Package manager:** npm (via Nx)
- **Test runner:** Jest
- **Linter:** ESLint (Nx-managed)

### Feature Folder Structure

Every feature follows this exact layout inside `src/Paso.Cap.Angular/`:

```
src/app/{feature-name}/
├── routes.ts                              (feature routes, exports {FEATURE}_ROUTES)
├── pages/
│   ├── list/{feature}-list.component.ts   (list page component)
│   └── detail/{feature}-detail.component.ts (detail page component)
└── services/
    └── {feature}.service.ts               (data access service)
```

### App Routing

**File:** `src/app/app.routes.ts`

All features use lazy-loaded routes via `loadChildren`. Add new features following the same pattern:

```typescript
export const routes: Routes = [
  {
    path: 'weather-forecasts',
    loadChildren: () => import('./weather-forecasts/routes').then(m => m.WEATHER_ROUTES),
  },
];
```

## Angular 21 Conventions (Mandatory)

These are non-negotiable patterns for all frontend code in this project.

### Standalone Components with OnPush

Every component MUST use `standalone: true` and `ChangeDetectionStrategy.OnPush`.

### inject() for Dependency Injection

Always use the `inject()` function. Never use constructor injection.

```typescript
// CORRECT
private readonly service = inject({Feature}Service);
private readonly router = inject(Router);

// WRONG — do not use
constructor(private service: {Feature}Service) {}
```

### signal() for Component State

Use `signal()` for reactive state. Use `computed()` for derived values. Use `toSignal()` to bridge RxJS observables to signals.

```typescript
readonly items = signal<{Entity}Dto[]>([]);
readonly loading = signal(false);
readonly itemCount = computed(() => this.items().length);
```

### No Manual subscribe() Without Cleanup

If you must use `subscribe()`, always pair it with `takeUntilDestroyed(this.destroyRef)`. Prefer `toSignal()` or `rxResource` over manual subscriptions.

### No `any` Types

TypeScript strict mode is enforced. Never use `any`. Define proper interfaces/types for all data.

## Service Pattern (concise)

**File:** `src/app/{feature}/services/{feature}.service.ts`

- `@Injectable({ providedIn: 'root' })`
- `private readonly http = inject(HttpClient)`
- `private readonly baseUrl = '/api/{feature-name}'`
- Methods return typed `Observable<T>` — `getAll()`, `getById(id)`, `create(dto)`
- DTO interfaces mirror backend DTOs exactly (field names, types, nullability)

## Lazy-Loaded Routes Pattern (concise)

**File:** `src/app/{feature}/routes.ts`

Export `{FEATURE}_ROUTES: Routes` using `loadComponent` for each page. Register in `app.routes.ts` via `loadChildren`.

## Scaffolding a New Frontend Feature — 5 Steps

### Step 1: Generate the Components (via Nx)

```bash
cd src/Paso.Cap.Angular
npx nx generate @nx/angular:component {feature}-list --project=app --path=src/app/{feature}/pages/list
npx nx generate @nx/angular:component {feature}-detail --project=app --path=src/app/{feature}/pages/detail
```

### Step 2: Create the Service

Create `src/app/{feature}/services/{feature}.service.ts` — DTO interfaces must match backend DTOs exactly.

### Step 3: Create Feature Routes

Create `src/app/{feature}/routes.ts` with `loadComponent` for list and detail pages, exporting `{FEATURE}_ROUTES`.

### Step 4: Register in App Routes

Add to `src/app/app.routes.ts`:

```typescript
{
  path: '{feature-name}',
  loadChildren: () => import('./{feature}/routes').then(m => m.{FEATURE}_ROUTES),
},
```

### Step 5: Verify

```bash
cd src/Paso.Cap.Angular
npx nx serve     # Dev server — check the feature loads
npx nx test      # Jest tests pass
npx nx lint      # ESLint passes
```

## Full-Stack Scaffolding Awareness

When aligning DTO types with the backend, refer to this layer table:

| Layer | File |
|-------|------|
| Entity | `src/Paso.Cap.Domain/{FeatureName}/{EntityName}.cs` |
| EF Config | `src/Paso.Cap.Domain/{FeatureName}/{EntityName}Configuration.cs` |
| DTOs | `src/Paso.Cap.Domain/{FeatureName}/{EntityName}Dto.cs`, `Create{EntityName}Dto.cs` |
| Service | `src/Paso.Cap.Domain/{FeatureName}/{FeatureName}Service.cs` |
| DbContext | `src/Paso.Cap.Domain/ApplicationDbContext.cs` (add DbSet) |
| DI | `src/Paso.Cap.Domain/DomainServiceExtensions.cs` (register service) |
| Feature flag | `src/Paso.Cap.Shared/Features.cs` |
| Endpoint | `src/Paso.Cap.Web/Endpoints/{FeatureName}.cs` |
| Migration | `dotnet ef migrations add Add{FeatureName} ...` |

Backend conventions: sealed classes, immutable records for DTOs, inline `Select()` projections (no AutoMapper), `CancellationToken` on every async method, feature flags via `Features.{FeatureName}.IsEnabled`.

## Frontend Checklist

Before completing any frontend task, verify:

- [ ] Service uses `inject()` for DI, not constructor injection
- [ ] Components are `standalone: true` with `ChangeDetectionStrategy.OnPush`
- [ ] Component state uses `signal()`, not plain class properties
- [ ] Routes are lazy-loaded via `loadChildren` / `loadComponent`
- [ ] No manual `subscribe()` without `takeUntilDestroyed()` cleanup (or use signals)
- [ ] TypeScript types match backend DTOs exactly
- [ ] No `any` types anywhere
- [ ] Feature route registered in `app.routes.ts`
- [ ] No `innerHTML` with user input (XSS risk)
- [ ] No circular Nx dependencies introduced

## Nx Commands

```bash
cd src/Paso.Cap.Angular
npx nx serve                    # Dev server
npx nx test                     # Jest tests
npx nx lint                     # ESLint
npx nx generate @nx/angular:component {name} --project=app --path={path}
```

## Routing and Delivery Flow

```
design -> plan -> implement / frontend / database -> lint -> test -> integration-test -> review -> build -> deploy -> monitor
                      |                                                                                        |
                  scaffold (optional)                                                                  document (parallel)
```

Dallas is the **eager overlay** for all Angular/Nx work. Backend (implement) and frontend (Dallas) proceed in parallel after plan produces `plan.tasks`.

### Routing Rules

1. If Dallas is available and the work involves Angular/Nx, Dallas handles it rather than a generic implement agent.
2. New entity on backend → also queue frontend if Angular UI is enabled.
3. New endpoint → verify frontend service alignment.
4. Any user-facing change → escalate documentation to Scribe.
5. Changes to OIDC config or feature flags controlling production features must trigger secure review.

## Boundaries

- **Always do:** Use standalone components, OnPush, signals, `inject()`, lazy routes, feature-folder structure
- **Ask first:** Adding new npm dependencies, creating new Nx libraries, changing Nx workspace config
- **Never do:** Use `innerHTML` with user input, skip TypeScript types, create circular Nx dependencies, use constructor injection, use `any`

## When to Stop and Ask

Stop and ask the user before proceeding if:
- The component hierarchy or state management approach is unclear
- A new npm dependency is needed
- New Nx library boundaries need to be defined
- The API contract from the backend is not yet finalized
- The feature requires patterns not yet established in the codebase

## Squad Collaboration

- **Dallas + Fenster:** Contract alignment — ensure frontend DTOs match backend contracts exactly
- **Dallas + Scribe:** Developer-facing walkthroughs, setup notes, usage documentation for UI features
- If the current slice has no active frontend code, focus on: user flow implications, naming/usability of endpoints, setup/onboarding clarity

## Anti-Patterns

- Do not force a frontend phase into purely backend work
- Do not invent a UI surface that the repository slice does not actually contain
- Do not let UI wording drift away from the underlying API or workflow behavior
- Do not use method groups in EF `.Select()` (backend awareness)
- Do not skip feature flags when scaffolding new features

---

## Load on Demand

Load these modules only when the task requires them — do not load all three upfront.

| Module | When to load |
|--------|-------------|
| `cap-template-role-frontend-forms.md` | Task involves forms, user input, validation, or data entry |
| `cap-template-role-frontend-material.md` | Task involves UI styling, Angular Material components, error handling, or API client integration |
| `cap-template-failure-patterns.md` | Task involves code review or analysis |
