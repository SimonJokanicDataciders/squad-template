# Documentation Quality & UX Analysis

_Analyst: Frontend/UX — Squad-Template Documentation Audit_
_Scope: README.md, docs/, stacks/, agent charters, seeds, shared patterns_

---

## 1. README.md — Completeness & Clarity

**Overall: Strong skeleton, weak first impression.**

### Strengths
- Steps 1–4 are genuinely short, numbered, and copy-pasteable. A developer with Copilot already installed can be running in under 5 minutes.
- The prompt template with the explicit "Do / Don't" table (`README.md:77-83`) is the best teaching element in the entire repository — it tells users *how to think*, not just what to type.
- The `"Why Not Just squad init?"` comparison table (`README.md:173-183`) is concrete and persuasive. It directly answers the skeptic's question with numbers.
- The CLI Reference table (`README.md:130-136`) and troubleshooting section (`README.md:153-168`) cover all common first-run failure modes.

### Issues

**1. Value proposition is buried.**
The first ~40 lines are prerequisites, a disclaimer, and step headings. A new visitor has no answer to "why should I care?" before being asked to clone a repo. The "What You Get" section (`README.md:89`) appears *after* the four-step install flow. This violates the "first 3 paragraphs must earn the scroll" rule for any project README.

**2. The `> Note:` disclaimer reads as a warning, not a differentiator.**
`README.md:5` — "This is not the official Squad setup" is the very first substantive sentence a reader sees. It frames the project defensively. The actual differentiators (model routing, auto-proceed, self-validation) are listed later in the table but never used to *reframe* this note as an advantage.

**3. "GPT-5.1 HIGH" is mentioned but never explained inline.**
`README.md:12` lists it as a prerequisite. The *why* only appears in the troubleshooting section at `README.md:158`: "Only this model routes models per agent." A new user reading top-to-bottom hits a required step with no explanation. The one-sentence rationale should be directly at the point of friction.

**4. The auto-proceed pipeline (`README.md:101-107`) is shown as ASCII art with no evidence.**
There are no screenshots, no terminal recordings, no example of what output looks like during a run. For a system whose core promise is autonomous execution, "no visual proof" is the highest credibility risk in the README.

**5. "Adding a New Stack" (`README.md:188-205`) has equal visual weight to core onboarding.**
This is advanced content for day N. It should be collapsed (`<details>`) or moved to `docs/` — first-time users are confused about whether they need to read it before starting.

### Recommendations
1. Add 3-sentence value-prop lede *before* Prerequisites: what it is, what it does, what makes it different.
2. Reframe the disclaimer as a "vs. default Squad" callout and move it below the fold.
3. Add the one-sentence "why" for GPT-5.1 HIGH inline at `README.md:12`.
4. Collapse or move "Adding a New Stack" — it should not compete with the install flow.
5. Add a terminal transcript or GIF showing at least the welcome message and one phase completing.

---

## 2. Documentation Structure — docs/ Directory

**Four docs exist. Cross-linking is sparse. Audience is inconsistent.**

### Files present
| File | Lines | Purpose |
|------|-------|---------|
| `docs/INTEGRATION-GUIDE.md` | ~300 | Detailed setup, prompt examples, gitignore, FAQ, checklist |
| `docs/ARCHITECTURE.md` | ~186 | 3-tier model, coordinator internals, key patterns |
| `docs/CUSTOMIZATION_GUIDE.md` | ~210 | How to create a stack preset |
| `docs/PREMIUM-REQUEST-COMPARISON.md` | ~248 | Cost analysis with methodology |

### Cross-linking gaps
- `README.md:209-211` links only to `INTEGRATION-GUIDE.md` and `PREMIUM-REQUEST-COMPARISON.md`. `ARCHITECTURE.md` and `CUSTOMIZATION_GUIDE.md` are not linked from the main README.
- None of the docs link to each other. A reader in `CUSTOMIZATION_GUIDE.md` who wants to understand on-demand loading mechanics has no pointer to `ARCHITECTURE.md` where those are explained.
- `stacks/_template/README.md` is referenced in `README.md:204` but `stacks/dotnet-angular/README.md` — the only completed reference example — is never cited as a worked example in any doc.

