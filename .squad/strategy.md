# Squad System Improvement Strategy

_Generated: 2026-04-02 — Updated: 2026-04-15 — Full synthesis of 5-agent analysis_
_Analysts: Lead (Architecture), Backend (Tooling/Seeds), Frontend (Docs/UX), Tester (Consistency/Completeness), Ralph (Security/Ops)_

---

## Executive Summary

Squad-Template v0.9.1 is a mature, well-architected system with strong fundamentals: clean 3-tier separation, battle-tested session recovery, a high-quality seed library, and an aggressive auto-proceed philosophy that eliminates the most common AI-team friction. However, the system has **three systemic themes** that cut across all five analyses. **First: core/stack boundary leakage** — stack-specific cast names ("ripley", "fenster") are hardcoded into core files (config.json, coordinator model table), and 9 template files referenced by the coordinator don't exist, causing file-not-found errors in ceremonies, casting, and issue lifecycle. **Second: init.sh has real bugs** — shell operator precedence errors silently break Vite/Next.js detection for TypeScript variants, session-state.md is overwritten without protection, and re-running init.sh on an existing project silently destroys customized charters. **Third: the gap between "defined" and "wired"** — the charter template defines Skill Loading Protocol and Primary bundle fields that no actual charter implements, meaning agents can't find their skill bundles via the mechanism the coordinator expects. The seed library and drop-box decision pattern are standout strengths to preserve. No critical security vulnerabilities were found, but the absence of `.gitignore` management creates a high-severity risk of committing secrets and session logs.

---

## Finding Themes

### 🔴 P0 — Bugs & Broken References

These are active defects that cause silent failures or incorrect behavior today.

| # | Finding | Source | Fix | Effort | Files |
|---|---------|--------|-----|--------|-------|
| 1 | **Shell operator precedence bug** — `[ -f a ] \|\| [ -f b ] && CMD` parses as `a \|\| (b && CMD)`. Vite/Next.js `.ts` variant detection silently broken. | Backend | Wrap in braces: `{ [ -f a ] \|\| [ -f b ]; } && CMD` | S | `init.sh:131,133,652,654` |
| 2 | **Corrupted `{skills/coordinator}` directory** — Literal `{skills/` directory in source tree from botched shell expansion. | Backend | Delete `core/.copilot/skills/{skills/` directory tree | S | `core/.copilot/skills/{skills/` |
| 3 | **9 missing template files** referenced by coordinator/modules — ceremony-reference, human-members, copilot-agent, issue-lifecycle, orchestration-log, prd-intake, ralph-reference, casting-reference, constraint-tracking. Agents hit file-not-found and must improvise. | Lead | Create all 9 template files with minimal viable content. | L | `core/.squad/templates/` (9 files) |
| 4 | **Stack-specific cast names in core** — `"ripley"` in core `config.json`, cast names (ripley/fenster/dallas/hockney) in coordinator model table at line 506-510. Confusing on non-dotnet-angular installs. | Tester, Lead | Remove `"ripley"` from core config.json. Generalize model table to role names (Lead, Backend, etc.). | S | `core/.squad/config.json`, `.github/agents/squad.agent.md` |
| 5 | **Charter "Primary bundle" field name mismatch** — Spawn prompt reads "Primary bundle" but charters use "Skill bundle"/"Skill bundles". Agents fail to locate their bundle. | Lead | Standardize all charters to use `Primary bundle:` field name. | S | `core/.squad/agents/*/charter.md` (6 files) |

### 🟠 P1 — System Integrity Issues

Charter/coordinator misalignment and missing safety guards.

| # | Finding | Source | Fix | Effort | Files |
|---|---------|--------|-----|--------|-------|
| 6 | **Missing Skill Loading Protocol** in all 6 charters — Defined in template (`templates/charter.md:31-35`) but never populated in any actual charter. Agents don't know when to load on-demand modules. | Lead | Add `## Skill Loading Protocol` section to all 6 charters. | M | `core/.squad/agents/*/charter.md` (6 files) |
| 7 | **session-state.md overwritten on re-init** — `cp` without `-n` flag at line 268 resets session state. | Backend | Change to `cp -n` or add `[[ ! -f ]]` guard, consistent with config.json handling. | S | `init.sh:268` |
| 8 | **init.sh overwrites charters without warning** on existing projects (non-upgrade path) — No check for existing `.squad/` directory. Users lose customizations silently. | Tester, Backend | Add `.squad/` existence check → prompt user or route to `--upgrade`. | S | `init.sh` (near line 55-63) |
| 9 | **Ralph invisible in core routing.md** — Defined in `team.md` but has zero entries in core routing table. Users can't discover when to route to Ralph. | Tester | Add `build`, `deploy`, `monitor`, `security` routing entries pointing to Ralph. | S | `core/.squad/routing.md` |
| 10 | **Duplicate BANNED PHRASES block** — Identical content at lines 17-22 and 576-589 in coordinator. Risk of divergence during edits. | Lead | Remove duplicate at line 576. Keep only Critical Rules version. | S | `.github/agents/squad.agent.md` |
| 11 | **Init Mode exception not in Critical Rule 1** — "NEVER ASK" rule conflicts with Init Mode Phase 1's required user confirmation. | Lead | Add exception note: "Exception: Init Mode Phase 1 requires confirmation." | S | `.github/agents/squad.agent.md:14-15` |
| 12 | **Missing Handoff Protocol** for Backend, Frontend, Tester — Scribe and Ralph have it; implementation agents (who produce/consume handoffs most) don't. | Lead | Add `## Handoff Protocol` section to Backend, Frontend, Tester charters. | M | `core/.squad/agents/{backend,frontend,tester}/charter.md` |

