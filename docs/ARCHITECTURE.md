# Architecture

## 3-Tier Separation

### Tier 1: Core Engine (universal)

The optimized coordinator prompt at `.github/agents/squad.agent.md` is the brain. It was reduced from 21,600 lines (default) to ~1200 lines through:

1. **On-demand module loading** — 14 coordinator modules in `.copilot/skills/coordinator/` are only read when keywords trigger them
2. **Removed redundancy** — merged duplicate sections, eliminated verbose examples
3. **Preserved all behavior** — same bootstrap protocol, model selection, parallel fan-out, failure recovery, reviewer lockout

#### Coordinator Modules

| Module | Trigger | Purpose |
|--------|---------|---------|
| Init Mode | "init", "create team" | Team setup and casting |
| Casting | "cast", "rename" | Agent name management |
| Issues | "issue", "triage" | GitHub issue routing |
| Mesh | "mesh", "cross-squad" | Multi-squad coordination |
| Infrastructure | "kubernetes", "scale" | Infrastructure management |
| Communications | "external", "community" | External communications |
| Plugins | "plugin", "extend" | Plugin system |
| Session | "session recovery" | Client compatibility |
| Artifacts | "artifact format" | Output format control |
| Worktrees | "worktree", "cleanup" | Git worktree isolation |
| **Pre-Flight** | **ALWAYS (bootstrap)** | Environment checks (SDK, Docker, Java, ports, DB provider) |
| Contexts | "mode", "context" | Dev/Research/Review behavioral switching |
| Handoffs | "handoff", "orchestrate" | Structured agent-to-agent communication |
| Onboard | No skill bundles found | Auto-learn from codebase or bootstrap from prompt |

#### Key Optimizations

- **11 Critical Rules** at the top of the coordinator prompt (survive context truncation):
  1. Never ask — just do (auto-proceed, banned phrases)
  2. Referenced files are instructions (parse and execute)
  3. Detect project type before build/run
  4. Install dependencies first
  5. Honor model overrides from user input
  6. Read project map
  7. Handle read_agent failures gracefully
  8. Always pass model explicitly in spawns
  9. Environment time budget (10 min max)
  10. Proactive agent status checks
  11. Direct-run fallback (when orchestrators hang)

- **Bootstrap in 1 turn** — reads 12 files in parallel on session start (team, routing, registry, config, all charters, all histories, decisions, wisdom, project-map, pre-flight)
- **Charter inlining** — pastes charters into spawn prompts (eliminates 4-5 agent self-reads, enables 96% prompt caching)
- **Max 2 parallel agents** — prevents transient API errors from 3+ spawns
- **Failure collaboration** — after 2 failures, spawns a different agent to help
- **Self-validation** — agents run build/lint before handing off, reducing fix-loops

### Tier 2: Stack Presets (per tech stack)

Stack presets contain the actual domain knowledge that makes agents effective:

