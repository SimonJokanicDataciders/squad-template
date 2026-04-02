# Lead Architecture Analysis

> Squad-Template v0.9.1 — Deep system analysis
> Analyst: Lead (Architect)
> Date: 2026-04-15

---

## 1. Coordinator Design

The coordinator prompt (`.github/agents/squad.agent.md`, 1312 lines) is the heart of the system. It defines the full orchestration protocol inline, with 14 on-demand modules loaded from `.copilot/skills/coordinator/` (2061 lines total).

### Strengths

1. **Critical Rules at the top (lines 12–82):** 11 hard-won rules placed where they survive context truncation — excellent defensive design. Each rule clearly addresses a specific failure mode observed in stress testing.

2. **On-demand module loading (lines 86–104):** Smart keyword-based lazy loading. Only `squad-preflight.md` loads unconditionally; the rest are triggered by specific user phrases. This keeps the always-loaded context to ~1312 lines instead of ~3373 (1312+2061).

3. **Model selection hierarchy (lines 486–551):** 6 layers, well-ordered. The fallback chains per tier are practical and handle plan restrictions gracefully. The nuclear fallback (omit model param entirely) is a good last-resort.

4. **Session expiry handling (lines 52–56, Rule 7):** The system explicitly acknowledges that agent sessions expire and provides a concrete recovery path via `status.md` files — a mature design born from production experience.

5. **Auto-proceed philosophy (lines 563–619):** The BANNED PHRASES list and explicit auto-proceed rules are aggressively anti-friction. This is the single biggest UX win.

### Gaps / Issues

1. **Redundant BANNED PHRASES blocks.** The BANNED PHRASES list appears at **line 17** (Critical Rule 1) AND **line 576** (Eager Execution section). Identical content, 100% duplication. While redundancy in critical rules can be intentional (survive truncation), these are close enough in the file that only one is needed.
   - `squad.agent.md:17-22` vs `squad.agent.md:576-589`

2. **Init Mode exception buried.** Line 563 says "Eager Execution does NOT apply during Init Mode Phase 1." But Critical Rule 1 (line 14) says "NEVER ASK — JUST DO" with no mention of the Init Mode exception. A coordinator under context pressure may follow Rule 1 and skip the Init Mode confirmation step.
   - `squad.agent.md:14-15` vs `squad.agent.md:563`

3. **Coordinator does domain work in some paths.** Rule at line 141: "You may NOT generate domain artifacts (code, designs, analyses) — spawn an agent." But lines 1050–1072 instruct the coordinator to directly run build/test validation commands. And the Phase 0 project scan in `squad-onboard.md:46-61` is also coordinator-direct. These are pragmatic exceptions but they contradict the stated rule.
   - `squad.agent.md:141` vs `squad.agent.md:1050-1072` vs `squad-onboard.md:46-61`

4. **Instruction hierarchy ambiguity for VS Code mode.** The Session module (`squad-session.md:78-121`) describes VS Code adaptations that conflict with main coordinator rules (e.g., "Drop agent_type, mode, model, description parameters"). When does VS Code behavior override the main prompt? No explicit priority is stated.
   - `squad-session.md:88-106`

5. **No explicit version gating on module loading.** The coordinator has a version (`0.9.1`, line 6), but modules have no version markers. During upgrades (`init.sh --upgrade`), the coordinator prompt is overwritten but there's no mechanism to validate that the loaded modules are compatible with the new coordinator version.
   - `squad.agent.md:6`, `init.sh:82-118`

6. **Pre-flight always runs but could be wasteful.** The pre-flight module (`squad-preflight.md`, 115 lines) loads unconditionally. For read-only tasks (research, review, status checks), environment detection is unnecessary overhead.
   - `squad.agent.md:101` — "ALWAYS — run in bootstrap turn before any work"

### Recommendations

