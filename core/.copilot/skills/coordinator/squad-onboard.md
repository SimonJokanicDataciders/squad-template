# Squad Onboard — Automated Codebase Learning & Project Bootstrap

**Load when:** "learn", "onboard", "analyze codebase", "discover", "scan project", OR when no `.copilot/skills/role-*-core.md` files exist and user gives first work request.

---

## Auto-Detection

On session start, after bootstrap reads, check TWO things:

```bash
# 1. Do skill bundles exist?
ls .copilot/skills/role-*-core.md 2>/dev/null

# 2. Does source code exist?
find . -maxdepth 3 -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.cs" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.rb" -o -name "*.php" \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' 2>/dev/null | head -5
```

**Decision matrix:**

| Skill bundles exist? | Source code exists? | Action |
|---------------------|-------------------|--------|
| YES | any | **Skip onboarding** — proceed normally |
| NO | YES | **Learn Mode** — scan existing codebase (Phase A) |
| NO | NO | **Bootstrap Mode** — generate from user's prompt (Phase B) |

If onboarding is triggered:
1. Say which mode: `"🔍 No skill bundles detected. [Learning from existing code / Bootstrapping from your request] — ~60 seconds, one time only."`
2. Run the appropriate phase
3. After completion, immediately execute the original work request

---

## Phase A: Learn Mode (existing codebase)

Use when source code already exists. Agents scan the codebase and extract patterns.

Fan out ALL 4 domain agents with `agent_type: "general-purpose"` (they need to WRITE skill bundles):

**Batch 1:**

```
name: "lead"
agent_type: "general-purpose"
mode: "background"
description: "🏗️ Lead: Analyzing project architecture"
prompt: |
  You are Lead, the Architect.
  TEAM ROOT: {team_root}

  Read .squad/agents/lead/learn.md and execute the FULL learning protocol.
  This is an EXISTING codebase — scan it thoroughly and extract actual patterns.

  Write your findings to:
  1. .copilot/skills/role-architect.md
  2. .copilot/skills/sdlc-context-core.md

  Include REAL code examples from the actual codebase. Cite file:line.
  Append summary to .squad/agents/lead/history.md
```

```
name: "backend"
agent_type: "general-purpose"
mode: "background"
description: "🔧 Backend: Discovering backend patterns"
prompt: |
  You are Backend, the Backend Developer.
  TEAM ROOT: {team_root}

  Read .squad/agents/backend/learn.md and execute the FULL learning protocol.
  This is an EXISTING codebase — scan it and extract actual backend patterns.

  Write your findings to .copilot/skills/role-backend-core.md
  Include REAL code examples from the actual codebase. Cite file:line.
  Append summary to .squad/agents/backend/history.md
```

**Batch 2:**

```
name: "frontend"
agent_type: "general-purpose"
mode: "background"
description: "⚛️ Frontend: Discovering frontend patterns"
prompt: |
  You are Frontend, the Frontend Developer.
  TEAM ROOT: {team_root}

  Read .squad/agents/frontend/learn.md and execute the FULL learning protocol.
  This is an EXISTING codebase — scan it and extract actual frontend patterns.

  Write your findings to .copilot/skills/role-frontend-core.md
  Include REAL code examples from the actual codebase. Cite file:line.
  Append summary to .squad/agents/frontend/history.md
```

```
name: "tester"
agent_type: "general-purpose"
mode: "background"
description: "🧪 Tester: Discovering test patterns"
prompt: |
  You are Tester, the QA Engineer.
  TEAM ROOT: {team_root}

  Read .squad/agents/tester/learn.md and execute the FULL learning protocol.
  This is an EXISTING codebase — scan it and extract actual test patterns.

  Write your findings to .copilot/skills/role-qa-core.md
  Include REAL code examples from the actual codebase. Cite file:line.
  Append summary to .squad/agents/tester/history.md
```

---

## Phase B: Bootstrap Mode (empty project, build from prompt)

Use when NO source code exists. The Lead agent analyzes the user's prompt, determines the tech stack, and generates skill bundles from best-practice knowledge.