### 🟡 P2 — Missing Infrastructure

Gaps in tooling, version management, and template completeness.

| # | Finding | Source | Fix | Effort | Files |
|---|---------|--------|-----|--------|-------|
| 13 | **No `.gitignore` management** — init.sh never creates/updates `.gitignore`. Session logs, orchestration logs, and `.env` files risk being committed. **Highest-severity security gap.** | Backend, Tester, Ralph | Add `.gitignore` creation step to init.sh. Include `.squad/log/`, `.squad/orchestration-log/`, `.env`, `.env.local`. | S | `init.sh`, create `core/.gitignore` template |
| 14 | **No `--upgrade` version comparison** — Upgrade runs unconditionally even if already at latest version. No pre/post version logging. | Backend, Lead, Ralph | Add `templateVersion` comparison before upgrade. Emit "Already at vX.Y.Z" or "Upgrading from X → Y". | M | `init.sh` |
| 15 | **No CHANGELOG.md** — Users who upgrade have no way to know what changed. No release history. | Backend, Frontend, Ralph | Create `CHANGELOG.md` with entries for current version (0.9.1). | S | Create `CHANGELOG.md` |
| 16 | **Duplicate stack detection logic** — `detect_stack()` (lines 128-161) and Step 5 (lines 648-660) implement detection independently with different tech lists. Will diverge. | Backend | Refactor Step 5 to call `detect_stack()` and reuse `$DETECTED_TECHS`. | M | `init.sh` |
| 17 | **Missing `learn.md` for Ralph and Scribe** — Other agents have it. Ralph/Scribe are handicapped for auto-discovery behavior. | Backend | Create `learn.md` files for Ralph and Scribe consistent with other agents. | S | `core/.squad/agents/{ralph,scribe}/learn.md` |
| 18 | **STACK parameter not validated** — Could contain `../` for directory traversal (low risk but easy fix). | Ralph | Add regex validation: `[[ ! "$STACK" =~ ^[a-z0-9_-]+$ ]] && exit 1` | S | `init.sh:467-475` |
| 19 | **3rd-party GitHub Action not pinned** — `amannn/action-semantic-pull-request@v5` uses major version only. | Ralph | Pin to patch version or commit SHA. | S | `core/.github/workflows/pr-title-check.yml` |
| 20 | **3 speculative modules** consuming 373 lines — `squad-mesh.md`, `squad-infrastructure.md`, `squad-plugins.md` reference non-existent CLIs and systems. | Lead | Move to `future/` directory. Remove from on-demand module table. | S | `.copilot/skills/coordinator/` (3 files), `.github/agents/squad.agent.md` |
| 21 | **`_template` preset missing ops/docs charters** — Only 4 of 6 agent charter templates. No `cast.conf` example. | Tester, Backend | Add `agents/ops.charter.md`, `agents/docs.charter.md`, example `cast.conf`. | M | `stacks/_template/agents/` |
| 22 | **Keyword triggers too broad** — "scale", "mode", "context" trigger modules on unrelated requests. | Lead | Tighten to multi-word phrases: "scale infrastructure", "development mode", etc. | S | `.github/agents/squad.agent.md` |
| 23 | **No module versioning** — Modules have no version markers. Upgrade overwrites without compatibility check. | Lead | Add YAML frontmatter with `updated`, `requires_coordinator` fields. | M | `.copilot/skills/coordinator/*.md` (14 files) |
| 49 | **Pre-flight always runs regardless of context type** — Environment checks (build, install, test-run) are unnecessary for Research and Review context tasks but add 30-60s bootstrap time. | Lead | Make pre-flight conditional: skip environment validation for Research/Review context; run full checks only for Development context. | M | `.copilot/skills/coordinator/squad-preflight.md`, `.github/agents/squad.agent.md` |
| 50 | **Missing tech detectors in `detect_stack()`** — Svelte, Bun, Astro, Docker, Terraform, NestJS, Django, Laravel, tRPC, Drizzle have no detection logic. Auto-detect silently misses these stacks. | Backend | Add detection fingerprints (`svelte.config.js`, `bun.lockb`, `Dockerfile`, `*.tf`, package.json deps) to `detect_stack()`. | M | `init.sh:128-161` |
| 51 | **Seeds not wired into charter loading flow** — Seeds are copied to `.squad/seeds/` and agents are told they exist, but no charter section or init.sh step tells agents HOW to load them (which context, which trigger). Activation mechanism is implicit and undocumented. | Backend | Add `## Seed Loading` section to charter template and all 6 charters. Document which agent roles load which seed types. OR: automate seed injection into charters during init.sh stack detection. | M | `core/.squad/agents/*/charter.md`, `stacks/_template/agents/*.charter.md`, `init.sh` |