### Missing documents (critical gaps)
| Missing | Why it matters |
|---------|---------------|
| `CHANGELOG.md` | Users running `--upgrade` have no way to know what changed. The coordinator has `<!-- version: 0.9.1 -->` in `squad.agent.md:6` but no user-facing release notes. |
| `docs/TEAM-WORKFLOW.md` | The FAQ in `INTEGRATION-GUIDE.md:272` says "yes, commit .squad/ files" but gives no guidance on merge workflows, two-dev simultaneous use, or conflict resolution on append-only files. |
| `docs/FIRST-FEATURE-WALKTHROUGH.md` | No doc traces what actually happens when you give Squad a task — which files are read, which agents run in what order, what output files appear. This is the biggest unknown for first-time users. |

### Structural observations
- `core/` directory at `squad-template/core/` mirrors the root `.copilot/`, `.squad/`, and `.github/` structure exactly. This is not explained anywhere in user-facing docs. A user browsing the repo will be confused about its relationship to the root files.
- `stacks/seeds/` and `.squad/seeds/` contain identical files (e.g., `react.seed.md`). The duplication pattern is not explained.
- `.squad/templates/` (`ceremonies.md`, `charter.md`, `routing.md`, etc.) are never mentioned in any doc.

---

## 3. Getting Started Experience

**Score: 8/10 — clear path, but silent failure modes.**

### What works well
- The 4-step README flow is short enough to fit in one screen.
- `INTEGRATION-GUIDE.md:53-67` shows the exact file tree created by `init.sh` — this is excellent UX, making an abstract install concrete.
- The checklist at `INTEGRATION-GUIDE.md:289-297` gives users a done-state to aim for.
- `init.sh --help` (`init.sh:17-40`) shows available presets and seeds — discoverable without docs.

### Friction points

**1. Empty-directory edge case is unaddressed.**
`INTEGRATION-GUIDE.md:42-49` shows a "new project from scratch" flow that runs `--auto` on an empty directory. It's not stated whether `--auto` gracefully handles zero config files (falls back to "core only") or fails silently.

**2. No timing expectations anywhere.**
A user running `copilot --agent squad` on a real feature will wonder: "Is this taking too long? Did it crash?" There is no guidance on expected duration (e.g., "A CRUD feature typically takes 20-45 minutes"). The only timing reference is in `wisdom.md:105` ("10 min max for environment issues") but that's internal to the coordinator, not user-facing.

**3. The first bootstrap turn is silent.**
The coordinator reads 12 files in parallel on session start (`ARCHITECTURE.md:47`), but there's no user-facing indication this is happening. Users unfamiliar with the system will see a pause with no output and wonder if something is broken.

**4. The `--auto` vs `--stack` decision is made but not fully supported for mixed stacks.**
`README.md:38` explains the heuristics, but `ARCHITECTURE.md:67-79` lists only C#, TypeScript, and Python under `stacks/rules/`. A Python + Vue or Go + React project will get a "no match found" silently. This edge case is not addressed.

---

## 4. API Documentation (Coordinator & Skills System)

**Internal contract quality is high; user-facing discoverability is low.**

### Agent charters
All agent charters follow a consistent structure with: Project Context, Model, Tools, Responsibilities, Guardrails, Scope Boundaries, Work Style. The dotnet-angular `backend.charter.md` (`stacks/dotnet-angular/agents/backend.charter.md`) is an excellent reference — it embeds actual C# conventions, patterns, and anti-patterns directly.

The generic charters in `.squad/agents/*/charter.md` are sparser — they use `<!-- Replace -->` placeholders indicating they're intended to be customized. However, `INTEGRATION-GUIDE.md:232` refers to them as if they're ready to use ("Open `.squad/agents/*/charter.md` and replace the `<!-- Replace -->` comments"), which may surprise users who expect working defaults.

### On-demand loading mechanics — undocumented for users
`ARCHITECTURE.md:8-29` lists 14 coordinator modules and their trigger keywords. But the mechanics of how a *skill bundle* gets loaded on-demand (which file naming pattern, which keyword in which file) are never explained to users. `CUSTOMIZATION_GUIDE.md:133-137` mentions "tiered loading" and "saves 70-80% context overhead" but gives no actionable explanation of how to implement it for a new preset.