**3-Layer approach:**
1. **Stack Seeds** — curated guardrails for common stacks (verified, high confidence)
2. **Premium Model** — bootstrap ALWAYS uses `claude-opus-4.6` regardless of config
3. **Verification** — sanity check after generation
4. **Knowledge Gate** — if no seeds match, ask user for conventions before hallucinating

### Step 0: Load Matching Stack Seeds

**Before spawning the Lead, check for matching seeds:**

```bash
ls .squad/seeds/*.seed.md 2>/dev/null
```

Parse the user's original message for tech keywords. For each seed file, read its YAML frontmatter `matches` field. If ANY keyword from the user's message matches ANY entry in `matches`, load that seed.

Example: User says "Build a task API with Express and React"
→ matches `express.seed.md` (matches: ["express"]) + `react.seed.md` (matches: ["react"])
→ Load both seeds and inject into the Lead's prompt

Available seeds: express, react, nextjs, angular, vue, fastapi, dotnet-webapi, prisma, efcore, jest, vitest, pytest, xunit, tailwind, python-ml

### Step 0b: Knowledge Gate — When NO Seeds Match

**If NO seeds match the user's tech keywords, do NOT blindly generate from LLM knowledge.** Instead:

1. **Identify what's missing.** Parse the user's prompt for tech keywords that didn't match any seed.

2. **Ask the user for a learning file:**

```
🔍 I don't have verified conventions for {unmatched technologies}.

To ensure quality, please provide a conventions file:
  1. Create a .md file with your coding patterns, rules, and a code example
  2. Drop it in: .squad/seeds/{tech}.seed.md

Example format (just the essentials — 30-50 lines):
  ## Critical Rules
  1. {your most important convention}
  2. {second rule}
  ...

  ## Golden Example
  ```{lang}
  // one complete example showing THE pattern to follow
  ```

  ## Common Mistakes
  - {what to avoid}

Or if you want me to proceed with auto-generated conventions (lower confidence),
say "proceed without seeds" and I'll generate from my training data.
```

3. **Wait for the user to either:**
   - Provide a seed file → re-run Step 0 (seed matching), then proceed to Step 1
   - Say "proceed without seeds" / "just go" / "use defaults" → proceed to Step 1 without seeds, but mark generated bundles as `confidence: "low"` and `source: "llm-generated-no-seed"`
   - Clarify their tech stack → re-run Step 0 with updated keywords

**This is the ONE exception to the "never ask" rule.** Missing knowledge is a legitimate blocker — it's better to ask once for 30 lines of conventions than to generate bad code across the entire project.

**When SOME seeds match but not all technologies:**
- Use the matched seeds normally
- For unmatched technologies, tell the user which ones are missing and offer the same options
- Example: "Seeds found for Express and React. Missing seed for Redis — provide one or I'll generate from training data."

### Step 1: Lead Generates All Skill Bundles (sync, PREMIUM MODEL)

**⚠️ CRITICAL: Bootstrap ALWAYS uses `claude-opus-4.6`. This overrides config.json, session directives, and task-aware auto-select. Rationale: this runs ONCE per project and affects the quality of ALL subsequent work. One premium call now prevents hundreds of bad cheap calls later.**