### 🟢 P3 — UX & Documentation Improvements

Onboarding friction, missing guides, documentation gaps.

| # | Finding | Source | Fix | Effort | Files |
|---|---------|--------|-----|--------|-------|
| 24 | **README value prop buried** — Benefits don't appear until section 5. First 40 lines are prerequisites/install. Visitors bounce. | Frontend | Add 2-3 sentence benefit lede before prerequisites. Move disclaimer below value prop. | S | `README.md` |
| 25 | **GPT-5.1 HIGH requirement unexplained** — Listed in prerequisites with no inline explanation of why it's needed. | Frontend | Add one-sentence explanation: "Required for per-agent model routing." | S | `README.md` |
| 26 | **No terminal demo/GIF anywhere** — Zero visual proof of the system working. Highest-impact single doc addition. | Frontend | Record 60-90 second terminal session. Add to README. | M | `README.md`, add media file |
| 27 | **No "first feature" walkthrough** — No end-to-end trace showing prompt → coordinator → agents → output. Biggest unknown for new users. | Frontend | Create `docs/FIRST-FEATURE-WALKTHROUGH.md` with step-by-step trace. | L | Create `docs/FIRST-FEATURE-WALKTHROUGH.md` |
| 28 | **Architecture doc explains WHAT but not WHY** — No motivation for 3-tier design. Pre-flight buried at bottom. No diagram. | Frontend | Add "Why this architecture?" section. Move pre-flight up. Add ASCII diagram. | M | `docs/ARCHITECTURE.md` |
| 29 | **Customization guide assumes from-scratch** — No "improve an existing `--auto` install" path. No "minimum viable customization" path. | Frontend | Add "Improving an Auto Install" subsection and "30-minute Quick Wins" path. | M | `docs/CUSTOMIZATION_GUIDE.md` |
| 30 | **No multi-developer workflow guide** — FAQ says "commit `.squad/`" but no merge/conflict/simultaneous-use guidance. | Frontend | Add "Team Workflows" section to INTEGRATION-GUIDE.md. | M | `docs/INTEGRATION-GUIDE.md` |
| 31 | **`project-map.md` "ALWAYS read first" language** — Charters say "ALWAYS read" but file doesn't exist on fresh install. Coordinator says "if exists" but charters don't. | Tester | Change charter language to: "Read if it exists (generated by Learn Mode)." | S | `core/.squad/agents/*/charter.md` (6 files) |
| 32 | **Backend charter test-writing ambiguity** — "Don't write tests (route to Tester, unless unit-testing own code)" — parenthetical contradicts the rule. | Tester | Rewrite to explicit boundary: "Backend MAY write unit tests for internal service logic; all integration/API/cross-layer tests route to Tester." | S | `core/.squad/agents/backend/charter.md` |
| 33 | **Ceremonies.md installed version loses template richness** — Missing "3+ layers" trigger condition for Design Review. | Tester | Sync installed `ceremonies.md` with template version. | S | `core/.squad/ceremonies.md` |
| 34 | **No agent behavior troubleshooting guide** — README has 5 error messages but no "my agent keeps doing X wrong" guide. | Frontend | Create `docs/TROUBLESHOOTING.md` covering agent misbehavior patterns. | M | Create `docs/TROUBLESHOOTING.md` |
| 35 | **Scribe/Ralph use different Project Context format** than other charters — flat vs bulleted lists. | Lead | Align to bulleted list format used by Lead/Backend/Frontend/Tester. | S | `core/.squad/agents/{scribe,ralph}/charter.md` |
| 36 | **Lead charter says "read-only" but Lead writes decisions** — Misleading tool scoping rationale. | Lead | Correct to: "Allowed: Read, Grep, Glob, Write (decisions inbox and history only)." | S | `core/.squad/agents/lead/charter.md` |
| 37 | **No "what Squad doesn't do" section** — Users don't know limitations (unsupervised DB migrations, auth changes, etc.). | Frontend | Add "Limitations & Boundaries" section to README or Integration Guide. | S | `README.md` or `docs/INTEGRATION-GUIDE.md` |
| 38 | **Missing secrets sanitization in Scribe** — Scribe auto-commits but charter doesn't mention scanning for secrets first. | Ralph | Add secret-scanning step to Scribe charter's git commit protocol. | S | `core/.squad/agents/scribe/charter.md` |
| 52 | **Decision contradiction detection absent** — When Scribe merges the decisions inbox, conflicting decisions ("use PostgreSQL" vs "use SQLite") are silently merged with no flag for Lead review. Corrupts architectural state. | Lead | Add contradiction-check step to Scribe's merge protocol. Flag conflicting entries in `decisions.md` with a `⚠️ CONFLICT:` marker for Lead to resolve at next session. | S | `core/.squad/agents/scribe/charter.md` |
| 53 | **`--stack` error path lists `seeds` as a valid preset** — `init.sh:473` omits the `grep -v 'seeds'` filter used in the valid-path listing, making `seeds` appear as a selectable preset in error messages. | Tester | Add `grep -v 'seeds'` to the error path's preset listing at line 473. | S | `init.sh:473` |
| 54 | **`{{PROJECT_NAME}}` double-brace in `_template` charter** — `stacks/_template/agents/backend.charter.md:7` uses `{{PROJECT_NAME}}` while the rest of the template system uses single-brace `{PROJECT_NAME}`. Creates confusing inconsistency for stack authors. | Tester | Standardize all `_template` placeholder syntax to `{PROJECT_NAME}` (single-brace) to match convention. | S | `stacks/_template/agents/backend.charter.md` |