### config.json — no schema documentation
`ARCHITECTURE.md:100` mentions `config.json` stores "per-agent model overrides" but there is no documented schema. What keys are valid? What model strings are accepted? Users cannot customize without reverse-engineering `.squad/config.json` directly.

### cast.conf — underdocumented
`CUSTOMIZATION_GUIDE.md:144-155` shows the format (`lead=ripley`) but never explains where the example names (`ripley`, `fenster`, `dallas`, `hockney`) come from (Alien/Predator movie characters) or whether user-defined names have constraints. A user writing `lead=my-architect` doesn't know if dashes, spaces, or uppercase are valid.

### Coordinator version — no user-facing changelog
`squad.agent.md:6` has `<!-- version: 0.9.1 -->`. The version exists but has no associated release notes anywhere in the repository.

---

## 5. Example Coverage

**Good breadth in seeds; gaps in full-stack worked examples.**

### What's covered well
- **15 tech seeds** (`stacks/seeds/`): each has critical rules, a golden code example, and a "Common LLM Mistakes" list. The `react.seed.md` example (`stacks/seeds/react.seed.md:21-83`) is thorough — it shows hooks, components, and composing them together with correct TypeScript interfaces.
- **Multiple prompt archetypes** in `INTEGRATION-GUIDE.md:100-183`: feature build, bug fix, code review, new project scaffold. Each has a template and a filled example.
- **Bad vs. good charter example** in `CUSTOMIZATION_GUIDE.md:57-97` and `stacks/_template/README.md:52-65`: the contrast is concrete and immediately actionable.
- **Failure patterns** in `shared/failure-patterns-global.md`: 17 documented patterns with code-level before/after examples. Quality is high.

### Gaps

**1. No before/after skill bundle example.**
`CUSTOMIZATION_GUIDE.md:99-131` describes the skill bundle structure but shows only a template. The `stacks/_template/README.md:52-65` gives a good "generic vs. effective" contrast for charters but does NOT show the same contrast for a skill bundle (e.g., a before showing generic advice vs. after showing embedded code with real file paths and patterns).

**2. The dotnet-angular preset is the only completed example but is never called out as the reference.**
`stacks/dotnet-angular/` contains 6 charters and 22 skill bundles — a fully worked example of everything in the customization guide. Not a single documentation file says "see `stacks/dotnet-angular/` for a complete example." `stacks/_template/README.md` and `CUSTOMIZATION_GUIDE.md` don't reference it once.

**3. No full-pipeline trace.**
No documentation shows what files are created and in what sequence when Squad runs a task end-to-end: which agent runs first, what it writes to disk, what the next agent reads, what the final output looks like. Users have no mental model for "what does done look like?"

**4. No visual/terminal demos.**
For a system whose selling point is autonomous, multi-agent execution, there is no GIF, screenshot, or terminal recording anywhere in the docs. The premium comparison doc (`PREMIUM-REQUEST-COMPARISON.md:168-183`) has a text dump of billing data — which is as close to a demo as the repo gets.

---

## 6. Documentation Gaps & Outdated Content

### Critical gaps (blocking for new users)

| Gap | Impact | Suggested fix |
|-----|--------|---------------|
| No timing expectations | Users don't know if Squad is stuck | Add "typical duration" guidance to `INTEGRATION-GUIDE.md` |
| No first-feature walkthrough | Black box anxiety on first run | New doc: `docs/HOW-IT-WORKS.md` — traces one feature from prompt to output |
| No team workflow guide | Blocks team adoption | New doc: `docs/TEAM-WORKFLOW.md` — merge conflicts, two-dev use, onboarding |
| No CHANGELOG | `--upgrade` users can't assess impact | Add `CHANGELOG.md` at repo root |
| `config.json` schema undocumented | Users can't customize model routing | Add schema table to `ARCHITECTURE.md` |

### Medium-priority gaps