```
name: "lead"
agent_type: "general-purpose"
model: "claude-opus-4.6"
mode: "sync"
description: "🏗️ Lead: Bootstrapping project knowledge from request"
prompt: |
  You are Lead, the Architect on this project.
  TEAM ROOT: {team_root}

  The user wants to build a NEW project. There is NO existing code.
  Their request: "{original user message}"

  {if seeds were loaded:}
  STACK SEEDS (verified conventions — follow these STRICTLY as your foundation):

  {paste contents of ALL matching seed files here}

  These seeds contain VERIFIED critical rules and golden examples.
  Your skill bundles MUST follow the seeds' critical rules.
  Expand them into full bundles, but NEVER contradict the seeds.
  {end if}

  {if user provided custom learning file(s):}
  USER-PROVIDED CONVENTIONS:

  {paste contents of user's .md file(s)}

  These are the user's own conventions. Follow them as ground truth.
  {end if}

  YOUR JOB: Analyze the user's request, determine the tech stack, and generate
  skill bundles so the whole team knows HOW to build this project correctly.

  ## Step 1: Determine the Tech Stack

  From the user's request, identify (or choose best defaults for):
  - Backend language + framework (e.g., Node.js + Express, Python + FastAPI, etc.)
  - Frontend framework (e.g., React, Angular, Vue, etc.)
  - Database (e.g., PostgreSQL, MongoDB, SQLite, etc.)
  - ORM/data layer (e.g., Prisma, Sequelize, SQLAlchemy, etc.)
  - Test framework (e.g., Jest/Vitest, pytest, xUnit, etc.)
  - Build tools, package manager
  - Any other tech mentioned in the request

  If the user didn't specify a technology for a layer, choose the most popular/practical
  option for the stack they DID specify. State your choices clearly.

  ## Step 2: Design the Project Structure

  Create the directory layout this project should follow. Be specific:
  ```
  project-root/
  ├── src/           or backend/
  │   ├── routes/    or controllers/
  │   ├── models/    or entities/
  │   ├── services/
  │   └── ...
  ├── frontend/      or client/
  │   ├── src/
  │   │   ├── components/
  │   │   ├── pages/
  │   │   └── ...
  ├── tests/
  └── ...
  ```

  ## Step 3: Write Skill Bundles

  Create ALL of the following files with REAL, ACTIONABLE conventions:

  ### 3a. `.copilot/skills/sdlc-context-core.md`

  ```markdown
  ---
  name: "sdlc-context-core"
  description: "Project context for {project name}"
  domain: "cross-cutting"
  confidence: "medium"
  source: "bootstrapped"
  ---

  # Project Context

  ## Stack
  {complete stack summary}

  ## Project Structure
  {full directory layout}

  ## Key Commands
  - Install: {command}
  - Dev server: {command}
  - Build: {command}
  - Test: {command}
  - Lint: {command}

  ## Agent Directory Map
  | Agent | Owns | Key Directories |
  |-------|------|-----------------|
  | Backend | API, DB, services | {paths} |
  | Frontend | UI, components | {paths} |
  | Tester | Tests | {paths} |
  ```

  ### 3b. `.copilot/skills/role-architect.md`

  Architecture decisions, delivery flow, and how agents should coordinate.
  Include: project structure, reference implementation plan, routing table.

  ### 3c. `.copilot/skills/role-backend-core.md`

  Backend conventions based on the chosen stack. Include:
  - Code conventions (naming, file structure, error handling)
  - Entity/model pattern (with code example showing the EXACT pattern to follow)
  - Service pattern (with code example)
  - Route/endpoint pattern (with code example)
  - Database conventions (migrations, queries)
  - Validation approach
  - Implementation checklist

  **CRITICAL:** Include actual CODE EXAMPLES showing the pattern, not just descriptions.
  For example, if the stack is Express + Prisma, show a complete endpoint handler,
  a complete Prisma model, a complete service method.

  ### 3d. `.copilot/skills/role-frontend-core.md`

  Frontend conventions based on the chosen stack. Include:
  - Component pattern (with code example)
  - Routing pattern (with code example)
  - API integration pattern (with code example showing how to call the backend)
  - State management approach
  - Styling approach
  - Type/interface conventions
  - Frontend checklist

  ### 3e. `.copilot/skills/role-qa-core.md`

  Testing conventions based on the chosen stack. Include:
  - Test file naming and structure
  - Unit test pattern (with code example)
  - Integration/API test pattern (with code example)
  - Mocking approach
  - Test commands
  - QA checklist

  ## Step 4: Update Agent Charters

  For each agent (backend, frontend, tester), update their charter at
  `.squad/agents/{name}/charter.md` to add:
  - The specific tech stack under Project Context
  - Stack-specific guardrails (e.g., "use Prisma for all DB access, never raw SQL")
  - The skill bundle path reference

  ## Step 5: Update Routing

  Update `.squad/routing.md` to include the specific directory paths for this project.

  ## Step 6: Log Your Work

  Append to `.squad/agents/lead/history.md`:
  ```
  ## Project Bootstrap — {date}
  - User request: {summary}
  - Stack chosen: {stack}
  - Skill bundles generated: role-architect.md, role-backend-core.md,
    role-frontend-core.md, role-qa-core.md, sdlc-context-core.md
  - Project structure designed: {summary}
  ```

  ## IMPORTANT RULES:
  - Every skill bundle MUST contain real CODE EXAMPLES, not just descriptions
  - Code examples should be the EXACT patterns agents will follow
  - If you're unsure about a convention, pick the most common/popular one
  - Be opinionated — agents need clear rules, not options
  - The skill bundles are the team's shared brain — make them thorough
```