### 🔵 P4 — Strategic Expansions

New capabilities, new stacks, new features.

| # | Finding | Source | Fix | Effort | Files |
|---|---------|--------|-----|--------|-------|
| 39 | **Only 1 full preset exists** — `dotnet-angular` is the only non-template preset. Need at least 2-3 more for broad adoption. | Lead, Backend | Create `nextjs-prisma`, `express-react`, `fastapi-react` presets. | XL | `stacks/` (new directories) |
| 40 | **Missing high-value seeds** — NestJS, Drizzle, Supabase, Django, SQLAlchemy, Svelte, Docker. | Lead, Backend | Create seeds using existing seed format. NestJS/Drizzle/Supabase highest priority. | L | `stacks/seeds/`, `.squad/seeds/` |
| 41 | **No composable presets** — Can't combine `dotnet-backend` + `react-frontend`. Must create full preset per combo. | Lead | Design `--backend X --frontend Y` flag system or composable layer architecture. | XL | `init.sh`, `stacks/` architecture |
| 42 | **No CI/Pipeline skill module** — System ships 5 workflows but no module for "CI", "pipeline", "GitHub Actions" discussions. | Lead | Create `squad-ci.md` module with workflow documentation and customization guidance. | M | `core/.copilot/skills/coordinator/squad-ci.md` |
| 43 | **`shared/` directory underused** — Only `failure-patterns-global.md`. Could house security baseline, git workflow, code review standards. | Backend | Add `shared/security-baseline.md`, `shared/git-workflow.md`. | M | `shared/` |
| 44 | **No monorepo detection** — init.sh only inspects root of `$TARGET`. Monorepos with `frontend/` + `backend/` subdirs not detected. | Backend | Add one-level-deep subdir traversal to `detect_stack()`. | M | `init.sh` |
| 45 | **No SECURITY.md** — No security best practices for running agents with secrets, CI/CD guidance, or pre-commit hooks. | Ralph | Create SECURITY.md with agent security model, CI/CD guidance, pre-commit template. | M | Create `SECURITY.md` |
| 46 | **No CONTRIBUTING.md** — No guidance for contributing new stacks, seeds, or skills. | Tester | Create CONTRIBUTING.md with contribution workflow. | M | Create `CONTRIBUTING.md` |
| 47 | **Dotnet-angular skills reference CAP.Template-specific paths** — Confuses agents on other .NET+Angular projects using this preset. | Backend | Parameterize paths or add prominent warning in preset README. | M | `stacks/dotnet-angular/skills/*.md` |
| 48 | **Preset suggestion only works for dotnet-angular** — No dispatch table for future presets. | Backend | Create convention-based detection manifest per stack directory. | M | `init.sh`, `stacks/*/detect.conf` |

---

## Full Prioritized Work Queue

