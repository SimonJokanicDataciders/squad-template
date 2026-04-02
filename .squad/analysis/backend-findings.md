# Backend Tooling Analysis

> Audited by: GitHub Copilot CLI
> Date: 2026-04-11
> Scope: init.sh, core/, stacks/, shared/, .github/workflows/, .squad/agents/, docs/

---

## 1. Build Configuration and Tooling

### Template Repo Has No Build Tooling

The squad-template repository itself has **zero runtime dependencies** and no build system. There is no `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, or `Makefile`. The entire repo is:
- `init.sh` — pure Bash bootstrapper
- Markdown files (skills, seeds, charters, rules)
- YAML GitHub Actions workflows
- JSON config files

This is intentional — the template is a meta-framework that provisions build tooling into target projects, not a runnable application itself.

### Build Tooling Provided Per Stack

The template ships **build knowledge** rather than build files:

**dotnet-angular preset** (`stacks/dotnet-angular/skills/role-ops-build.md`)
Uses the **NUKE build system** with partial class pattern:
```
build/
  Build.cs              # Entry point, parameters, solution reference
  Build.Core.cs         # Restore, Compile, Test, Publish targets
  Build.Database.cs     # BuildMigrations, MigrateDev/Staging/Prod
  Build.Docker.cs       # Docker image build & push
  Build.Deployment.cs   # Azure App Service deployment
  Build.Setup.cs        # Pulumi setup, environment configuration
  Build.Angular.cs      # Angular build orchestration
```

Build target dependency graph documented at `stacks/dotnet-angular/skills/role-ops-build.md`:
```
Restore → Compile → Test
                  → BuildDev → DeployDev
                  → BuildStaging → DeployStaging
                  → BuildProd → DeployProd
         → BuildMigrations → MigrateDev/Staging/Prod
         → BuildDockerImage → PushDockerImage