| Gap | File | Detail |
|-----|------|--------|
| On-demand loading mechanics | `CUSTOMIZATION_GUIDE.md` | Step 4 mentions tiered loading but doesn't explain implementation |
| `cast.conf` format constraints | `CUSTOMIZATION_GUIDE.md:144` | Valid characters, name origin, error behavior |
| `core/` directory purpose | Not mentioned anywhere | Explain it's the upstream source for the root files or a reference copy |
| `stacks/seeds/` vs `.squad/seeds/` duplication | Not mentioned | Explain the copy-on-install relationship |
| `.squad/templates/` purpose | Not mentioned | These are base templates used by coordinator during init mode |
| Multi-stack project handling | `INTEGRATION-GUIDE.md` | What does `--auto` do when both `.csproj` and `package.json` exist? |
| Empty-directory `--auto` behavior | `INTEGRATION-GUIDE.md:42` | Does it fall back gracefully or fail? |

### Potentially outdated content

| Content | File | Concern |
|---------|------|---------|
| "GPT-5.1 HIGH" as the required model | `README.md:12`, `INTEGRATION-GUIDE.md:12`, `PREMIUM-REQUEST-COMPARISON.md:246` | Model names change. This is mentioned in 3 places; if it changes, all three need updates. A single canonical reference would reduce maintenance. |
| `.squad/config.json` version | `squad.agent.md:6` shows `0.9.1` | No changelog, so users cannot know if their installed version is current. |
| Agent cast names in README | `README.md:93-99` shows Ripley/Fenster/Dallas/Hockney | These are dotnet-angular-preset-specific names. A user on a generic install will have Lead/Backend/Frontend/Tester — the README table will not match their project. |
| `stacks/dotnet-angular/cast.conf` agent names | `dotnet-angular/cast.conf` | References `architect` role which maps to `lead` in the generic config — the naming difference is not documented. |

---

## 7. Evaluation Summary

| Dimension | Score | Key finding |
|-----------|-------|-------------|
| Clarity for new developers | 7/10 | Clear steps but no value prop upfront; too much unfamiliar jargon without explanation |
| Completeness of setup instructions | 8/10 | Most paths covered; edge cases (empty dir, mixed stack) missing |
| Quality of examples | 7/10 | Seeds and prompt examples are good; no full-pipeline walkthrough |
| Documentation organization | 6/10 | Sparse cross-linking; advanced content mixed with onboarding; `core/` and `templates/` unexplained |
| Missing documentation areas | 5/10 | CHANGELOG, team workflow, first-feature walkthrough, and visual demo are all absent |

---

## 8. Priority Improvements

**Ranked by developer-hours impact per word written:**

1. **Add 3-sentence value prop to `README.md` before Prerequisites.**
   Highest-impact, lowest-effort fix. Answers "why should I care?" before asking the user to do anything.

2. **Create `docs/HOW-IT-WORKS.md` — first-feature walkthrough.**
   Trace one real task (prompt → coordinator bootstrap → agent sequence → disk output → final state). Eliminates the biggest unknown for first-time users and reduces "is it broken?" anxiety.

3. **Add a terminal demo or GIF to README.**
   Even 30 seconds of the welcome message + one phase completing is more persuasive than any prose comparison. Add to `README.md` after the value prop.

4. **Add "Minimum Viable Customization" to `CUSTOMIZATION_GUIDE.md`.**
   The 8-12 hour full preset is a barrier. A "30-minute quick win" path (update Guardrails sections only) removes friction for the 80% use case.

5. **Explicitly reference `stacks/dotnet-angular/` as the worked example in `CUSTOMIZATION_GUIDE.md` and `stacks/_template/README.md`.**
   The work is already done — it's just not discoverable.

6. **Add `CHANGELOG.md`.**
   Even 3-5 entries covering recent coordinator versions builds trust that `--upgrade` does something meaningful.

7. **Add team workflow section to `INTEGRATION-GUIDE.md`.**
   Covers merge conflicts on `.squad/` files, two-developer simultaneous use, and onboarding a second developer. This is the "can we use this at work?" question that FAQ doesn't fully answer.

8. **Document `config.json` schema in `ARCHITECTURE.md`.**
   Table of valid keys, accepted model strings, and override priority. Users cannot confidently customize model routing without this.