1. **[P0]** Fix shell operator precedence in init.sh detection logic — _Backend_ — Wrap multi-condition tests in braces. Affects lines 131, 133, 652, 654. **Effort: S**
2. **[P0]** Delete corrupted `{skills/coordinator}` directory — _Backend_ — Remove `core/.copilot/skills/{skills/` tree. **Effort: S**
3. **[P0]** Create 9 missing template files — _Lead_ — ceremony-reference, human-members, copilot-agent, issue-lifecycle, orchestration-log, prd-intake, ralph-reference, casting-reference, constraint-tracking. **Effort: L**
4. **[P0]** Remove stack-specific cast names from core — _Tester, Lead_ — Delete "ripley" from core config.json. Generalize coordinator model table. **Effort: S**
5. **[P0]** Standardize "Primary bundle" field name across all charters — _Lead_ — Match spawn prompt expectation. **Effort: S**
6. **[P1]** Add Skill Loading Protocol to all 6 charters — _Lead_ — Minimum: "ALWAYS read primary bundle. On code review: read failure-patterns.md." **Effort: M**
7. **[P1]** Add `cp -n` to session-state.md copy — _Backend_ — Prevent data loss on accidental re-init. **Effort: S**
8. **[P1]** Add existing-Squad guard to init.sh — _Tester, Backend_ — Check for `.squad/` directory, warn user, route to `--upgrade`. **Effort: S**
9. **[P1]** Add Ralph to core routing.md — _Tester_ — Add build/deploy/monitor/security routing entries. **Effort: S**
10. **[P1]** Remove duplicate BANNED PHRASES block — _Lead_ — Keep Critical Rules version only. **Effort: S**
11. **[P1]** Add Init Mode exception to Critical Rule 1 — _Lead_ — Explicit exception note. **Effort: S**
12. **[P1]** Add Handoff Protocol to implementation agent charters — _Lead_ — Backend, Frontend, Tester need to know handoff expectations. **Effort: M**
13. **[P2]** Add `.gitignore` management to init.sh — _Backend, Tester, Ralph_ — Create/append Squad ephemeral paths + .env. **Effort: S**
14. **[P2]** Add version comparison to `--upgrade` — _Backend, Lead, Ralph_ — Compare templateVersion, emit changelog. **Effort: M**
15. **[P2]** Create CHANGELOG.md — _Backend, Frontend, Ralph_ — Document v0.9.1 changes. **Effort: S**
16. **[P2]** Consolidate duplicate detection logic in init.sh — _Backend_ — Step 5 should call detect_stack(). **Effort: M**
17. **[P2]** Create learn.md for Ralph and Scribe — _Backend_ — Match other agents' auto-discovery. **Effort: S**
18. **[P2]** Add STACK parameter regex validation — _Ralph_ — `^[a-z0-9_-]+$`. **Effort: S**
19. **[P2]** Pin 3rd-party GitHub Actions to SHA/patch — _Ralph_ — `amannn/action-semantic-pull-request`. **Effort: S**
20. **[P2]** Move speculative modules to `future/` — _Lead_ — mesh, infrastructure, plugins. Saves 373 lines. **Effort: S**
21. **[P2]** Add ops/docs charters and cast.conf to `_template` — _Tester, Backend_ — Complete the template. **Effort: M**
22. **[P2]** Tighten keyword triggers for on-demand modules — _Lead_ — Use multi-word phrases. **Effort: S**
23. **[P2]** Add version frontmatter to all coordinator modules — _Lead_ — `updated`, `requires_coordinator`. **Effort: M**
24. **[P3]** Restructure README — lead with value prop — _Frontend_ — Benefits before prerequisites. **Effort: S**
25. **[P3]** Explain GPT-5.1 HIGH inline in README — _Frontend_ — One sentence. **Effort: S**
26. **[P3]** Add terminal demo/GIF to README — _Frontend_ — 60-90 second recording. **Effort: M**
27. **[P3]** Create "first feature" walkthrough doc — _Frontend_ — End-to-end trace. **Effort: L**
28. **[P3]** Improve ARCHITECTURE.md — add WHY, diagram, reorder — _Frontend_ — Move pre-flight up, add motivation. **Effort: M**
29. **[P3]** Add "Improving Auto Install" path to Customization Guide — _Frontend_ — Plus 30-min quick wins. **Effort: M**
30. **[P3]** Add multi-developer workflow section to Integration Guide — _Frontend_ — Merge conflicts, simultaneous use. **Effort: M**
31. **[P3]** Fix `project-map.md` language in charters — _Tester_ — "Read if it exists." **Effort: S**
32. **[P3]** Clarify Backend charter test-writing boundary — _Tester_ — Explicit unit vs integration split. **Effort: S**
33. **[P3]** Sync ceremonies.md installed ↔ template — _Tester_ — Add "3+ layers" trigger. **Effort: S**
34. **[P3]** Create agent troubleshooting guide — _Frontend_ — "My agent keeps doing X wrong." **Effort: M**
35. **[P3]** Align Scribe/Ralph charter format — _Lead_ — Match bulleted list format. **Effort: S**
36. **[P3]** Correct Lead charter tool scoping language — _Lead_ — Acknowledge write access for decisions. **Effort: S**
37. **[P3]** Add "Limitations & Boundaries" section — _Frontend_ — What Squad doesn't do. **Effort: S**
38. **[P3]** Add secrets sanitization to Scribe charter — _Ralph_ — Scan before git commit. **Effort: S**
39. **[P4]** Create 2-3 new stack presets — _Lead, Backend_ — nextjs-prisma, express-react, fastapi-react. **Effort: XL**
40. **[P4]** Create high-value missing seeds — _Lead, Backend_ — NestJS, Drizzle, Supabase, Django, SQLAlchemy, Svelte, Docker. **Effort: L**
41. **[P4]** Design composable preset architecture — _Lead_ — `--backend X --frontend Y`. **Effort: XL**
42. **[P4]** Create CI/Pipeline skill module — _Lead_ — squad-ci.md. **Effort: M**
43. **[P4]** Expand `shared/` directory — _Backend_ — Security baseline, git workflow. **Effort: M**
44. **[P4]** Add monorepo detection to init.sh — _Backend_ — One-level subdir traversal. **Effort: M**
45. **[P4]** Create SECURITY.md — _Ralph_ — Agent security model, CI/CD guidance, pre-commit hooks. **Effort: M**
46. **[P4]** Create CONTRIBUTING.md — _Tester_ — Contribution workflow for stacks/seeds/skills. **Effort: M**
47. **[P4]** Decouple dotnet-angular skills from CAP.Template paths — _Backend_ — Parameterize or document. **Effort: M**
48. **[P4]** Add preset suggestion dispatch table — _Backend_ — Convention-based detection beyond dotnet-angular. **Effort: M**
49. **[P2]** Make pre-flight conditional on context type — _Lead_ — Skip environment checks for Research/Review; full checks for Development only. **Effort: M**
50. **[P2]** Add missing tech detectors to `detect_stack()` — _Backend_ — Svelte, Bun, Astro, Docker, Terraform, NestJS, Django, tRPC, Drizzle. **Effort: M**
51. **[P2]** Document and/or automate seed-to-charter loading — _Backend_ — Add `## Seed Loading` section to charter template; define which agents load which seed types. **Effort: M**
52. **[P3]** Add decision contradiction detection to Scribe charter — _Lead_ — Flag conflicting entries with `⚠️ CONFLICT:` for Lead resolution. **Effort: S**
53. **[P3]** Fix `--stack` error path to exclude `seeds` from preset listing — _Tester_ — Add `grep -v 'seeds'` at init.sh:473. **Effort: S**
54. **[P3]** Normalize `{{PROJECT_NAME}}` → `{PROJECT_NAME}` in `_template/agents/backend.charter.md` — _Tester_ — Single-brace throughout. **Effort: S**