```

Common commands from that skill bundle:
```bash
./build.cmd Restore          # NuGet restore
./build.cmd Compile          # Build solution
./build.cmd Test             # Run all tests
./build.cmd BuildMigrations  # Create portable EF Core migration bundle
./build.cmd BuildDockerImage # Build Docker images
./build.cmd DeployDev        # Deploy to Dev environment
dotnet build                 # Direct dotnet fallback
dotnet test                  # Direct dotnet fallback
```

**Self-validation gate**: agent charters (e.g., `core/.squad/agents/backend/charter.md:65`) require agents to run the project's build command before marking work done:
> "BEFORE marking done: run the project's build command — fix any errors yourself. Do NOT hand off code that doesn't compile."

**Gap**: Only dotnet-angular has a detailed ops-build skill bundle. No equivalent build documentation exists for Node.js, Python, or Go stacks. Agents on those stacks must discover build commands on their own from `package.json` scripts or `pyproject.toml`.

---

## 2. Initialization and Seeding System

**File:** `init.sh` (28.4 KB, ~780 lines)

### Architecture

`init.sh` is a 6-step Bash bootstrapper that provisions Squad into any git repository:

```
Step 1: Copy core engine (.github/agents/, .copilot/skills/, .squad/ scaffolding)
Step 2: Create agent charters and history files for 6 agents (lead, backend, frontend, tester, scribe, ralph)
Step 3: Create team.md, routing.md, ceremonies.md, decisions.md from inline heredocs
Step 4: Apply stack preset (if --stack or --auto matched a preset)
Step 5: Scan project structure → generate .squad/project-map.md
Step 6: Replace {{PROJECT_NAME}}, {{USER_NAME}}, {{INIT_TIMESTAMP}} placeholders
```

### Invocation Modes

| Command | Behavior |
|---------|----------|
| `./init.sh <dir>` | Core engine only, generic agents |
| `./init.sh <dir> --auto` | Auto-detect tech stack, apply matching seeds/preset |
| `./init.sh <dir> --stack dotnet-angular` | Apply named preset, skip detection |
| `./init.sh <dir> --upgrade` | Overwrite coordinator/skills/seeds; preserve team/decisions/history |
| `./init.sh --help` | Lists presets and seeds |

### Stack Auto-Detection (`detect_stack()` function, lines 128–170)

Scans root of target directory for:

| File | Detected Tech |
|------|--------------|
| `package.json` | node |
| `tsconfig.json` | typescript |
| `vite.config.{ts,js}` | vite ⚠️ see Bug 1 |
| `angular.json` | angular |
| `next.config.{js,ts,mjs}` | nextjs ⚠️ see Bug 1 |
| `*.csproj`, `*.sln` | dotnet |
| `pyproject.toml`, `requirements.txt` | python |
| `go.mod` | go |
| `Cargo.toml` | rust |
| `Gemfile` | ruby |
| `composer.json` | php |

Also greps `package.json` for: react, vue, express, fastify, vitest, jest, tailwindcss, prisma, @angular
And greps `pyproject.toml` for: fastapi, pytest

### Seeding System

Seeds are curated LLM guardrails for common tech stacks:
- **Source:** `stacks/seeds/*.seed.md` (15 seeds)
- **Deployed to:** `.squad/seeds/` in target project
- **Format:** YAML frontmatter (`name`, `matches`, `version`, `updated`, `status`) + `## Critical Rules` + `## Golden Example` + `## Common LLM Mistakes`

Seeds are **NOT automatically injected** into agent charters. They are available at `.squad/seeds/` for agents to load on-demand. The coordinator's onboard skill (`core/.copilot/skills/coordinator/squad-onboard.md`) handles this discovery.

### Known Bugs in init.sh

**Bug 1 — Shell operator precedence, lines 131, 133, 652, 654**

```bash
# BROKEN — assignment only fires when vite.config.js is present; .ts variant silently fails
[ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ] && DETECTED_TECHS="$DETECTED_TECHS vite"
```
`||` binds before `&&` in Bourne shell. Fix:
```bash
{ [ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ]; } && DETECTED_TECHS="$DETECTED_TECHS vite"
```
Same bug on `next.config.js|ts|mjs` at line 133 and the duplicate block at lines 652–654.

**Bug 2 — session-state.md always overwritten on re-init (line 268)**

```bash
cp "$SCRIPT_DIR/core/.squad/session-state.md" "$TARGET/.squad/"   # no -n flag
```
Running `init.sh` twice on the same project resets session state. Should be `cp -n`.

**Bug 3 — Duplicate detection logic between `detect_stack()` and Step 5 (lines 648–660)**

Step 5 re-implements stack detection with a shorter, inconsistent list (missing ruby, php, rust; different variable name `$DETECTED_STACK` vs `$DETECTED_TECHS`). These will diverge. Step 5 should call `detect_stack()` and reuse `$DETECTED_TECHS`.

**Bug 4 — Only `dotnet-angular` ever suggested as preset (lines 179–181)**

```bash
if echo "$DETECTED_TECHS" | grep -q "dotnet" && echo "$DETECTED_TECHS" | grep -q "angular"; then
  SUGGESTED_PRESET="dotnet-angular"
fi
```
No other preset is ever suggested. Needs a dispatch table as the preset library grows.

**Bug 5 — No monorepo detection**

`detect_stack()` only inspects `$TARGET` root. A monorepo with `frontend/package.json` and `backend/*.csproj` is detected as "nothing." Should traverse one level deep.

---

## 3. Dependencies Management

### Template Repo Dependencies

**Runtime dependencies: none.** The template ships as pure Bash + Markdown.

**Implicit dependencies for init.sh to run:**
- `bash` (invoked as `#!/usr/bin/env bash`)
- `git` (validates target is a git repo; reads `git config user.name`)
- `python3` (used inline at Step 5 for JSON parsing of `package.json` scripts):
  ```bash
  python3 -c "import json; pkg = json.load(open('$TARGET/package.json')); ..."
  ```
  If Python 3 is unavailable, the project-map `## Key Commands` section is silently skipped (no failure — the `-c` call is wrapped in `$(... 2>/dev/null)`).
- `date` with `-u` flag (macOS and GNU `date` compatible; standard)
- Standard Unix tools: `find`, `grep`, `sed`, `awk`, `wc`, `ls`, `cp`, `mv`, `mkdir`

**No package manager is used.** There is no lockfile.

### Dependency Guidance for Target Projects

The template propagates dependency knowledge through:

1. **Seeds** — Each seed specifies exact package versions and rules. Examples:
   - `stacks/seeds/dotnet-webapi.seed.md`: `.NET 9.x`, FluentValidation, TypedResults
   - `stacks/seeds/vitest.seed.md`: `Vitest 3.1`, MSW
   - `stacks/seeds/prisma.seed.md`: `Prisma 6.x`
   - `stacks/seeds/xunit.seed.md`: `xUnit 2.9`, FluentAssertions, NSubstitute, Testcontainers, Bogus
   - `stacks/seeds/pytest.seed.md`: `pytest 8.3`, httpx, pytest-asyncio

2. **Stack rules** (`stacks/rules/`) — List recommended packages per language:
   - C# (`stacks/rules/csharp/testing.md`): xUnit, Bogus, FluentAssertions, NSubstitute, Testcontainers, WebApplicationFactory
   - TypeScript (`stacks/rules/typescript/testing.md`): Vitest (preferred) or Jest, Testing Library, MSW, Playwright
   - Python (`stacks/rules/python/testing.md`): pytest, httpx, factory_boy, pytest-mock

3. **Security rules** (`stacks/rules/common/security.md:108-112`) — Mandate dependency audits:
   ```
   Run `npm audit` / `dotnet list package --vulnerable` / `pip audit` in CI
   Never ignore critical or high severity vulnerabilities
   Pin dependency versions in production
   ```

4. **dotnet-angular ops skill** (`stacks/dotnet-angular/skills/role-ops-build.md`) — Documents Central Package Management via `Directory.Packages.props` for consistent NuGet versioning across the solution.

**Gap**: No equivalent central version management guidance for Node.js monorepos (e.g., pnpm workspaces, turborepo) or Python (e.g., `uv.lock`).

---

## 4. Testing Frameworks and Configuration

### Meta-level: No Tests for init.sh

The template repository contains **no automated tests**. `init.sh` is not tested against actual target projects in CI. There is no test suite validating that seeds are syntactically correct or that workflows are valid YAML.

This is the largest gap from a backend tooling perspective — the bootstrapper that provisions every project is untested.

### Testing Standards Shipped to Target Projects

**Universal rules** (`stacks/rules/common/testing.md`):

| Area | Minimum Coverage |
|------|-----------------|
| General application code | 80% |
| Auth and authorization | 100% |
| Payment processing | 100% |
| Security-critical paths | 100% |
| Data validation | 100% |
| Utility/helper functions | 90% |

Mandated methodology: **TDD RED-GREEN-REFACTOR** cycle. Test structure: **Arrange-Act-Assert**. One behavior per test.

**Language-specific testing configurations:**

**C#** (`stacks/rules/csharp/testing.md`, `stacks/seeds/xunit.seed.md`)
- Framework: xUnit 2.9
- Assertions: FluentAssertions (`value.Should().Be(...)`)
- Mocking: NSubstitute
- Data generation: Bogus (static readonly `Faker<T>`)
- Integration tests: WebApplicationFactory + Testcontainers (real Postgres, not EF InMemory)
- Naming: `MethodName_Condition_ExpectedResult`
- Project layout: mirror `src/` under `tests/MyApp.Tests/` and `tests/MyApp.IntegrationTests/`
- Rule: No `EF InMemory` provider for integration tests — use Testcontainers

**TypeScript** (`stacks/rules/typescript/testing.md`, `stacks/seeds/vitest.seed.md`, `stacks/seeds/jest.seed.md`)
- Primary framework: Vitest 3.1 (preferred), Jest 29.7 (alternative)
- Component testing: @testing-library/react
- HTTP mocking: MSW (Mock Service Worker) — intercept at network level, never mock `fetch` directly
- E2E: Playwright
- Key Vitest rules: use `vi.*` not `jest.*`; `vi.clearAllMocks()` in `afterEach`; `test.each` for parameterized tests
- Test files co-located: `src/services/orderService.test.ts` beside `orderService.ts`

**Python** (`stacks/rules/python/testing.md`, `stacks/seeds/pytest.seed.md`)
- Framework: pytest 8.3
- HTTP testing: `httpx.AsyncClient` with `ASGITransport` for FastAPI
- Data: factory_boy or custom fixtures
- Mocking: `unittest.mock` or `pytest-mock`
- Required: `@pytest.mark.asyncio` on async tests; fixtures in `conftest.py`
- Test structure: `tests/conftest.py`, `tests/unit/`, `tests/integration/`
- Naming: `test_method_condition_expected` (snake_case)

### Seed Coverage for Testing

| Seed | Version | Covers |
|------|---------|--------|
| `jest.seed.md` | 29.7 | `jest.fn()`, `beforeEach`, mock cleanup, async |
| `vitest.seed.md` | 3.1 | MSW, `vi.*`, `test.each`, in-source testing |
| `xunit.seed.md` | 2.9 | `[Fact]`/`[Theory]`, `IClassFixture`, Testcontainers |
| `pytest.seed.md` | 8.3 | fixtures, `parametrize`, asyncio, `TestClient` |

---

## 5. Development Environment Setup

### Prerequisites (from README.md)

1. GitHub Copilot with agent mode enabled
2. CLI model: GPT-5.1 HIGH (enables per-agent model routing; other models collapse all agents to same tier)
3. Git repository (`git init` required before running `init.sh`)

### Pre-Flight Environment Checks

Encoded in `core/.copilot/skills/coordinator/squad-preflight.md`. Before starting any work, the coordinator detects:
- SDK version vs project requirements (`global.json`, `package.json`, `pyproject.toml`)
- Docker availability
- Java (for OpenAPI generators)
- Database provider (`UseSqlServer` vs `UseNpgsql` vs `UseSqlite`)
- Port availability
- Missing dependencies (`node_modules`, pip packages, NuGet)

Ref: `docs/ARCHITECTURE.md:166-176`

### No Devcontainer or Docker Compose

The template ships **no `devcontainer.json`** or **`docker-compose.yml`**. Environment setup is entirely manual and relies on pre-flight checks to detect issues at runtime.

### Python 3 Required on Provisioner Machine

`init.sh` Step 5 (line ~688) runs:
```python
python3 -c "import json; pkg = json.load(open('$TARGET/package.json')); scripts = pkg.get('scripts', {})..."
```
If Python 3 is absent, project-map command table is silently empty. Not documented in prerequisites.

### Environment Variables

Security rules (`stacks/rules/common/security.md`) mandate environment variable usage:
```
Secrets belong in: environment variables / secret managers / .gitignored .env files
```
No `.env.example` template is provided by init.sh. Projects must create their own.

### Session State and Context Persistence

Agent sessions expire in ~2 minutes (per `shared/failure-patterns-global.md`, Pattern 2). The template handles this via:
- `.squad/session-state.md` — completed/pending/blocked status
- `.squad/agents/{name}/status.md` — per-agent state
- `.squad/orchestration-log/` — per-agent change logs (immediate, before Scribe)
- `.gitattributes` sets `merge=union` on history and log files to make parallel worktrees safe

### Model Routing Setup

`core/.squad/config.json`:
```json
{
  "version": 1,
  "defaultModel": "claude-sonnet-4.6",
  "agentModelOverrides": {
    "lead":   "claude-opus-4.6",
    "ripley": "claude-opus-4.6",
    "scribe": "claude-haiku-4.5",
    "ralph":  "claude-haiku-4.5"
  },
  "templateVersion": "1.0.0",
  "templateDate": "2026-03-30"
}
```
Model selection hierarchy (6 layers): user task override → config.json overrides → session directive → charter preference → role-based defaults → fallback.

---

## 6. Automation and Script Organization

### GitHub Actions Workflows

All 5 workflows live in `core/.github/workflows/` and are copied to target projects:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `squad-heartbeat.yml` | Schedule (every 30 min) + issue close/label + PR close + manual | Ralph runs triage script; assigns unassigned `squad:copilot` issues |
| `squad-triage.yml` | Issue labeled `squad` | Routes issue to agent via keyword matching + capability scoring |
| `squad-issue-assign.yml` | Issue labeled `squad:*` | Posts assignment acknowledgment; assigns `copilot-swe-agent[bot]` if `squad:copilot` |
| `sync-squad-labels.yml` | Push to `team.md` or manual | Creates/updates all `squad:*`, `go:*`, `release:*`, `type:*`, `priority:*` labels from roster |
| `pr-title-check.yml` | PR opened/edited/synced | Validates conventional commit format via `amannn/action-semantic-pull-request@v5` |

All workflows use `actions/github-script@v7` for logic (Node.js inline) and `actions/checkout@v4`.

**Required secrets:**
- `GITHUB_TOKEN` (auto-provisioned)
- `COPILOT_ASSIGN_TOKEN` — PAT required to assign `copilot-swe-agent[bot]` to issues; falls back to `GITHUB_TOKEN` (but @copilot assignment may fail). **Not documented in README setup steps.**

### Label System

Managed by `sync-squad-labels.yml`, creates:
- `squad` — triage inbox
- `squad:{member}` — per-agent assignment (derived from `team.md` roster)
- `squad:copilot` — Copilot coding agent assignment
- `go:yes`, `go:no`, `go:needs-research` — decision status
- `release:v{n}`, `release:backlog` — milestone targeting
- `type:feature`, `type:bug`, `type:spike`, `type:docs`, `type:chore`, `type:epic`
- `priority:p0/p1/p2`
- `bug`, `feedback` — high-signal labels

### Issue Routing Logic

`squad-triage.yml` implements keyword-based routing:
- Reads `team.md` for roster; reads `routing.md` for routing rules
- Scores @copilot fit using three capability tiers from `team.md`: 🟢 Good fit / 🟡 Needs review / 🔴 Not suitable
- Falls through to role-based keyword matching (frontend/backend/tester/devops keywords)
- Defaults to Lead if no match
- Posts triage comment on issue with reasoning

### init.sh Script Organization

The script is well-structured with numbered steps and clear echo output:
```
1/6  Copying core engine
2/6  Creating agent charters and histories
3/6  Creating team configuration
4/6  Applying stack preset (if any)
5/6  Scanning project structure
6/6  Replacing placeholders
```

Functions: `detect_stack()` (standalone, reusable), `charter_map()` (maps preset charter filenames to agent dirs)

### Missing Automation

**Critical gap: `ralph-triage.js` is referenced but does not exist**

`squad-heartbeat.yml:34-39` checks for and runs:
```bash
node .squad/templates/ralph-triage.js --squad-dir .squad --output triage-results.json
```
This file does not exist anywhere in the repository. The workflow gracefully skips if absent (`has_script=false`) but logs a warning. The triage functionality is therefore silently non-operational until this script is authored.

**No Makefile or Taskfile for common operations**

Common dev operations require remembering init.sh flags. A `Makefile` would help:
```makefile
init:        init.sh $(TARGET) --auto
upgrade:     init.sh $(TARGET) --upgrade
new-stack:   cp -r stacks/_template stacks/$(NAME)
```

**No `.gitignore` management**

`init.sh` does not append Squad ephemeral paths to `.gitignore`. Projects risk committing:
- `.squad/session-state.md`
- `.squad/log/`
- `.squad/orchestration-log/`
- `.squad/project-map.md` (arguably should be committed, but could be noisy)

**No pre-commit hooks**

The security rules (`stacks/rules/common/security.md`) define a pre-commit checklist, but there are no hook files to enforce it automatically.

**No upgrade version comparison**

`--upgrade` runs unconditionally without checking if the target is already current. A `templateVersion` comparison (from `config.json`) would prevent unnecessary overwrites.

---

## Summary: Gaps and Recommendations

### Critical (P0)

| # | Issue | File Reference |
|---|-------|---------------|
| P0-1 | `ralph-triage.js` referenced in heartbeat but doesn't exist | `core/.github/workflows/squad-heartbeat.yml:49` |
| P0-2 | Shell operator precedence bug silences vite/nextjs detection | `init.sh:131,133,652,654` |

### High (P1)

| # | Issue | File Reference |
|---|-------|---------------|
| P1-1 | `session-state.md` always overwritten on re-init (missing `cp -n`) | `init.sh:268` |
| P1-2 | `COPILOT_ASSIGN_TOKEN` secret undocumented in setup | `README.md`, `squad-issue-assign.yml:121` |
| P1-3 | No test suite for `init.sh` bootstrapper | `init.sh` (all) |
| P1-4 | `learn.md` missing for ralph and scribe agents | `core/.squad/agents/{ralph,scribe}/` |
| P1-5 | No `.gitignore` management step in init.sh | `init.sh` |

### Medium (P2)

| # | Issue | File Reference |
|---|-------|---------------|
| P2-1 | Duplicate stack detection logic (detect_stack() vs Step 5) | `init.sh:128-170` vs `init.sh:648-660` |
| P2-2 | Only `dotnet-angular` ever suggested as preset; no dispatch for others | `init.sh:179-181` |
| P2-3 | No monorepo subdir traversal in detect_stack() | `init.sh:128-170` |
| P2-4 | dotnet-angular skills reference CAP.Template-specific paths — confuses other .NET projects | `stacks/dotnet-angular/skills/role-backend-core.md` |
| P2-5 | `mcp-config.json` referenced but not present in core/ | `init.sh:263` |
| P2-6 | No version comparison in `--upgrade` | `init.sh:63-112` |

### Low (P3)

| # | Issue | File Reference |
|---|-------|---------------|
| P3-1 | Missing seeds: NestJS, Drizzle, Supabase, Go, Docker, Django | `stacks/seeds/` |
| P3-2 | Missing stack presets: nextjs-prisma, react-express, fastapi-react | `stacks/` |
| P3-3 | `shared/` underused — only 1 file; could house security baseline, git workflow | `shared/` |
| P3-4 | Python 3 runtime dependency of init.sh not in prerequisites | `README.md`, `init.sh:688` |
| P3-5 | No devcontainer.json for reproducible dev environments | (missing) |
| P3-6 | fastapi.seed.md and python-ml.seed.md marked beta with no explanation | `stacks/seeds/fastapi.seed.md:6`, `stacks/seeds/python-ml.seed.md` |