1. Remove the duplicate BANNED PHRASES block at line 576. Keep only the one in Critical Rules.
2. Add an explicit exception to Critical Rule 1: "Exception: Init Mode Phase 1 requires user confirmation (see squad-init-mode.md)."
3. Reconcile the "no domain work" rule with the build/test validation path by carving out explicit exceptions: "The coordinator MAY run build/test commands and project scans directly."
4. Add a `min_coordinator_version` field to module frontmatter for upgrade safety.
5. Make pre-flight conditional: only run when the task will involve building/testing (Development context), skip for Research/Review contexts.

---

## 2. Agent Charter Quality

Six agents: Lead, Backend, Frontend, Tester, Scribe, Ralph. Charters live at `.squad/agents/{name}/charter.md`.

### Consistency Analysis

| Element | Lead | Backend | Frontend | Tester | Scribe | Ralph |
|---------|------|---------|----------|--------|--------|-------|
| Project Context section | ✅ | ✅ | ✅ | ✅ | ✅ (diff format) | ✅ (diff format) |
| Model section | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tools section | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Responsibilities | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Guardrails | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Scope Boundaries (DO/DON'T) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sub-Agent Capability | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Work Style | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Skill Loading Protocol | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Handoff Protocol | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Review Checklist | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ (Security) |
| Reference Implementation | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Strengths

1. **Consistent structure.** All 6 charters follow the same section ordering: Context → Model → Tools → Responsibilities → Guardrails → Scope → Sub-Agent → Work Style. This makes them scannable and predictable.

2. **Clear scope boundaries.** Every charter has an explicit DO/DON'T section with cross-references to other agents. Lead says "Don't write code (route to Backend/Frontend)." Backend says "Don't write tests (route to Tester)." These boundaries are non-overlapping and well-defined.

3. **Tool scoping.** Each charter restricts tools to what the role needs:
   - Lead: Read-only (Read, Grep, Glob) — `lead/charter.md:19`
   - Backend/Frontend/Tester: Full access — `backend/charter.md:19`
   - Scribe: No Bash — `scribe/charter.md:17`
   - Ralph: No Edit/Write — `ralph/charter.md:13`

4. **Self-validation requirements.** Backend (`charter.md:65`), Frontend (`charter.md:64`), and Tester (`charter.md:77`) all require running build/lint before marking done. This prevents cascading failures.

### Gaps / Issues

1. **No Skill Loading Protocol in any charter.** The charter template (`.squad/templates/charter.md:31-35`) defines a `## Skill Loading Protocol` section with on-demand module loading, but NONE of the 6 actual charters include it. Instead, the coordinator's spawn prompt (line 808) tells agents to read their primary bundle. This means agents have no awareness of on-demand skill modules.
   - `.squad/templates/charter.md:31-35` (defined) vs `.squad/agents/*/charter.md` (missing)

2. **No Reference Implementation field.** The charter template (`templates/charter.md:7`) has `Reference implementation: {path}`, but none of the actual charters populate it. This is critical for grounding agent output — the wisdom file (`wisdom.md`) says "Role bundles should embed knowledge, not reference file paths," but reference implementations are different from file path references.
   - `templates/charter.md:7` vs all actual charters

3. **Scribe and Ralph use different Project Context format.** Lead/Backend/Frontend/Tester use bulleted lists with `- **Project:**`, `- **Role:**`, etc. Scribe and Ralph use a flat `**Project:**` format without the list bullets. Minor inconsistency.
   - `scribe/charter.md:5-8` vs `lead/charter.md:5-11`

4. **Handoff Protocol missing from implementation agents.** Scribe and Ralph have Handoff Protocol sections. Backend, Frontend, and Tester don't — even though they're the primary producers and consumers of handoff documents (per `squad-handoffs.md`).
   - `scribe/charter.md:66-69`, `ralph/charter.md:57-61` vs backend/frontend/tester (absent)

5. **Lead charter says "Read-only" but Lead writes decisions.** `lead/charter.md:19` says "Allowed: Read, Grep, Glob (read-only — architecture does not write code)." But Lead needs to write to `.squad/decisions/inbox/` and `.squad/agents/lead/history.md`. This is tool scoping, not actual enforcement, but the stated rationale is misleading.
   - `lead/charter.md:19`

6. **Missing "Primary bundle" field from all charters.** The spawn prompt template (`squad.agent.md:808`) tells agents: "Read your PRIMARY SKILL BUNDLE listed in your charter's 'Primary bundle' field." But only Scribe (`charter.md:8`) and Ralph (`charter.md:8`) have a `Primary bundle` field. Lead, Backend, Frontend, and Tester have `Skill bundle(s)` or `Skill bundle` instead. The field name mismatch means agents won't find their bundle.
   - `squad.agent.md:808` references "Primary bundle" vs `lead/charter.md:11` uses "Skill bundles", `backend/charter.md:10` uses "Skill bundle"

### Recommendations

1. Add `## Skill Loading Protocol` to all 6 charters. At minimum: "ALWAYS: Read primary bundle. On code review: also read failure-patterns.md."
2. Standardize the `Primary bundle` field name across all charters to match what the spawn prompt expects.
3. Add `## Handoff Protocol` to Backend, Frontend, and Tester — they need to know what to produce for downstream agents.
4. Correct Lead's tool section: "Allowed: Read, Grep, Glob, Write (decisions inbox and history only)."
5. Add `Reference implementation` to all charters once projects have one (populated by onboarding learn mode).

---

## 3. System Architecture (3-Tier)

### Tier 1: Core Engine (`core/`)

Contains the universal coordinator prompt, skill modules, state templates, and workflows. Tech-stack-agnostic. ~3373 lines total (1312 coordinator + 2061 modules).

**Separation is clean.** Core has zero technology-specific references. All `.NET`, `React`, `Express`, etc. knowledge lives in Tier 2 (stacks/seeds). The coordinator detects project type dynamically (`squad.agent.md:29-37`).

### Tier 2: Stack Presets (`stacks/`)

```
stacks/
├── _template/          # Blank preset scaffold
├── dotnet-angular/     # Full preset: charters, skills, routing, casting
├── rules/              # Language-specific coding rules
│   ├── common/         # Universal: coding-style, security, testing, git-workflow
│   ├── csharp/         # C#-specific rules
│   ├── typescript/     # TS-specific rules
│   └── python/         # Python-specific rules
└── seeds/              # 15 curated convention files for common frameworks
```

**The preset vs seed distinction is sound:**
- **Presets** = full stack configurations (agent charters + skills + routing + casting). Heavy, opinionated, pre-configured. Currently only `dotnet-angular` exists.
- **Seeds** = lightweight convention files (~60-80 lines each) that feed Bootstrap Mode. Technology-agnostic format, high-value density.

### Tier 3: Per-Project (generated at runtime)

Created by `init.sh` or Squad's Init Mode. Contains team-specific state: `team.md`, agent histories, decisions, casting registry, project map.

### Strengths

1. **Clean separation.** Core changes don't affect per-project state. `init.sh --upgrade` (line 66-118) explicitly preserves `team.md`, `decisions`, `agent histories`, and `config.json` while overwriting `squad.agent.md`, skills, workflows, and seeds.

2. **Seed system is elegant.** Seeds are tiny (~60-80 lines), have YAML frontmatter with `matches` arrays for keyword matching, and include structured sections: Critical Rules, Golden Example, Common LLM Mistakes. This is a high-leverage format — small input, large output quality improvement.

3. **Drop-box pattern for decisions.** Agents write to `decisions/inbox/{name}-{slug}.md`, Scribe merges to `decisions.md`. No file conflicts on parallel writes. The `merge=union` gitattributes driver handles cross-branch merging. Elegant distributed state management.
   - `squad.agent.md:710-712`, `init.sh:53-59` (the gitattributes template in init.sh)

4. **Duplicate seeds are synchronized.** Seeds exist in both `stacks/seeds/` (source) and `.squad/seeds/` (target). `init.sh` copies from source to target, and `--upgrade` refreshes them. Single source of truth maintained.

### Gaps / Issues

1. **Only one full preset exists.** `dotnet-angular` is the only non-template preset. For the system to be widely adoptable, it needs at least: `express-react`, `fastapi-react`, `nextjs`, `dotnet-react`. Seeds alone aren't enough — presets include agent charters with stack-specific guardrails, specialized routing, and casting.
   - `stacks/` directory listing

2. **No preset for the most common stacks.** Express + React is arguably the most common web stack. No preset exists for it, even though both `express.seed.md` and `react.seed.md` exist. The gap between "seeds exist" and "full preset exists" is significant.

3. **Rules are only copied when a preset is used.** `init.sh:488-509` copies language rules only inside the `if [[ -n "$STACK" ]]` block. The `else` block at line 612 also copies rules (lines 612-634), but only when `DETECTED_TECHS` is non-empty. If `--auto` is not passed, `DETECTED_TECHS` may be empty even if tech was detected.
   - `init.sh:496-509` vs `init.sh:619-633`
   - Actually: `detect_stack` is called at line 211 when no `--auto` and no `--stack`, so `DETECTED_TECHS` IS populated. The logic is correct but confusing.

4. **Core duplicates state in `core/.squad/` and root `.squad/`.** The template repo itself has `.squad/` at the root (the live state for the squad-template project) AND `core/.squad/` (the template to copy). This creates confusion about which is the source of truth for templates. Some files like `config.json` are in `core/.squad/` but the root `.squad/config.json` has different content.
   - `core/.squad/config.json` vs `.squad/config.json`

5. **No mechanism to compose presets.** If someone wants `dotnet + react` (instead of `dotnet + angular`), they'd need a whole new preset. There's no way to say "use dotnet-backend preset + react-frontend preset." The seed system partially addresses this but seeds don't include charters or routing.

6. **`.github/instructions/` rules are not referenced by any agent charter.** `init.sh` copies rules to `.github/instructions/`, but no agent charter or skill module references this directory. These rules only work because GitHub Copilot natively reads `.github/instructions/` — but if the system is used outside GitHub Copilot, the rules are invisible.
   - `init.sh:489-509` copies to `.github/instructions/` — no charter references this path

### Recommendations

1. **Create 2-3 more presets** as first-class stacks: `express-react`, `fastapi-react`, `nextjs-fullstack`. Use the `_template` scaffold + existing seeds as the basis.
2. **Consider composable presets.** Split presets into `backend-*` and `frontend-*` halves that can be combined. E.g., `init.sh --backend dotnet --frontend react`.
3. **Add `.github/instructions/` reference to the onboard module** so agents know to check those rules.
4. **Document the `core/` vs root `.squad/` distinction** clearly. Consider using symlinks or a build step to prevent drift.

---

## 4. Skill Bundle System

### Module Inventory

14 on-demand modules in `.copilot/skills/coordinator/`:

| Module | Lines | Trigger | Assessment |
|--------|-------|---------|------------|
| squad-onboard.md | 538 | No skill bundles | **Core — well-scoped, thorough** |
| squad-issues.md | 204 | "issue", "triage" | **Core — well-scoped** |
| squad-session.md | 146 | "session recovery" | **Good — covers VS Code compat** |
| squad-infrastructure.md | 146 | "kubernetes", "scale" | **Speculative — no user evidence** |
| squad-comms.md | 140 | "external", "community" | **Speculative — no user evidence** |
| squad-plugins.md | 132 | "plugin", "extend" | **Speculative — marketplace not built** |
| squad-casting.md | 131 | "cast", "rename" | **Core — well-scoped** |
| squad-handoffs.md | 117 | "handoff", "orchestrate" | **Core — critical for quality** |
| squad-preflight.md | 115 | ALWAYS | **Core — prevents 60% of wasted time** |
| squad-mesh.md | 95 | "mesh", "cross-squad" | **Speculative — no implementation** |
| squad-worktrees.md | 94 | "worktree", "cleanup" | **Good — addresses real workflow** |
| squad-artifacts.md | 73 | "artifact format" | **Good — clear format spec** |
| squad-init-mode.md | 69 | "init", "create team" | **Core — well-scoped, tight** |
| squad-contexts.md | 61 | "mode", "context" | **Good — simple and effective** |

Plus 1 shared file: `failure-patterns-global.md` (167 lines) — cross-cutting, always available.

### Strengths

1. **Loading strategy is efficient.** Total module content: 2061 lines. Always-loaded: ~115 lines (preflight). The coordinator only reads modules when keyword triggers match. This saves ~1946 lines of context most of the time.

2. **Module scoping is generally clean.** Each module handles one concern. No module tries to do two things. The boundaries are clear: casting is about names, sessions are about recovery, handoffs are about agent-to-agent communication.

3. **Onboard module is the most critical and most thorough (538 lines).** It handles three modes (Phase 0: project scan, Phase A: learn from code, Phase B: bootstrap from prompt) and includes the Knowledge Gate pattern (ask user for conventions when no seeds match). This is the right module to invest the most lines in.

4. **Pre-flight module justifies its always-loaded status.** The wisdom file records that 60% of a stress test session was wasted on environment issues. Pre-flight catches SDK mismatches, missing Docker, port conflicts, and Python version mismatches upfront.

### Gaps / Issues

1. **Three modules are speculative with no implementation backing.** `squad-mesh.md`, `squad-infrastructure.md`, and `squad-plugins.md` describe systems that don't exist yet (no `squad-cli`, no KEDA integration, no plugin marketplace, no mesh sync). They consume 373 lines of potential context for features that have zero users.
   - `squad-mesh.md:51-63` references `npx @bradygaster/squad-cli mesh sync` — this CLI doesn't exist
   - `squad-infrastructure.md:80-105` describes KEDA ScaledJob config — no evidence this is used
   - `squad-plugins.md:42-55` references `squad plugin marketplace browse` — doesn't exist

2. **squad-issues.md has dependency on external CLI.** Lines 149-158 reference `npx @bradygaster/squad-cli watch` — an external dependency that may or may not be installed. The graceful degradation path is not well-defined for when this CLI is absent.
   - `squad-issues.md:149-158`

3. **No module for testing/CI integration.** There's no module for `"CI", "pipeline", "GitHub Actions"` — yet the system ships with 5 workflows. Ralph's charter handles some ops concerns, but there's no structured guidance for when the user wants to discuss CI configuration.

4. **Keyword triggers are imprecise.** `squad-contexts.md` triggers on "mode" and "context" — extremely common words that could fire on unrelated requests ("dark mode toggle", "provide more context"). Similarly, `squad-infrastructure.md` triggers on "scale" which could mean "scale the UI" (frontend task).
   - `squad.agent.md:95` — "scale" trigger for infrastructure
   - `squad.agent.md:102` — "mode", "context" trigger for contexts

5. **No module versioning.** Modules have no version, no `updated` date, no `min_coordinator_version`. During `init.sh --upgrade`, all modules are overwritten unconditionally (`init.sh:87`). If a user customized a module, it's silently lost.

### Recommendations

1. **Move speculative modules to a `future/` directory.** Keep `squad-mesh.md`, `squad-infrastructure.md`, and `squad-plugins.md` out of the active module set until implementations exist. This saves 373 lines of dead module references.
2. **Add a CI/Pipeline module** triggered by "CI", "pipeline", "GitHub Actions", "workflow". Document how the 5 shipped workflows work and how to customize them.
3. **Tighten keyword triggers.** Use more specific trigger phrases: "scale infrastructure" instead of just "scale". "Development mode" instead of just "mode".
4. **Add version frontmatter to all modules** with `updated` date and `requires_coordinator: >=0.9.0`.
5. **Mark customizable modules.** During upgrade, warn before overwriting modules that have local modifications (check git diff).

---

## 5. Stack/Seeds System

### Seed Quality Assessment

**Sample 1: `express.seed.md`** (81 lines)
- ✅ YAML frontmatter with `matches`, `version`, `status: "verified"`
- ✅ 7 Critical Rules — specific, actionable, no ambiguity
- ✅ Golden Example — complete, production-quality Express 5 + Zod + asyncHandler pattern
- ✅ Common LLM Mistakes — 5 specific anti-patterns with explanations
- ✅ Version-pinned to Express 5.x
- **Assessment: Excellent.** This is the gold standard for seed quality.

**Sample 2: `react.seed.md`** (92 lines)
- ✅ All structural elements present
- ✅ Critical Rule 4 is particularly valuable: "Never use `useEffect` for data fetching" — this prevents the most common React mistake LLMs make
- ✅ Golden Example shows React Query + TypeScript interfaces + composition
- ✅ React 19-specific (mentions `use()` hook)
- **Assessment: Excellent.** Comparable quality to Express seed.

**Sample 3: `dotnet-webapi.seed.md`** (69 lines)
- ✅ All structural elements present
- ✅ Critical Rule 1 addresses the most common .NET LLM mistake: mixing Minimal APIs and Controllers
- ✅ Golden Example shows Minimal API with `TypedResults`, `sealed record` DTOs, `MapGroup()`
- ✅ Version-pinned to .NET 9.x
- **Assessment: Excellent.** Tight, authoritative, version-current.

### Preset Model Assessment

The only full preset is `dotnet-angular`:
- Has `cast.conf` for named agents (Alien universe: ripley, dallas, etc.)
- Has custom charters per role
- Has its own routing.md, ceremonies.md, skills/
- Has `.github/instructions/` with stack-specific copilot instructions

**The preset model is sound but under-populated.** The template (`_template/`) is well-structured and provides a clear scaffold for creating new presets.

### Coverage Analysis

**15 seeds available:**
| Category | Seeds | Gap |
|----------|-------|-----|
| Backend frameworks | express, fastapi, dotnet-webapi | ✅ Good — missing: Django, Spring, NestJS, Go/Gin |
| Frontend frameworks | react, angular, vue, nextjs | ✅ Good — missing: Svelte, Astro |
| ORMs | prisma, efcore | ⚠️ Partial — missing: Drizzle, SQLAlchemy, TypeORM, Sequelize |
| Test frameworks | jest, vitest, pytest, xunit | ✅ Good |
| Styling | tailwind | ⚠️ Minimal — missing: CSS modules, Styled Components |
| Other | python-ml | ⚠️ Niche |

**Notable missing seeds:** Django (2nd most popular Python web framework), NestJS (most popular Node.js framework for enterprise), SQLAlchemy (dominant Python ORM), Drizzle (growing TypeScript ORM), Svelte (growing frontend framework).

### Recommendations

1. **Create seeds for the top gaps:** Django, NestJS, SQLAlchemy, Drizzle. These are high-value additions.
2. **Create 2 more full presets:** `express-react-prisma` and `fastapi-react` — covering the most common non-.NET full-stack combos.
3. **Add a seed validation script** that checks all seeds have the required structure (frontmatter, Critical Rules, Golden Example, Common Mistakes).
4. **Consider a seed for Docker/Docker Compose** — many projects need container conventions and it's a common source of LLM mistakes.

---

## 6. Cross-cutting Concerns

### Decision Flow

**Architecture:** Agents → `decisions/inbox/{agent}-{slug}.md` → Scribe merges → `decisions.md`

- ✅ Drop-box pattern prevents file conflicts (`squad.agent.md:710-712`)
- ✅ Union merge driver in `.gitattributes` handles cross-branch merging (`init.sh:53-59`)
- ✅ Source of Truth Hierarchy table clearly defines who writes what (`squad.agent.md:1210-1227`)
- ⚠️ **No merge conflict resolution guidance.** When `decisions.md` has a genuine semantic conflict (two agents made contradictory decisions), the union merge just keeps both lines. No process for detecting or resolving contradictions.
- ⚠️ **No decision archival automation.** The Scribe charter mentions archiving decisions older than 30 days if `decisions.md` exceeds ~20KB (`scribe/charter.md:34`), but there's no automation — it depends on Scribe being spawned and choosing to do it.

### Session State / Agent Session Expiry

**The most battle-tested part of the system.** Three layers of defense:

1. **status.md** — each agent writes working/done/failed state to `.squad/agents/{name}/status.md` (mandated in spawn prompt, `squad.agent.md:835-879`)
2. **orchestration-log/** — coordinator writes change logs immediately after agent completes (`squad.agent.md:1122-1142`)
3. **session-state.md** — coordinator maintains completed/pending/blocked tracking (`squad.agent.md:1143-1158`)

**Strength:** Rule 7 (`squad.agent.md:52-56`) explicitly states that `read_agent` failures are NORMAL and provides a concrete recovery path. This is learned wisdom from production.

**Gap:** The `status.md` format uses YAML frontmatter (`---\nstatus: working\n---`) but there's no validation. If an agent writes malformed YAML, the coordinator may not parse it correctly. No schema or example parsing code exists.

### Upgrade Path Design

`init.sh --upgrade` (lines 66-118):
- ✅ **Preserves**: team.md, decisions, agent histories, config.json, routing.md, ceremonies.md
- ✅ **Overwrites**: coordinator prompt, coordinator skills, seeds, shared failure patterns, identity templates
- ✅ **Adds new workflows** (uses `cp -n` — won't overwrite existing)
- ⚠️ **Overwrites ALL coordinator skills unconditionally** (`init.sh:87`). If a user customized `squad-onboard.md`, it's silently lost.
- ⚠️ **No version comparison.** The upgrade doesn't check if the target is already at the latest version. No pre/post version logging.
- ⚠️ **No charter upgrade path.** Agent charters are NOT updated during `--upgrade`. If the charter template gains new sections (like Skill Loading Protocol), existing projects never get them.
- ⚠️ **No rollback.** If an upgrade breaks something, there's no way to revert short of git history.

### Worktree Strategy

Well-designed with two strategies:
1. **Worktree-local** (recommended) — each worktree has its own `.squad/` state. Branch-local, no conflicts. Merge via git.
2. **Main-checkout** — all worktrees share the main `.squad/`. Single source of truth but races on concurrent sessions.

The `merge=union` gitattributes driver makes strategy 1 seamless for append-only files.

**Gap:** The worktree module (`squad-worktrees.md:56-57`) mentions `worktrees: true` config in `squad.config.ts` or `package.json squad section` — but these config paths don't exist in the system. `config.json` has no `worktrees` field.

### Ceremony System

Two ceremonies pre-configured:
1. **Design Review** — auto-triggered before multi-agent tasks
2. **Retrospective** — auto-triggered after failures

**Gap:** The ceremonies system references `.squad/templates/ceremony-reference.md` (`squad.agent.md:1168`) for facilitator spawn template and execution rules — but this file doesn't exist in the template. Ceremony execution details are only described in general terms.
- Missing file: `.squad/templates/ceremony-reference.md`

### Missing Templates

Several template files referenced in the coordinator don't exist:
- `.squad/templates/ceremony-reference.md` (`squad.agent.md:1168`)
- `.squad/templates/human-members.md` (`squad.agent.md:1297`)
- `.squad/templates/copilot-agent.md` (`squad.agent.md:1304`)
- `.squad/templates/issue-lifecycle.md` (`squad.agent.md:line in squad-issues.md`)
- `.squad/templates/orchestration-log.md` (`squad.agent.md:1313`)
- `.squad/templates/prd-intake.md` (`squad.agent.md:1279`)
- `.squad/templates/ralph-reference.md` (referenced in squad-issues.md)
- `.squad/templates/casting-reference.md` (referenced in squad-casting.md)
- `.squad/templates/constraint-tracking.md` (referenced in squad-session.md)

**These are significant gaps.** When the coordinator or a module instructs reading a template that doesn't exist, the agent encounters a file-not-found error and must improvise. This degrades quality.

---

## Priority Improvements (Ranked)

### Critical (blocks quality)

1. **Create missing template files.** 9 template files are referenced but don't exist. This causes file-not-found errors during ceremonies, issue lifecycle, PRD intake, and casting. Highest-impact fix.
   - Files needed: `ceremony-reference.md`, `human-members.md`, `copilot-agent.md`, `issue-lifecycle.md`, `orchestration-log.md`, `prd-intake.md`, `ralph-reference.md`, `casting-reference.md`, `constraint-tracking.md`

2. **Standardize charter `Primary bundle` field name.** The spawn prompt looks for "Primary bundle" but charters use inconsistent names ("Skill bundle", "Skill bundles"). This means agents fail to find their skill bundle on first action. Fix all charters to use `Primary bundle` consistently.

3. **Add `Skill Loading Protocol` to all charters.** This section exists in the template but was never populated in any actual charter. Without it, agents don't know when to load on-demand skill modules (e.g., failure-patterns.md during code review).

### High (improves reliability)

4. **Remove duplicate BANNED PHRASES block.** Lines 576-589 duplicate lines 17-22. Consolidate to save ~15 lines of context and eliminate potential divergence.

5. **Add Init Mode exception to Critical Rule 1.** The "NEVER ASK" rule conflicts with Init Mode's required user confirmation step. Add an explicit exception note.

6. **Move speculative modules out of active set.** `squad-mesh.md`, `squad-infrastructure.md`, and `squad-plugins.md` describe systems that don't exist. Move to `future/` directory and remove from the on-demand module table to prevent confusion.

7. **Add charter upgrade to `init.sh --upgrade`.** Currently, agent charters are never updated during upgrade. Add a mechanism to merge new charter sections (like Skill Loading Protocol) without overwriting customizations. Consider a `charter-base.md` + `charter-overrides.md` model.

### Medium (improves efficiency)

8. **Create 2 more full presets.** `express-react-prisma` and `fastapi-react` would cover the most common non-.NET full-stack configurations. Seeds alone produce lower quality output than full presets with specialized charters.

9. **Add Handoff Protocol to implementation agent charters.** Backend, Frontend, and Tester lack this section. Adding it makes handoff expectations explicit rather than relying on the coordinator's spawn prompt.

10. **Create missing high-value seeds.** Django, NestJS, SQLAlchemy, Drizzle — these are the biggest gaps in the seed library.

11. **Make pre-flight conditional on context.** Only run pre-flight environment checks for Development context tasks. Skip for Research and Review contexts to save bootstrap time.

### Low (polish)

12. **Tighten keyword triggers for modules.** Replace overly broad triggers ("scale", "mode", "context") with more specific phrases to prevent false-positive module loading.

13. **Add module version frontmatter.** Include `updated`, `requires_coordinator`, and `version` fields in module YAML frontmatter for upgrade safety.

14. **Add decision contradiction detection.** When Scribe merges the decisions inbox, check for contradictory decisions (e.g., "use PostgreSQL" vs "use SQLite") and flag them for Lead review.

15. **Standardize Scribe/Ralph charter format.** Align their Project Context section with the bulleted list format used by Lead/Backend/Frontend/Tester.