---

## Quick Wins (< 30 min each)

These can be done immediately with minimal risk:

1. **Delete corrupted `{skills/coordinator}` directory** — `rm -rf core/.copilot/skills/\{skills/` — 2 minutes
2. **Fix shell operator precedence** (4 lines in init.sh) — Add braces around multi-condition tests — 10 minutes
3. **Remove "ripley" from core config.json** — Delete one line from `agentModelOverrides` — 5 minutes
4. **Standardize "Primary bundle" field** in 4 charters (lead, backend, frontend, tester) — Find/replace — 10 minutes
5. **Add `cp -n` to session-state.md copy** — One character change in init.sh:268 — 2 minutes
6. **Remove duplicate BANNED PHRASES** — Delete lines 576-589 from squad.agent.md — 5 minutes
7. **Add Init Mode exception note** to Critical Rule 1 — One sentence addition — 5 minutes
8. **Add Ralph to core routing.md** — 4 new rows in routing table — 10 minutes
9. **Pin 3rd-party GitHub Action** — Change `@v5` to `@v5.4.0` or SHA — 5 minutes
10. **Add STACK regex validation** — 3 lines in init.sh — 5 minutes
11. **Fix project-map.md language** — "ALWAYS read" → "Read if it exists" in 6 charters — 15 minutes
12. **Clarify Backend test-writing boundary** — Rewrite one paragraph — 10 minutes
13. **Create CHANGELOG.md** — One file, 3-5 version entries — 20 minutes
14. **Explain GPT-5.1 HIGH inline** — One sentence in README — 5 minutes
15. **Add secrets sanitization step to Scribe charter** — 3-4 lines — 10 minutes
16. **Correct Lead charter tool scoping** — One line edit — 5 minutes

**Total estimated time for all quick wins: ~2-3 hours (parallelizable across team)**

---

## Decisions Needed from Simon

These items require Simon's input before the team can proceed:

1. **9 missing template files** — What content should `ceremony-reference.md`, `prd-intake.md`, `human-members.md`, and the other 6 missing templates contain? Should we create minimal stubs or full reference docs? The coordinator references them but they were never written. We can create reasonable defaults but Simon should review the intended scope of each.