### Step 2: Verify Generated Bundles

After Lead completes, run a verification check:

**Structural verification (coordinator does this, no agent needed):**

1. Check all 5 files exist:
   ```
   ls .copilot/skills/role-architect.md .copilot/skills/role-backend-core.md .copilot/skills/role-frontend-core.md .copilot/skills/role-qa-core.md .copilot/skills/sdlc-context-core.md
   ```

2. For each bundle, verify it contains:
   - A `## Stack` or `## Project Structure` section (not empty)
   - At least one code example (fenced code block)
   - A checklist section

3. **If any bundle is missing or empty:** re-spawn Lead (still premium model) with: "The following skill bundles are missing or incomplete: {list}. Generate them now."

4. **If seeds were used:** spot-check that the seed's critical rules appear in the generated bundle. If a critical rule is contradicted, flag it: `"⚠️ Generated bundle contradicts seed rule: {rule}. Regenerating."`

### Step 3: Show Results and Proceed

1. Show results:
   ```
   🏗️ Lead — Bootstrapped project: {stack summary}
     📄 role-architect.md — Architecture & delivery flow
     📄 role-backend-core.md — {framework} conventions + patterns
     📄 role-frontend-core.md — {framework} conventions + patterns
     📄 role-qa-core.md — {test framework} conventions + patterns
     📄 sdlc-context-core.md — Project context & commands
     🌱 Seeds used: {list of matched seeds, or "none"}
   ```

2. Say: `"✅ Project bootstrapped with {stack}. {N} skill bundles generated. Starting work now."`

3. **Immediately proceed to execute the original work request** using normal routing. Do NOT ask the user to confirm. The skill bundles are ready — agents can load them and start building.

---

## Post-Bootstrap: Auto-Learn After First Feature

After the FIRST feature is fully implemented (code exists), add this to Scribe's post-work tasks:

> Check if skill bundles have `source: "bootstrapped"`. If yes, and real code now exists,
> update the bundles with actual code examples from the implemented feature (replace
> hypothetical examples with real ones). Change source to `"auto-discovered"`.

This means:
1. Bootstrap generates skill bundles from LLM knowledge (good enough to start)
2. After first feature ships, bundles are automatically enriched with real examples
3. Each subsequent feature benefits from increasingly accurate knowledge

---

## Re-Learn (Manual Trigger)

When the user says "re-learn", "refresh skills", "re-analyze", or "update knowledge":

1. Delete existing skill bundles: `rm .copilot/skills/role-*-core.md .copilot/skills/role-architect.md .copilot/skills/sdlc-context-core.md 2>/dev/null`
2. Check if source code exists now
3. If yes → run Learn Mode (Phase A)
4. If no → run Bootstrap Mode (Phase B) again
5. Say: `"🔄 Skill bundles refreshed."`

---

## Partial Learn / Bootstrap

- "learn the backend" → spawn only Backend with learn.md
- "learn the frontend" → spawn only Frontend with learn.md
- "re-bootstrap with FastAPI instead of Express" → re-run Phase B with updated prompt

---

## Summary

| Scenario | What Happens | Time |
|----------|-------------|------|
| Empty project + work request | Lead bootstraps skill bundles from prompt → work starts | ~60s |
| Existing project + work request | All agents scan codebase in parallel → work starts | ~60s |
| Skill bundles exist | Skip onboarding → work starts immediately | 0s |
| User says "re-learn" | Delete bundles → re-scan or re-bootstrap | ~60s |
| User says "learn the backend" | Single agent re-scans its domain | ~20s |