- **Agent charters** — model preferences, tool scoping, guardrails, coding conventions, scope boundaries (DO/DON'T), skill loading protocols
- **Skill bundles** — embedded patterns, code examples, reference implementations
- **Routing tables** — precise mapping of work types to agents
- **Ceremonies** — quality gate triggers specific to the stack
- **Failure patterns** — documented failures and mitigations (stack-specific)
- **Cast mapping** — `cast.conf` maps generic roles to stack-specific agent names

**Tiered loading**: Each agent has a core bundle (always loaded, ~250 lines) and on-demand modules (loaded only when relevant). This saves 70-80% context overhead vs loading everything.

#### Language Rules (`stacks/rules/`)

Universal and language-specific coding rules auto-copied by `init.sh`:

```
stacks/rules/
├── common/          # Universal (all projects): coding-style, security, testing, git-workflow
├── csharp/          # C#: sealed classes, EF Core, xUnit patterns
├── typescript/      # TS: strict mode, no any, Vitest/Jest patterns
└── python/          # Python: type hints, Pydantic, FastAPI, pytest patterns
```

These are copied to `.github/instructions/` in the target project based on auto-detected tech stack.

#### Shared Failure Patterns (`shared/`)

`shared/failure-patterns-global.md` contains universal patterns observed across ALL projects:
- Hallucinated method names
- Parallel DB queries on shared connections
- Frontend build walking into backend output dirs
- Environment setup exceeding time budget
- Wrong database provider assumptions

This file is copied to every project and inherited by all agents.

### Tier 3: Per-Project (generated at runtime)

Created by `init.sh` or Squad's Init Mode:

- `team.md` — roster with cast names (via `cast.conf` or generic roles)
- `agents/{name}/charter.md` — per-agent identity with model preferences and tool scoping
- `agents/{name}/history.md` — personal learnings (append-only)
- `decisions.md` — shared decision log (append-only, union merge)
- `casting/` — persistent name registry
- `project-map.md` — auto-detected file structure and tech stack
- `config.json` — per-agent model overrides

## Key Patterns

### Drop-Box Pattern

Agents never write directly to `decisions.md`. Instead:
1. Each agent writes to `.squad/decisions/inbox/{agent-name}-{slug}.md`
2. Scribe merges inbox into `decisions.md` and clears inbox
3. No file conflicts on parallel writes

### Union Merge

`.gitattributes` configures `merge=union` for append-only files:
- `decisions.md`, `agents/*/history.md`, `log/**`, `orchestration-log/**`
- This makes parallel branching and worktree-based development safe

### Session State Persistence

Agent sessions expire quickly. The coordinator writes results to:
- `.squad/orchestration-log/` — per-agent change logs (immediate, before Scribe)
- `.squad/session-state.md` — completed/pending/blocked status
- `.squad/agents/{name}/status.md` — per-agent working/done/failed state
- These survive context compaction and session expiry

### Model Selection Hierarchy

6 layers, first match wins:

1. **User task override** — task spec says "use opus" (highest priority)
2. **Persistent config** — `config.json` agentModelOverrides (survives sessions)
3. **Session directive** — "use opus for this session"
4. **Charter preference** — agent's `## Model` section with `Preferred` field
5. **Task-aware auto** — role-based defaults:

| Agent Role | Default Model | Rationale |
|---|---|---|
| Lead/Architect | `claude-opus-4.6` | Decisions feed all agents |
| Backend/Frontend/Tester | `claude-sonnet-4.6` | Code quality needs accuracy |
| Scribe/Ralph | `claude-haiku-4.5` | Mechanical work, cost first |

6. **Default fallback** — `claude-sonnet-4.6`

### Agent Tool Scoping

Each agent charter declares allowed tools:

| Agent | Tools | Rationale |
|---|---|---|
| Lead | Read, Grep, Glob | Read-only — designs, doesn't implement |
| Backend/Frontend/Tester | Read, Grep, Glob, Edit, Write, Bash | Full access — writes code |
| Scribe | Read, Grep, Glob, Edit, Write | Writes docs, no Bash needed |
| Ralph | Read, Grep, Glob, Bash | Reads code, runs build/security commands |

### Context Modes

The coordinator detects task context and adjusts agent behavior:

| Context | When | Behavior |
|---|---|---|
| Development | "build", "implement", "fix" | Write code first, explain after |
| Research | "analyze", "investigate", "explore" | Read widely before concluding |
| Review | "review", "check", "audit" | Prioritize by severity, suggest fixes |

### Pre-Flight Environment Checks

Before any work, the coordinator detects:
- SDK version vs project requirements (global.json, package.json)
- Docker availability
- Java (for OpenAPI generators)
- Database provider (SqlServer vs PostgreSQL vs SQLite)
- Port availability
- Missing dependencies (node_modules, pip packages)

Reports issues upfront instead of discovering them mid-pipeline.

## init.sh Capabilities

| Flag | Purpose |
|---|---|
| `--auto` | Auto-detect tech stack, apply matching preset/seeds/rules |
| `--stack <name>` | Apply specific preset (e.g., dotnet-angular) |
| `--upgrade` | Update coordinator + skills without losing customizations |
| (no flag) | Core engine only, generic agents |