2. **Speculative modules (mesh, infrastructure, plugins)** — These describe systems that don't exist yet (squad-cli, KEDA, plugin marketplace). Should we remove them entirely, move to `future/`, or keep them as aspirational? They consume 373 lines of potential context.

3. **Composable presets vs monolithic presets** — Lead analysis suggests `--backend dotnet --frontend react` composability. This is a significant architecture decision affecting how `stacks/` is organized. Is this the direction Simon wants, or should we stick with monolithic presets and just create more of them?

4. **Which new presets to prioritize?** — Multiple analyses suggest different first targets: `nextjs-prisma`, `express-react`, `fastapi-react`. Simon should decide the order based on user demand.

5. **`.gitignore` policy** — Should init.sh create a new `.gitignore` if one doesn't exist, or ONLY append Squad-specific entries to an existing one? Creating a full `.gitignore` with `node_modules/`, `dist/`, etc. is opinionated. Ralph's analysis suggests a full template; Backend's analysis suggests append-only.

6. **Charter upgrade path** — Currently `--upgrade` never touches agent charters (by design, to preserve customizations). But this means projects never get new charter sections (like Skill Loading Protocol). Should we implement a `charter-base.md` + `charter-overrides.md` split, or a different merge strategy?

7. **Cast name origin documentation** — The "Alien" movie character naming convention (ripley, fenster, dallas, hockney) is a fun cultural detail. Should it be documented/explained in the stack template guide, or left as an Easter egg?

---

## Phase Plan

### Phase 1: Today — Bug Fixes & Critical Integrity
_Goal: Eliminate all P0 bugs and the most impactful P1 issues._

- [ ] Fix shell operator precedence (init.sh:131,133,652,654)
- [ ] Delete corrupted `{skills/coordinator}` directory
- [ ] Remove "ripley" from core config.json; generalize coordinator model table
- [ ] Standardize "Primary bundle" field in all 6 charters
- [ ] Add `cp -n` to session-state.md copy (init.sh:268)
- [ ] Add existing-Squad guard to init.sh (non-upgrade path)
- [ ] Remove duplicate BANNED PHRASES block
- [ ] Add Init Mode exception to Critical Rule 1
- [ ] Add Ralph to core routing.md
- [ ] Add STACK regex validation to init.sh

**Estimated time: 3-4 hours, 1-2 people**

### Phase 2: This Week — Infrastructure & Charter Improvements
_Goal: Complete missing infrastructure. Get charters to full specification._

