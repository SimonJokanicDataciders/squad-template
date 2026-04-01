# Premium Request Comparison: Squad vs Standard Copilot

> **Note:** This comparison uses an [optimized Squad template](https://github.com/SimonJokanicDataciders/squad-template)
> — not the default `squad init` setup. The template includes a custom coordinator with auto-proceed pipeline,
> per-agent model routing (opus for architecture, sonnet for code, haiku for docs), self-validation before handoff,
> and context caching across agent spawns. These optimizations are what make the efficiency gains below possible.

## Methodology

Both scenarios use the same task: `stress-test.md` — build a complete React 19 + TypeScript dashboard with layout, charts, data table, forms/settings, auth/state, and 194 tests.

- **Squad (optimized template):** Measured from real stress test (Squad1.3)
- **Standard Copilot:** Calculated by tracing the minimum prompts an experienced developer would need, with optimal model selection per prompt

### Premium Request Cost per Model

| Model | Cost per Prompt | Tier |
|-------|----------------|------|
| `claude-opus-4.6` | 3 Premium Requests | Premium |
| `gpt-5.4` | 1 Premium Request | Standard |
| `claude-sonnet-4.6` | 1 Premium Request | Standard |
| `claude-haiku-4.5` | 0.33 Premium Requests | Fast |
| `gpt-4.1` | 0 Premium Requests | Free |

---

## Standard Copilot: Experienced Developer Walkthrough

An experienced developer would create instruction markdown files, batch related work, and pick the right model per prompt. This is the **best case** — a less experienced dev would need more prompts.

### Phase 0: Project Setup (2 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 1 | "Scaffold Vite + React 19 + TS + Tailwind project with these deps: zustand, react-router-dom, recharts, react-hook-form, zod" | gpt-5.4 | 1 |
| 2 | "Create src/types/index.ts with all shared interfaces: User, DashboardMetrics, TaskItem, AuthState, Theme, TableColumn, ToastNotification" | gpt-5.4 | 1 |

**Subtotal: 2 Premium Requests**

### Phase 1: Layout & Navigation (3 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 3 | "Create AppShell with responsive sidebar, top navbar, dark/light theme toggle with system preference, breadcrumbs" | gpt-5.4 | 1 |
| 4 | "Add mobile hamburger menu with animated slide-in drawer and skeleton loading states for page transitions" | gpt-5.4 | 1 |
| 5 | Fix TypeScript/styling issues from above | haiku | 0.33 |

**Subtotal: 2.33 Premium Requests**

### Phase 2: Dashboard Page (3 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 6 | "Create dashboard with summary cards (animated counters), line chart (30d revenue), bar chart (users/region), donut chart (traffic sources) using Recharts" | gpt-5.4 | 1 |
| 7 | "Add WebSocket mock activity feed showing last 50 events, make all charts responsive and theme-aware" | gpt-5.4 | 1 |
| 8 | Fix chart rendering / responsive issues | haiku | 0.33 |

**Subtotal: 2.33 Premium Requests**

### Phase 3: Data Table (4 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 9 | "Create generic DataTable component with server-side pagination, sorting, filtering, column resizing, drag & drop reorder" | opus | 3 |
| 10 | "Add row selection (shift-click multi), inline cell editing with validation, CSV export, keyboard navigation" | gpt-5.4 | 1 |
| 11 | "Create Users page rendering DataTable with 10K virtualized mock rows" | gpt-5.4 | 1 |
| 12 | Fix virtualization / performance issues | gpt-5.4 | 1 |

**Subtotal: 6 Premium Requests**

### Phase 4: Forms & Settings (4 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 13 | "Create form builder with react-hook-form + zod. Settings page with 4 tabs: Profile (avatar, name, email, bio), Notifications (toggles), Security (password strength, 2FA), Billing (plan cards)" | gpt-5.4 | 1 |
| 14 | "Add password strength meter, mock Stripe checkout, feature comparison on billing tab" | gpt-5.4 | 1 |
| 15 | "Create toast notification system (success/error/warning/info with auto-dismiss)" | gpt-5.4 | 1 |
| 16 | Fix form validation / tab switching issues | haiku | 0.33 |

**Subtotal: 3.33 Premium Requests**

### Phase 5: Auth & State (3 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 17 | "Create Zustand stores with slices: auth, ui, dashboard, settings. Add mock auth flow: login, register, forgot password, email verification" | gpt-5.4 | 1 |
| 18 | "Create ProtectedRoute with role-based access (admin/user/viewer), persist auth to localStorage, JWT interceptor with 401 refresh" | gpt-5.4 | 1 |
| 19 | Fix auth flow / state persistence issues | haiku | 0.33 |

**Subtotal: 2.33 Premium Requests**

### Phase 6: Route Wiring & Integration (2 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 20 | "Wire all routes together in App.tsx with React Router v7, lazy-load all pages, connect ProtectedRoute" | gpt-5.4 | 1 |
| 21 | Fix build warnings (chunk size, missing imports, route conflicts) | gpt-5.4 | 1 |

**Subtotal: 2 Premium Requests**

### Phase 7: Tests (6 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 22 | "Write tests for Layout components (AppShell, Sidebar, Navbar, useTheme) and Auth flow (login, register, ProtectedRoute)" | gpt-5.4 | 1 |
| 23 | "Write tests for Dashboard (charts, summary cards, activity feed) and Data Table (pagination, sorting, editing, selection)" | gpt-5.4 | 1 |
| 24 | "Write tests for Forms/Settings (validation, tabs, toast) and Zustand stores (auth, ui, dashboard)" | gpt-5.4 | 1 |
| 25 | "Write integration test: login → dashboard → navigate → edit table → change settings" | gpt-5.4 | 1 |
| 26 | Fix TypeScript errors in tests (unused imports, missing types, vitest config) | gpt-5.4 | 1 |
| 27 | Fix more test failures (assertion errors, async timing, mock setup) | gpt-5.4 | 1 |

**Subtotal: 6 Premium Requests**

### Phase 8: Storybook (2 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 28 | "Create Storybook stories for all shared components: Button, DataTable, FormField, Toast, AppShell, Sidebar" | gpt-5.4 | 1 |
| 29 | Fix Storybook dependency/version issues | haiku | 0.33 |

**Subtotal: 1.33 Premium Requests**

### Phase 9: Final Validation (2 prompts)

| # | Prompt | Model | Cost |
|---|--------|-------|------|
| 30 | "Run npm build, fix any remaining lint/build warnings" | gpt-5.4 | 1 |
| 31 | "Run npm test, fix any remaining test failures to hit 80% coverage" | gpt-5.4 | 1 |

**Subtotal: 2 Premium Requests**

---

## Total: Standard Copilot (Experienced Developer)

| Phase | Prompts | Premium Requests |
|-------|---------|-----------------|
| Setup | 2 | 2.00 |
| Layout | 3 | 2.33 |
| Dashboard | 3 | 2.33 |
| Data Table | 4 | **6.00** |
| Forms & Settings | 4 | 3.33 |
| Auth & State | 3 | 2.33 |
| Route Wiring | 2 | 2.00 |
| Tests | 6 | **6.00** |
| Storybook | 2 | 1.33 |
| Final Validation | 2 | 2.00 |
| **TOTAL** | **31 prompts** | **~29.65 Premium Requests** |

Model breakdown:
- 1 × opus (DataTable complexity) = 3 requests
- 24 × gpt-5.4 = 24 requests
- 5 × haiku (simple fixes) = 1.65 requests

**Rounded: ~30 Premium Requests**

> This is the **best case** — an experienced developer who batches prompts and manually picks the optimal model per prompt. In reality, **most developers don't switch models per prompt**. They use whatever their CLI is set to:
>
> - If set to **gpt-5.4**: 31 prompts × 1 = **31 Premium Requests**
> - If set to **opus**: 31 prompts × 3 = **93 Premium Requests**
> - If set to **gpt-4.1** (free): 31 × 0 = **0 Premium Requests** (but lower quality output)
>
> The ~30 request estimate assumes the developer actively optimizes model selection — which is generous to Standard Copilot. A less experienced developer would need 40-50+ prompts.

---

## Total: Squad Agent (Measured)

```
Task: Same stress-test.md — one prompt

Duration:     ~1h 45m
Test files:   30 (194 passing tests)
Agents used:  6 + sub-agents

Model Usage (from Copilot billing):
  gpt-4.1           823.8K in     (Est. 0 Premium)
  gpt-5.4           9.0M in      (Est. 2 Premium)
  claude-opus-4.6   11.7M in     (Est. 0 Premium — 90% cached)
  claude-haiku-4.5  240.7K in    (Est. 0 Premium)

Total Premium Requests: 2
```

---

## Comparison

| | Standard Copilot | Squad (optimized) |
|---|---|---|
| **Prompts** | 31 | 1 |
| **Premium Requests** | ~30 | 1-3 |
| **Developer Time** | Active for ~2-3 hours (writing prompts, reviewing, fixing) | Passive for ~1h 45m (Squad runs autonomously) |
| **Context Management** | Developer must maintain mental model across 31 prompts | Agents share context via inlined charters |
| **Error Fixing** | Developer writes fix prompts (~6 prompts just for fixes) | Agents self-validate before handoff |
| **Model Optimization** | Developer must manually pick model per prompt | Automatic per-agent routing |

> **1-3 Premium Requests with Squad:** Best case is 1 request (everything runs through). In practice, the coordinator may ask 1-2 clarifying questions (e.g., ambiguous scope or missing conventions), resulting in 2-3 requests. The stress test measured 2 requests.

### Savings

- **Premium Requests:** ~30 → 1-3 = **90-97% reduction**
- **Developer Active Time:** ~2-3 hours → ~5 min (write prompt + review final result)
- **Total Time:** Similar (~2 hours), but developer is free during Squad execution

---

## Where the Difference Comes From

### 1. Context caching

With standard Copilot, every prompt starts a fresh conversation. The model re-reads your codebase context each time — and you pay for those tokens each time.

With the optimized template, the coordinator reads all context once (charters, history, decisions, project map) and inlines it into every agent spawn. Because the context is identical across spawns, 90% of tokens hit the cache — which means they're effectively free.

*In the stress test, 10.5M of 11.7M opus tokens were cached. That's context reuse you can't achieve with sequential prompts.*

### 2. Parallel execution

A developer works sequentially: write prompt → wait for result → review → write next prompt. Each step blocks the next.

The template's coordinator identifies which agents can work simultaneously. While the backend agent writes endpoints, the QA agent is already planning tests from the architecture spec. While the frontend agent builds components, the docs agent captures decisions in the background.

*The same ~2 hours of compute, but the developer writes one prompt and reviews one result instead of managing 31 prompt-response cycles.*

### 3. Self-validation

In the stress test walkthrough above, 6 of 31 prompts (~19%) are just fixing errors from previous prompts. TypeScript errors, missing imports, lint failures, version mismatches.

The template's agents run build and lint verification before marking their work as done. Errors get caught and fixed by the agent that created them — not by the developer in a follow-up prompt.

*Fewer fix prompts = fewer premium requests = less developer time spent on error ping-pong.*

### 4. Automatic model routing

Most developers don't switch models between prompts. They set one model and use it for everything — architecture decisions on the same tier as typo fixes.

The template routes automatically: opus (3x) for architecture decisions that affect every downstream agent, sonnet (1x) for code generation, haiku (0.33x) for documentation and logs. The right cost tier for the right task, without the developer thinking about it.

*In the stress test, only the architect used opus. Code agents used sonnet. Docs used haiku. Total cost: fraction of what all-opus or all-sonnet would cost.*

---

## Requirements

- **CLI model: GPT-5.1 HIGH** — this is the only model that properly caches premium requests across agent spawns and supports per-agent model routing
- **Optimized Squad template** — the default `squad init` does not include model routing, auto-proceed, or self-validation. Use [this template](https://github.com/SimonJokanicDataciders/squad-template) instead