- [ ] Add `.gitignore` management to init.sh (pending Simon's policy decision)
- [ ] Add Skill Loading Protocol to all 6 charters
- [ ] Add Handoff Protocol to Backend, Frontend, Tester charters
- [ ] Create learn.md for Ralph and Scribe
- [ ] Create CHANGELOG.md
- [ ] Consolidate duplicate detection logic in init.sh
- [ ] Move speculative modules to `future/` (pending Simon's decision)
- [ ] Pin 3rd-party GitHub Actions
- [ ] Tighten keyword triggers for on-demand modules
- [ ] Add ops/docs charters and cast.conf to `_template`
- [ ] Fix project-map.md language across all charters
- [ ] Clarify Backend charter test-writing boundary
- [ ] Add secrets sanitization to Scribe charter
- [ ] Align Scribe/Ralph charter format
- [ ] Correct Lead charter tool scoping
- [ ] Make pre-flight conditional on Development context only
- [ ] Add missing tech detectors to `detect_stack()` (Svelte, Bun, Docker, NestJS, tRPC, Drizzle, Django)
- [ ] Document seed-to-charter loading mechanism (Seed Loading section in charters or automate in init.sh)

**Estimated time: 8-12 hours across team**

### Phase 3: Next Sprint — Documentation & UX
_Goal: Improve onboarding experience. Fill documentation gaps._

- [ ] Restructure README (value prop first)
- [ ] Create "first feature" walkthrough doc
- [ ] Add terminal demo/GIF
- [ ] Improve ARCHITECTURE.md (add WHY, diagram, reorder)
- [ ] Add "Improving Auto Install" path to Customization Guide
- [ ] Add multi-developer workflow section to Integration Guide
- [ ] Create agent troubleshooting guide
- [ ] Add version comparison to `--upgrade`
- [ ] Add version frontmatter to coordinator modules
- [ ] Begin creating 9 missing template files (pending Simon's scope input)
- [ ] Add decision contradiction detection to Scribe charter
- [ ] Fix `--stack` error path to exclude `seeds` from preset list
- [ ] Normalize `{{PROJECT_NAME}}` placeholder in `_template/agents/backend.charter.md`

**Estimated time: 2-3 days across team**

### Phase 4: Strategic — New Capabilities
_Goal: Expand system reach. New stacks, seeds, and features._

- [ ] Create 2-3 new stack presets (nextjs-prisma, express-react, fastapi-react)
- [ ] Create high-value missing seeds (NestJS, Drizzle, Supabase, Django, etc.)
- [ ] Design composable preset architecture (if Simon approves)
- [ ] Create CI/Pipeline skill module
- [ ] Add monorepo detection
- [ ] Expand `shared/` directory
- [ ] Create SECURITY.md and CONTRIBUTING.md
- [ ] Add preset suggestion dispatch table

**Estimated time: 2-3 weeks, full team**

---

## What's Working Well

**Preserve these strengths — don't break them during improvements:**

1. **3-tier architecture separation** — Core has zero tech-specific references. Stack presets and seeds add specialization cleanly. The boundary is well-maintained.

2. **Seed system quality** — All 15 seeds follow a consistent, high-density format (YAML frontmatter → Critical Rules → Golden Example → Common LLM Mistakes). Express, React, and dotnet-webapi seeds are gold standard quality. Version-pinned, prescriptive, battle-tested.

3. **Drop-box decision pattern** — Agents write to `decisions/inbox/`, Scribe merges to `decisions.md`. No file conflicts on parallel writes. Union merge gitattributes driver handles cross-branch merging. Elegant distributed state management.

4. **Auto-proceed philosophy** — BANNED PHRASES list and eager execution rules are aggressively anti-friction. The "NEVER ASK — JUST DO" stance is the single biggest UX differentiator from vanilla Copilot.

5. **Session expiry handling** — Three-layer defense (status.md, orchestration-log, session-state.md) with explicit "read_agent failures are NORMAL" wisdom. This is production-learned resilience that took real debugging to discover.

6. **On-demand module loading** — Only ~115 lines always loaded (pre-flight). The remaining ~1946 lines load by keyword trigger. This keeps context lean for most sessions.

7. **Agent scope boundaries** — Every charter has explicit DO/DON'T with cross-references. Lead → read-only architecture. Backend → no tests. Frontend → no backend. Tester → review gate. Scribe → no bash. Ralph → no edit. Non-overlapping and well-enforced.

8. **init.sh safety fundamentals** — `set -euo pipefail`, quoted variables, no `eval`/`exec`, no `rm -rf`, no remote downloads, git-repo-only operations. The shell script is conservatively written.

9. **Stress-test-informed design** — The `wisdom.md` file and Critical Rules show evidence of real-world stress testing. Rules like "60% of session time was wasted on environment issues" directly drove pre-flight's always-load design.

10. **Welcome message sophistication** — Three-case detection (existing project, empty project, returning session) with adaptive output. The seed-matching visual feedback (`🌱 Seeds available: express ✅, react ✅`) is a genuine "wow" moment.

---

## Risk Assessment & Dependencies

### Sequencing Dependencies

```
P0 fixes  ──→  P1 charter work  ──→  P2 infrastructure  ──→  P3 docs/UX  ──→  P4 expansion
    ↑                  ↑                     ↑
 Unblock          Unblock skills         .gitignore
 init.sh          loading in all         must land
 correctness      agents                 before Phase 4
                                         (new users)
```

**Critical path:**
1. Fix #4 (remove "ripley" from core) and #5 (Primary bundle field) **before** any charter edits — otherwise charter work builds on broken assumptions.
2. Fix #8 (init.sh overwrites charters without warning) **before** releasing any Phase 1 changes — otherwise a `git pull && ./init.sh` by an existing user destroys their customizations.
3. Resolve Simon's **Decision #6** (charter upgrade path) **before** Phase 2 charter work — the right answer affects how every charter edit is structured.
4. Fix #13 (.gitignore) **before** Phase 4 new presets/seeds go live — new users need protection from day one.

### Regression Risks

| Change | Regression Risk | Mitigation |
|--------|----------------|------------|
| Fixing operator precedence (init.sh:131,133) | Detection results change for some stacks | Test with Vite .ts and Next.js .ts projects manually |
| Removing "ripley" from core config.json | dotnet-angular users with old config have orphan key | No runtime impact; key is silently ignored |
| Moving speculative modules to `future/` | References in coordinator become dangling | Remove from on-demand module table in same PR |
| Tightening keyword triggers | Some legitimate requests stop loading needed modules | Test with common trigger phrases before/after |
| Pre-flight conditional on context | Research/Review tasks that need build environment won't pre-warm | Add fallback: "if build fails mid-task, run pre-flight retroactively" |

### Effort Scale

`S` = < 1 hour · `M` = 2–4 hours · `L` = 1–2 days · `XL` = 1+ weeks

---

_End of strategy document. 54 total items across P0–P4. Updated 2026-04-15 to include Lead architecture findings. Ready for Simon's review on decision items before Phase 2 work begins._
